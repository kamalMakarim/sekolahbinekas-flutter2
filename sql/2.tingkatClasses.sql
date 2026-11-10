DROP TYPE IF EXISTS tingkat CASCADE;
CREATE TYPE tingkat AS ENUM ('TK', 'SD');

DROP TABLE IF EXISTS public.tingkat_classes CASCADE;
CREATE TABLE public.tingkat_classes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tingkat tingkat NOT NULL,
    class_name classes NOT NULL UNIQUE,
    tahun int --kelas 1 sd 2 sd and so on buat tk jg bisa
);

DROP TABLE IF EXISTS public.tingkat_role CASCADE;
-- tingkat_role table to map roles to tingkat levels
CREATE TABLE public.tingkat_role (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    role role NOT NULL UNIQUE,
    tingkat tingkat NOT NULL,
    class_name classes NOT NULL UNIQUE
);

-- Populate the tingkat_role table
INSERT INTO public.tingkat_role (role, tingkat, class_name) VALUES
  ('bidang_study_tk', 'TK', 'Bidang Study TK'),
  ('bidang_study_sd', 'SD', 'Bidang Study SD')
ON CONFLICT (role) DO NOTHING;

-- Populate the tingkat_classes table with the class mappings
INSERT INTO public.tingkat_classes (tingkat, class_name) VALUES
  ('TK', 'Blue Pinter Morning'),
  ('TK', 'Blue Pinter Afternoon'),
  ('TK', 'Green Motekar'),
  ('TK', 'Green Wanter'),
  ('TK', 'Green Maher'),
  ('TK', 'Yellow Maher'),
  ('TK', 'Yellow Motekar'),
  ('TK', 'Yellow Wanter'),
  ('SD', 'Gumujeng'),
  ('SD', 'Someah'),
  ('SD', 'Rancage'),
  ('SD', 'Gentur'),
  ('SD', 'Macakal'),
  ('SD', 'Calakan'),
  ('SD', 'Singer'),
  ('SD', 'Rancingeus'),
  ('SD', 'Jatmika'),
  ('SD', 'Gumanti'),
  ('SD', 'Marahmay'),
  ('SD', 'Rucita'),
  ('SD', 'Binangkit'),
  ('SD', 'Gumilang'),
  ('SD', 'Sonagar')
ON CONFLICT (class_name) DO NOTHING;


DROP FUNCTION IF EXISTS public.insert_message_from_log() CASCADE;
-- Updated insert_message_from_log function
CREATE OR REPLACE FUNCTION public.insert_message_from_log()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tingkat public.tingkat;
BEGIN
  -- Check if this is a bidang study role and get its tingkat
  SELECT tr.tingkat INTO v_tingkat
  FROM public.tingkat_role tr
  WHERE tr.class_name = NEW.class_name;

  INSERT INTO public.messages (
    message,
    student_id,
    images,
    sender_id,
    message_type,
    log_id
  )
  SELECT NEW.message,
         s.id,
         NEW.images,
         NEW.user_id,
         'log',
         NEW.id
  FROM public.students s
  WHERE
    (
      -- If this is a bidang study role, send to students of that tingkat
      v_tingkat IS NOT NULL
      AND s.class_name IN (
        SELECT tc.class_name 
        FROM public.tingkat_classes tc 
        WHERE tc.tingkat = v_tingkat
      )
    )
    OR
    (
      -- default behavior: send to students of the same class
      v_tingkat IS NULL 
      AND s.class_name = NEW.class_name
    );
  RETURN NEW;
END;
$$;


DROP FUNCTION IF EXISTS public.update_student_access() CASCADE;
-- Updated update_student_access function
CREATE OR REPLACE FUNCTION public.update_student_access()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_tingkat public.tingkat;
BEGIN
  -- Clear old access for this auth_id
  DELETE FROM public.student_access
  WHERE auth_id = NEW.auth_id;

  -- Teacher access: grant access to students in same class
  IF NEW.role = 'teacher' THEN
    INSERT INTO public.student_access (student_id, auth_id)
    SELECT s.id, NEW.auth_id
    FROM public.students s
    WHERE s.class_name = NEW.class_name
    ON CONFLICT (student_id, auth_id) DO NOTHING;
  END IF;

  -- Parent access: parents get access to their own kids only if the student has_paid = true
  INSERT INTO public.student_access (student_id, auth_id)
  SELECT s.id, NEW.auth_id
  FROM public.students s
  WHERE s.parent_auth_id = NEW.auth_id
    AND s.has_paid = true
  ON CONFLICT (student_id, auth_id) DO NOTHING;

  -- Check if this is a bidang study role and get its tingkat
  SELECT tr.tingkat INTO v_tingkat
  FROM public.tingkat_role tr
  WHERE tr.role = NEW.role;

  -- If this is a bidang study role, grant access to all students of that tingkat
  IF v_tingkat IS NOT NULL THEN
    INSERT INTO public.student_access (student_id, auth_id)
    SELECT s.id, NEW.auth_id
    FROM public.students s
    WHERE s.class_name IN (
      SELECT tc.class_name 
      FROM public.tingkat_classes tc 
      WHERE tc.tingkat = v_tingkat
    )
    ON CONFLICT (student_id, auth_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;


DROP FUNCTION IF EXISTS public.update_student_access_on_student_change() CASCADE;
-- Updated update_student_access_on_student_change function
CREATE OR REPLACE FUNCTION public.update_student_access_on_student_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_old_tingkat public.tingkat;
  v_new_tingkat public.tingkat;
BEGIN
  -- INSERT: add parent access only if student.has_paid = true; add teachers & bidang roles
  IF TG_OP = 'INSERT' THEN
    -- Parent (only if student.has_paid is true)
    IF NEW.has_paid = true THEN
      INSERT INTO public.student_access (student_id, auth_id)
      VALUES (NEW.id, NEW.parent_auth_id)
      ON CONFLICT (student_id, auth_id) DO NOTHING;
    END IF;

    -- Teacher access for that class
    INSERT INTO public.student_access (student_id, auth_id)
    SELECT NEW.id, up.auth_id
    FROM public.users_private up
    WHERE up.role = 'teacher'
      AND up.class_name = NEW.class_name
    ON CONFLICT (student_id, auth_id) DO NOTHING;

    -- Get tingkat for new class
    SELECT tc.tingkat INTO v_new_tingkat
    FROM public.tingkat_classes tc
    WHERE tc.class_name = NEW.class_name;

    -- Add access for all bidang study roles that match this tingkat
    IF v_new_tingkat IS NOT NULL THEN
      INSERT INTO public.student_access (student_id, auth_id)
      SELECT NEW.id, up.auth_id
      FROM public.users_private up
      INNER JOIN public.tingkat_role tr ON tr.role = up.role
      WHERE tr.tingkat = v_new_tingkat
      ON CONFLICT (student_id, auth_id) DO NOTHING;
    END IF;

    RETURN NEW;
  END IF;

  -- UPDATE: handle class or parent changes
  IF TG_OP = 'UPDATE' THEN
    -- ---------- CLASS CHANGE ----------
    IF NEW.class_name IS DISTINCT FROM OLD.class_name THEN
      -- Remove teacher access for teachers of old class
      DELETE FROM public.student_access
      WHERE student_id = NEW.id
        AND auth_id IN (
          SELECT up.auth_id
          FROM public.users_private up
          WHERE up.role = 'teacher'
            AND up.class_name = OLD.class_name
        );

      -- Add teacher access for teachers of new class
      INSERT INTO public.student_access (student_id, auth_id)
      SELECT NEW.id, up.auth_id
      FROM public.users_private up
      WHERE up.role = 'teacher'
        AND up.class_name = NEW.class_name
      ON CONFLICT (student_id, auth_id) DO NOTHING;

      -- Get tingkat for old and new classes
      SELECT tc.tingkat INTO v_old_tingkat
      FROM public.tingkat_classes tc
      WHERE tc.class_name = OLD.class_name;

      SELECT tc.tingkat INTO v_new_tingkat
      FROM public.tingkat_classes tc
      WHERE tc.class_name = NEW.class_name;

      -- Remove access for bidang study roles of old tingkat
      IF v_old_tingkat IS NOT NULL THEN
        DELETE FROM public.student_access
        WHERE student_id = NEW.id
          AND auth_id IN (
            SELECT up.auth_id
            FROM public.users_private up
            INNER JOIN public.tingkat_role tr ON tr.role = up.role
            WHERE tr.tingkat = v_old_tingkat
          );
      END IF;

      -- Add access for bidang study roles of new tingkat
      IF v_new_tingkat IS NOT NULL THEN
        INSERT INTO public.student_access (student_id, auth_id)
        SELECT NEW.id, up.auth_id
        FROM public.users_private up
        INNER JOIN public.tingkat_role tr ON tr.role = up.role
        WHERE tr.tingkat = v_new_tingkat
        ON CONFLICT (student_id, auth_id) DO NOTHING;
      END IF;
    END IF;

    -- ---------- PARENT CHANGE ----------
    IF NEW.parent_auth_id IS DISTINCT FROM OLD.parent_auth_id THEN
      -- Remove access for old parent
      DELETE FROM public.student_access
      WHERE student_id = NEW.id
        AND auth_id = OLD.parent_auth_id;

      -- Add access for new parent only if the student has_paid = true and the new auth row is role=parent
      IF NEW.has_paid = true THEN
        INSERT INTO public.student_access (student_id, auth_id)
        SELECT NEW.id, up.auth_id
        FROM public.users_private up
        WHERE up.auth_id = NEW.parent_auth_id
          AND up.role = 'parent'
        ON CONFLICT (student_id, auth_id) DO NOTHING;
      END IF;
    END IF;

    -- ---------- PAYMENT TOGGLED (has_paid changed) ----------
    -- If has_paid changed from false -> true, add parent access
    IF NEW.has_paid = true AND (OLD.has_paid IS DISTINCT FROM true) THEN
      INSERT INTO public.student_access (student_id, auth_id)
      SELECT NEW.id, NEW.parent_auth_id
      FROM public.users_private up
      WHERE up.auth_id = NEW.parent_auth_id
        AND up.role = 'parent'
      ON CONFLICT (student_id, auth_id) DO NOTHING;
    END IF;

    -- If has_paid changed from true -> false, remove parent access
    IF NEW.has_paid = false AND (OLD.has_paid IS DISTINCT FROM false) THEN
      DELETE FROM public.student_access
      WHERE student_id = NEW.id
        AND auth_id = NEW.parent_auth_id;
    END IF;

    RETURN NEW;
  END IF;

  -- DELETE or other ops: no action (student_access cascades on student delete)
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_insert_message_from_log ON public.logs;
DROP TRIGGER IF EXISTS trg_update_student_access ON public.users_private;
DROP TRIGGER IF EXISTS trg_update_student_access_on_student_change ON public.students;

CREATE TRIGGER trg_update_student_access
AFTER INSERT OR UPDATE ON public.users_private
FOR EACH ROW EXECUTE FUNCTION public.update_student_access();

CREATE TRIGGER trg_update_student_access_on_student_change
AFTER INSERT OR UPDATE OR DELETE ON public.students
FOR EACH ROW EXECUTE FUNCTION public.update_student_access_on_student_change();

CREATE TRIGGER trg_insert_message_from_log
AFTER INSERT ON public.logs
FOR EACH ROW EXECUTE FUNCTION public.insert_message_from_log();

ALTER TABLE public.tingkat_classes
ADD COLUMN hidden boolean NOT NULL DEFAULT false;

ALTER TABLE public.tingkat_classes
ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read non-hidden tingkat_classes"
ON public.tingkat_classes
FOR SELECT
USING (hidden = false);

