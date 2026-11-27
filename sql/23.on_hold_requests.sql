-- Apply after 21.paymentVA.sql. Requests and their details must be created
-- together, and decisions must only be made against current invoices.
CREATE OR REPLACE FUNCTION public.submit_hold_request(
    p_student_id uuid, p_reason text, p_invoice_ids uuid[]
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request_id uuid;
    v_invoice public.invoices%ROWTYPE;
    v_count integer := 0;
BEGIN
    IF auth.uid() IS NULL OR NOT EXISTS (
        SELECT 1 FROM public.students
        WHERE id = p_student_id AND parent_auth_id = auth.uid()
    ) THEN
        RAISE EXCEPTION 'Not authorized to request a hold for this student';
    END IF;
    IF p_reason IS NULL OR length(btrim(p_reason)) = 0
       OR length(p_reason) > 1000 OR coalesce(cardinality(p_invoice_ids), 0) = 0
       OR array_position(p_invoice_ids, NULL) IS NOT NULL
       OR cardinality(p_invoice_ids) <> (
           SELECT count(DISTINCT id) FROM unnest(p_invoice_ids) AS ids(id)
       ) THEN
        RAISE EXCEPTION 'A reason and distinct invoices are required';
    END IF;

    FOR v_invoice IN
        SELECT * FROM public.invoices
        WHERE id = ANY(p_invoice_ids)
        ORDER BY id FOR UPDATE
    LOOP
        v_count := v_count + 1;
        IF v_invoice.student_id <> p_student_id OR v_invoice.status <> 'issued'
           OR EXISTS (
               SELECT 1 FROM public.request_on_hold_detail d
               JOIN public.request_on_hold r ON r.id = d.request_on_hold_id
               WHERE d.invoice_id = v_invoice.id AND r.request_status = 'pending'
           ) THEN
            RAISE EXCEPTION 'An invoice is unavailable or already has a pending request';
        END IF;
    END LOOP;
    IF v_count <> cardinality(p_invoice_ids) THEN
        RAISE EXCEPTION 'An invoice was not found';
    END IF;

    INSERT INTO public.request_on_hold (student_id, reason)
    VALUES (p_student_id, btrim(p_reason)) RETURNING id INTO v_request_id;
    INSERT INTO public.request_on_hold_detail (request_on_hold_id, invoice_id, qty)
    SELECT v_request_id, id, quantity FROM public.invoices
    WHERE id = ANY(p_invoice_ids);
    RETURN v_request_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.decide_hold_request(
    p_request_id uuid, p_approve boolean
) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE
    v_request public.request_on_hold%ROWTYPE;
    v_invoice record;
    v_count integer := 0;
BEGIN
    IF auth.uid() IS NULL OR NOT EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = auth.uid() AND role = 'accountant'
    ) THEN
        RAISE EXCEPTION 'Only accountants can review requests';
    END IF;
    IF p_approve IS NULL THEN
        RAISE EXCEPTION 'A decision is required';
    END IF;
    SELECT * INTO v_request FROM public.request_on_hold
    WHERE id = p_request_id FOR UPDATE;
    IF NOT FOUND OR v_request.request_status <> 'pending' THEN
        RAISE EXCEPTION 'This request is no longer pending';
    END IF;
    IF p_approve THEN
        FOR v_invoice IN
            SELECT i.id, i.student_id, i.status, i.quantity, d.qty
            FROM public.request_on_hold_detail d
            JOIN public.invoices i ON i.id = d.invoice_id
            WHERE d.request_on_hold_id = p_request_id
            ORDER BY i.id FOR UPDATE OF i
        LOOP
            v_count := v_count + 1;
            IF v_invoice.student_id <> v_request.student_id
               OR v_invoice.status <> 'issued'
               OR v_invoice.quantity <> v_invoice.qty THEN
                RAISE EXCEPTION 'An invoice has changed and cannot be placed on hold';
            END IF;
        END LOOP;
        IF v_count = 0 THEN
            RAISE EXCEPTION 'This request has no invoices';
        END IF;
    END IF;
    UPDATE public.request_on_hold
    SET request_status = CASE WHEN p_approve
        THEN 'approved'::public.request_status
        ELSE 'rejected'::public.request_status END
    WHERE id = p_request_id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_hold_request(uuid, text, uuid[]) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.decide_hold_request(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_hold_request(uuid, text, uuid[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.decide_hold_request(uuid, boolean) TO authenticated;

DROP POLICY IF EXISTS request_on_hold_insert ON public.request_on_hold;
DROP POLICY IF EXISTS request_on_hold_update ON public.request_on_hold;
DROP POLICY IF EXISTS request_on_hold_detail_insert ON public.request_on_hold_detail;
DROP POLICY IF EXISTS request_on_hold_detail_update ON public.request_on_hold_detail;
DROP POLICY IF EXISTS request_on_hold_detail_delete ON public.request_on_hold_detail;
