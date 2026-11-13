DROP TABLE IF EXISTS public.request_on_hold_detail CASCADE;
DROP TABLE IF EXISTS public.request_on_hold CASCADE;
DROP TABLE IF EXISTS public.payment_option CASCADE;
DROP TABLE IF EXISTS public.invoice_template_detail CASCADE;
DROP TABLE IF EXISTS public.invoice_template CASCADE;
DROP TABLE IF EXISTS public.invoices CASCADE;

DROP TYPE IF EXISTS public.invoice_status CASCADE;
DROP TYPE IF EXISTS public.payment_methods CASCADE;
DROP TYPE IF EXISTS public.request_status CASCADE;

CREATE TYPE public.invoice_status AS ENUM ('issued', 'on_hold', 'verifying', 'paid', 'draft');
CREATE TYPE public.payment_methods AS ENUM ('bca', 'bni', 'qris');
CREATE TYPE public.request_status AS ENUM ('pending', 'approved', 'rejected');

CREATE TABLE public.invoices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    bill_month date NOT NULL DEFAULT date_trunc('month', CURRENT_DATE)::date,
    status public.invoice_status NOT NULL DEFAULT 'draft',
    item_name text NOT NULL,
    price_per_item bigint NOT NULL CHECK (price_per_item >= 0),
    quantity integer NOT NULL CHECK (quantity > 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.payment_option (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_method public.payment_methods NOT NULL,
    va_number text,
    key text,
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    UNIQUE (student_id, payment_method)
);

CREATE TABLE public.request_on_hold (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reason text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    request_status public.request_status NOT NULL DEFAULT 'pending',
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.request_on_hold_detail (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    request_on_hold_id uuid NOT NULL REFERENCES public.request_on_hold(id) ON DELETE CASCADE,
    invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    qty integer NOT NULL CHECK (qty > 0),
    UNIQUE (request_on_hold_id, invoice_id)
);

CREATE TABLE public.invoice_template (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.invoice_template_detail (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_template_id uuid NOT NULL REFERENCES public.invoice_template(id) ON DELETE CASCADE,
    item_name text NOT NULL,
    price_per_item bigint NOT NULL CHECK (price_per_item >= 0),
    quantity integer NOT NULL CHECK (quantity > 0)
);

CREATE INDEX idx_invoices_student_status ON public.invoices (student_id, status);
CREATE INDEX idx_request_on_hold_detail_request ON public.request_on_hold_detail (request_on_hold_id);

ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_option ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_on_hold ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_on_hold_detail ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_template ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_template_detail ENABLE ROW LEVEL SECURITY;

CREATE POLICY invoices_accountant_all ON public.invoices
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ));

CREATE POLICY invoices_parent_select ON public.invoices
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.students
        WHERE students.id = invoices.student_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY payment_option_accountant_all ON public.payment_option
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ));

CREATE POLICY payment_option_parent_select ON public.payment_option
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.students
        WHERE students.id = payment_option.student_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY request_on_hold_accountant_all ON public.request_on_hold
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ));

CREATE POLICY request_on_hold_parent_select ON public.request_on_hold
    FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.students
        WHERE students.id = request_on_hold.student_id
          AND students.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY request_on_hold_parent_insert ON public.request_on_hold
    FOR INSERT
    WITH CHECK (
        request_status = 'pending'
        AND EXISTS (
            SELECT 1 FROM public.students
            WHERE students.id = request_on_hold.student_id
              AND students.parent_auth_id = (SELECT auth.uid())
        )
    );

CREATE POLICY request_on_hold_detail_accountant_all ON public.request_on_hold_detail
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ));

CREATE POLICY request_on_hold_detail_parent_select ON public.request_on_hold_detail
    FOR SELECT
    USING (EXISTS (
        SELECT 1
        FROM public.request_on_hold r
        JOIN public.students s ON s.id = r.student_id
        WHERE r.id = request_on_hold_detail.request_on_hold_id
          AND s.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY request_on_hold_detail_parent_insert ON public.request_on_hold_detail
    FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1
        FROM public.request_on_hold r
        JOIN public.invoices i ON i.student_id = r.student_id
        JOIN public.students s ON s.id = r.student_id
        WHERE r.id = request_on_hold_detail.request_on_hold_id
          AND r.request_status = 'pending'
          AND i.id = request_on_hold_detail.invoice_id
          AND s.parent_auth_id = (SELECT auth.uid())
    ));

CREATE POLICY invoice_template_accountant_all ON public.invoice_template
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ));

CREATE POLICY invoice_template_detail_accountant_all ON public.invoice_template_detail
    FOR ALL
    USING (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ))
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.users_private
        WHERE auth_id = (SELECT auth.uid()) AND role = 'accountant'
    ));

CREATE OR REPLACE FUNCTION public.set_payment_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_invoice_payment_status(p_student_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.students
    SET has_paid = COALESCE((
        SELECT SUM(i.price_per_item * i.quantity) < 9000000
        FROM public.invoices i
        WHERE i.student_id = p_student_id
          AND i.status IN ('issued', 'on_hold')
    ), true)
    WHERE id = p_student_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_invoice_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT'
       AND NEW.status IN ('issued', 'paid')
    THEN
        INSERT INTO public.notifications (auth_id, title, body)
        SELECT s.parent_auth_id, 'Invoice update',
               'An invoice for ' || s.name || ' is now ' || NEW.status::text || '.'
        FROM public.students s
        WHERE s.id = NEW.student_id;
    ELSIF TG_OP = 'UPDATE'
          AND NEW.status IS DISTINCT FROM OLD.status
          AND NEW.status IN ('issued', 'paid')
    THEN
        INSERT INTO public.notifications (auth_id, title, body)
        SELECT s.parent_auth_id, 'Invoice update',
               'An invoice for ' || s.name || ' is now ' || NEW.status::text || '.'
        FROM public.students s
        WHERE s.id = NEW.student_id;
    END IF;

    PERFORM public.refresh_invoice_payment_status(NEW.student_id);
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.refresh_invoice_payment_status_after_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    PERFORM public.refresh_invoice_payment_status(OLD.student_id);
    RETURN OLD;
END;
$$;

CREATE OR REPLACE FUNCTION public.notify_hold_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO public.notifications (auth_id, title, body)
        SELECT up.auth_id, 'Payment hold request',
               'A payment hold request was submitted for ' || s.name || '.'
        FROM public.users_private up
        CROSS JOIN public.students s
        WHERE up.role = 'accountant'
          AND s.id = NEW.student_id;
    ELSIF TG_OP = 'UPDATE'
          AND OLD.request_status = 'pending'
          AND NEW.request_status IN ('approved', 'rejected')
    THEN
        IF NEW.request_status = 'approved' THEN
            UPDATE public.invoices i
            SET status = 'on_hold'
            FROM public.request_on_hold_detail d
            WHERE d.request_on_hold_id = NEW.id
              AND i.id = d.invoice_id
              AND i.status = 'issued';
        END IF;

        INSERT INTO public.notifications (auth_id, title, body)
        SELECT s.parent_auth_id, 'Payment hold request',
               'Your payment hold request for ' || s.name || ' was ' ||
               NEW.request_status::text || '.'
        FROM public.students s
        WHERE s.id = NEW.student_id;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_payment_updated_at_invoices ON public.invoices;
DROP TRIGGER IF EXISTS trg_payment_updated_at_request_on_hold ON public.request_on_hold;
DROP TRIGGER IF EXISTS trg_payment_updated_at_invoice_template ON public.invoice_template;
DROP TRIGGER IF EXISTS trg_invoice_status_notify ON public.invoices;
DROP TRIGGER IF EXISTS trg_invoice_delete_refresh ON public.invoices;
DROP TRIGGER IF EXISTS trg_request_on_hold_notify ON public.request_on_hold;

CREATE TRIGGER trg_payment_updated_at_invoices
BEFORE UPDATE ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.set_payment_updated_at();

CREATE TRIGGER trg_payment_updated_at_request_on_hold
BEFORE UPDATE ON public.request_on_hold
FOR EACH ROW EXECUTE FUNCTION public.set_payment_updated_at();

CREATE TRIGGER trg_payment_updated_at_invoice_template
BEFORE UPDATE ON public.invoice_template
FOR EACH ROW EXECUTE FUNCTION public.set_payment_updated_at();

CREATE TRIGGER trg_invoice_status_notify
AFTER INSERT OR UPDATE OF status ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.notify_invoice_status();

CREATE TRIGGER trg_invoice_delete_refresh
AFTER DELETE ON public.invoices
FOR EACH ROW EXECUTE FUNCTION public.refresh_invoice_payment_status_after_delete();

CREATE TRIGGER trg_request_on_hold_notify
AFTER INSERT OR UPDATE OF request_status ON public.request_on_hold
FOR EACH ROW EXECUTE FUNCTION public.notify_hold_request();
