DROP TABLE IF EXISTS public.foto_student_access CASCADE;
DROP TABLE IF EXISTS public.foto_kegiatan CASCADE;

CREATE TABLE public.foto_kegiatan (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  link_foto varchar NOT NULL,
  nama_kegiatan varchar NOT NULL,
  thumbnail_foto varchar NOT NULL,
  classes_name classes[] NOT NULL
);

CREATE TABLE public.foto_student_access (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  foto_kegiatan_id uuid NOT NULL REFERENCES public.foto_kegiatan(id) ON DELETE CASCADE
);

-- enable RLS
ALTER TABLE public.foto_kegiatan ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.foto_student_access ENABLE ROW LEVEL SECURITY;

CREATE POLICY "insert foto_kegiatan"
ON public.foto_kegiatan
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.users_private
    WHERE (SELECT auth.uid()) = auth_id
      AND role = 'multimedia'
  )
);

CREATE POLICY "delete foto_kegiatan"
ON public.foto_kegiatan
FOR DELETE
USING (
  EXISTS (
    SELECT 1
    FROM public.users_private
    WHERE (SELECT auth.uid()) = auth_id
      AND role = 'multimedia'
  )
);

CREATE POLICY "select foto_kegiatan"
ON public.foto_kegiatan
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.users_private
    WHERE (SELECT auth.uid()) = auth_id
      AND role = 'multimedia'
  )
  OR EXISTS (
    SELECT 1
    FROM public.foto_student_access fsa
    JOIN public.students s ON s.id = fsa.student_id
    WHERE fsa.foto_kegiatan_id = foto_kegiatan.id
      AND (SELECT auth.uid()) = s.parent_auth_id
  )
);

CREATE POLICY "select foto_student_access"
ON public.foto_student_access
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM public.students s
    WHERE s.id = foto_student_access.student_id
      AND (SELECT auth.uid()) = s.parent_auth_id
  )
);


CREATE OR REPLACE FUNCTION public.insert_foto_student_access_by_class()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- 1️⃣ Insert foto_student_access
  INSERT INTO public.foto_student_access (student_id, foto_kegiatan_id)
  SELECT s.id, NEW.id
  FROM public.students s
  WHERE s.class_name = ANY (NEW.classes_name);

  -- 2️⃣ Notify parents with student names + activity
  INSERT INTO public.notifications (auth_id, title, body)
  SELECT
    s.parent_auth_id,
    'Foto Kegiatan Baru',
    'Foto untuk ' ||
      string_agg(DISTINCT s.name, ', ') ||
      ' (' || NEW.nama_kegiatan || ') sekarang tersedia.'
  FROM public.students s
  WHERE s.class_name = ANY (NEW.classes_name)
  GROUP BY s.parent_auth_id;

  RETURN NEW;
END;
$$;

ALTER FUNCTION public.insert_foto_student_access_by_class() OWNER TO postgres;

CREATE TRIGGER trg_insert_foto_student_access_by_class
AFTER INSERT ON public.foto_kegiatan
FOR EACH ROW EXECUTE FUNCTION public.insert_foto_student_access_by_class();

