DROP TABLE IF EXISTS public.invoice_proof CASCADE;
DROP TABLE IF EXISTS public.proofs CASCADE;
DROP TABLE IF EXISTS public.invoices CASCADE;
DROP TYPE IF EXISTS public.invoice_status CASCADE;

CREATE TYPE invoice_status AS ENUM ('issued', 'on_hold', 'verifying', 'paid', 'draft');
CREATE TYPE payment_methods AS ENUM ('bca', 'bni', 'qris');

CREATE TABLE public.invoices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
    bill_month date NOT NULL DEFAULT date_trunc('month', CURRENT_DATE)::date,
    status invoice_status NOT NULL DEFAULT 'draft',
    item_name text NOT NULL,
    price_per_item bigint NOT NULL,
    quantity integer NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE payment_option(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_method payment_methods NOT NULL,
    va_number text,
    key text,
    student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
);

CREATE TABLE public.request_on_hold(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reason text NOT NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

CREATE TABLE public.request_on_hold_detail(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
    qty integer NOT NULL,

);

CREATE TABLE public.invoice_template(
    

)

CREATE TABLE public.invoice_template_detail(

)