CREATE TYPE invoice_status AS ENUM ('issued', 'on_hold', 'verifying', 'paid');

CREATE TABLE public.invoices(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    item_name text NOT NULL,
    price_per_item bigint NOT NULL,
    quantity integer NOT NULL,
    bill_month date NOT NULL DEFAULT date_trunc('month', CURRENT_DATE)::date,
    status invoice_status NOT NULL DEFAULT 'issued',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.proofs(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    file_url text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.invoice_proof(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    proof_id uuid NOT NULL REFERENCES public.proofs(id) ON DELETE CASCADE,
    UNIQUE (invoice_id, proof_id)
);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.proofs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_proof ENABLE ROW LEVEL SECURITY;


--RLS
-- proofs:
-- accountant can select all
-- parent can insert and select their own children's proofs
--invoice_proof:
-- accountant can select all
-- parent can select their own children's invoice_proof
-- invoices:
-- Accountant can select, update, insert, delete
-- parent of student can select

CREATE POLICY invoices_accountant_all ON public.invoices
    FOR ALL
    USING (EXISTS (
        SELECT 1
        FROM public.users_private
        WHERE auth_id = (SELECT auth.uid())
          AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1
        FROM public.users_private
        WHERE auth_id = (SELECT auth.uid())
          AND role = 'accountant'
    ));

CREATE POLICY invoices_parent_select ON public.invoices
    FOR SELECT
    USING (EXISTS (
        SELECT 1
        FROM public.students
        WHERE students.id = invoices.student_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY proofs_accountant_select ON public.proofs
    FOR SELECT
    USING (EXISTS (
        SELECT 1
        FROM public.users_private
        WHERE auth_id = (SELECT auth.uid())
          AND role = 'accountant'
    ));

CREATE POLICY proofs_parent_select ON public.proofs
    FOR SELECT
    USING (EXISTS (
        SELECT 1
        FROM public.students
        WHERE students.id = proofs.student_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY proofs_parent_insert ON public.proofs
    FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1
        FROM public.students
        WHERE students.id = proofs.student_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY invoice_proof_accountant_select ON public.invoice_proof
    FOR SELECT
    USING (EXISTS (
        SELECT 1
        FROM public.users_private
        WHERE auth_id = (SELECT auth.uid())
          AND role = 'accountant'
    ));

CREATE POLICY invoice_proof_parent_select ON public.invoice_proof
    FOR SELECT
    USING (EXISTS (
        SELECT 1
        FROM public.invoices
        JOIN public.students ON students.id = invoices.student_id
        WHERE invoices.id = invoice_proof.invoice_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

--Trigger
-- proofs:
-- after insert,  assgin proof to all issued invoices of the student, then update invoices status to verifying, if there are no issued invoices, do nothing

--invoices:
-- After insert, notify parent ,if there are 3 months of issued invoices, students.has_paid false, if not students.has_paid true
-- After update, if status changed to paid notify parent, and check if there are still 3 months of issued invoices if yes students.has_paid false, if not students.has_paid true
-- After update, if status changed to veryfying notify all accountants, if status changed to paid notify parent

--Note
--check roles on public.users_private.role
--to get the parent there is students.parent_auth_id
--for notifications insert it to public.notifications with columns auth_id, title, body

CREATE OR REPLACE FUNCTION public.refresh_student_payment_status(p_student_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.students
    SET has_paid = (
        SELECT COUNT(DISTINCT bill_month) < 3
        FROM public.invoices
        WHERE student_id = p_student_id
          AND status = 'issued'
    )
    WHERE id = p_student_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_invoice_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    PERFORM public.refresh_student_payment_status(NEW.student_id);

    INSERT INTO public.notifications (auth_id, title, body)
    SELECT s.parent_auth_id,
           'New invoice',
           'A new invoice for ' || s.name || ' has been issued.'
    FROM public.students s
    WHERE s.id = NEW.student_id;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_invoice_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        PERFORM public.refresh_student_payment_status(NEW.student_id);
    END IF;

    IF NEW.status = 'paid' AND OLD.status IS DISTINCT FROM 'paid' THEN
        INSERT INTO public.notifications (auth_id, title, body)
        SELECT s.parent_auth_id,
               'Payment received',
               'Payment for ' || s.name || ' has been confirmed.'
        FROM public.students s
        WHERE s.id = NEW.student_id;
    ELSIF NEW.status = 'verifying' AND OLD.status IS DISTINCT FROM 'verifying' THEN
        INSERT INTO public.notifications (auth_id, title, body)
        SELECT up.auth_id,
               'Payment verification needed',
               'A payment proof for ' || s.name || ' is ready for verification.'
        FROM public.users_private up
        CROSS JOIN public.students s
        WHERE up.role = 'accountant'
          AND s.id = NEW.student_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_proof_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.invoice_proof (invoice_id, proof_id)
    SELECT i.id, NEW.id
    FROM public.invoices i
    WHERE i.student_id = NEW.student_id
      AND i.status = 'issued'
    ON CONFLICT (invoice_id, proof_id) DO NOTHING;

    UPDATE public.invoices
    SET status = 'verifying'
    WHERE student_id = NEW.student_id
      AND status = 'issued';

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_invoice_insert
AFTER INSERT ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.handle_invoice_insert();

CREATE TRIGGER trg_invoice_update
AFTER UPDATE OF status ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.handle_invoice_update();

CREATE TRIGGER trg_proof_insert
AFTER INSERT ON public.proofs
FOR EACH ROW EXECUTE FUNCTION public.handle_proof_insert();
