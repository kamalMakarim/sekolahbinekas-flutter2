-- Apply after 4.fotokegiatan.sql. Unlike student access, tingkat access also
-- includes activities without matching students and PPI-only activities.
CREATE OR REPLACE FUNCTION public.foto_kegiatan_matches_my_tingkat(
  photo_classes public.classes[]
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.users_private up
    JOIN public.tingkat_role tr ON tr.role = up.role
    JOIN public.tingkat_classes tc ON tc.tingkat = tr.tingkat
    WHERE up.auth_id = (SELECT auth.uid())
      AND up.role IN ('bidang_study_tk', 'bidang_study_sd')
      AND tc.class_name = ANY (photo_classes)
  );
$$;

REVOKE ALL ON FUNCTION public.foto_kegiatan_matches_my_tingkat(public.classes[])
  FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.foto_kegiatan_matches_my_tingkat(public.classes[])
  TO authenticated;

DROP POLICY IF EXISTS "select foto_kegiatan by bidang study"
  ON public.foto_kegiatan;
CREATE POLICY "select foto_kegiatan by bidang study"
ON public.foto_kegiatan
FOR SELECT
TO authenticated
USING (public.foto_kegiatan_matches_my_tingkat(classes_name));
