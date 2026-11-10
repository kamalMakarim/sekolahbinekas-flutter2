-- ========================
-- 0. TYPES / ENUMS
-- ========================
DROP TYPE IF EXISTS role CASCADE;
DROP TYPE IF EXISTS classes CASCADE;
DROP TYPE IF EXISTS student_status CASCADE;
DROP TYPE IF EXISTS message_type CASCADE;

CREATE TYPE role AS ENUM (
  'admin', 'teacher', 'parent', 'bidang_study_tk', 'bidang_study_sd', 'accountant', 'z_test', 'multimedia', 'other_employee', 'hr'
);

CREATE TYPE classes AS ENUM (
  'Blue Pinter Morning',
  'Blue Pinter Afternoon',
  'Green Motekar',
  'Green Wanter',
  'Green Maher',
  'Yellow Maher',
  'Yellow Motekar',
  'Yellow Wanter',
  'Gumujeng',
  'Someah',
  'Rancage',
  'Gentur',
  'Macakal',
  'Calakan',
  'Singer',
  'Rancingeus',
  'Jatmika',
  'Gumanti',
  'Marahmay',
  'Rucita',
  'Binangkit',
  'Gumilang',
  'Sonagar',
  'Bidang Study TK',
  'Bidang Study SD',
  'Z Test Class'
);

CREATE TYPE student_status AS ENUM ('pending', 'authenticated', 'rejected');

-- used by messages
CREATE TYPE message_type AS ENUM ('message', 'log');

-- ========================
-- 1. DROP TRIGGERS & FUNCTIONS (safe)
-- ========================
-- Drop triggers in auth schema
DROP TRIGGER IF EXISTS trg_mirror_auth_user ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Drop triggers in public schema
DROP TRIGGER IF EXISTS trg_update_student_access ON public.users_private;
DROP TRIGGER IF EXISTS trg_update_student_access_on_student_change ON public.students;
DROP TRIGGER IF EXISTS trg_insert_message_from_log ON public.logs;
DROP TRIGGER IF EXISTS trg_promote_student ON public.students_pending;
DROP TRIGGER IF EXISTS trigger_notify_related_users ON public.messages;

-- Now drop functions (if exist)
DROP FUNCTION IF EXISTS public.insert_message_from_log() CASCADE;
DROP FUNCTION IF EXISTS public.mirror_auth_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_student_access() CASCADE;
DROP FUNCTION IF EXISTS public.update_student_access_on_student_change() CASCADE;
DROP FUNCTION IF EXISTS public.promote_student() CASCADE;
DROP FUNCTION IF EXISTS public.notify_message() CASCADE;

-- ========================
-- 2. DROP TABLES
-- ========================
DROP TABLE IF EXISTS public.student_access CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.students CASCADE;
DROP TABLE IF EXISTS public.users_public CASCADE;
DROP TABLE IF EXISTS public.users_private CASCADE;
DROP TABLE IF EXISTS public.logs CASCADE;
DROP TABLE IF EXISTS public.fcm_tokens CASCADE;
DROP TABLE IF EXISTS public.students_pending CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;

-- ========================
-- 3. CREATE TABLES
-- ========================
-- Public-facing user data
CREATE TABLE public.users_public (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  auth_id uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name varchar NOT NULL,
  profile_picture text DEFAULT ''
);

-- FCM tokens table
CREATE TABLE public.fcm_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fcm_token text,
  UNIQUE (auth_id)
);

-- Private/internal user data
CREATE TABLE public.users_private (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  role role NOT NULL DEFAULT 'parent',
  class_name classes,
  email varchar NOT NULL UNIQUE,
  auth_id uuid UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Students table
CREATE TABLE public.students (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  parent_auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name varchar NOT NULL,
  batch smallint NOT NULL,
  class_name classes NOT NULL,
  has_paid boolean DEFAULT true
);

-- Student access table
CREATE TABLE public.student_access (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  UNIQUE (student_id, auth_id)
);

-- Logs table
CREATE TABLE public.logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  message text NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  images text[],
  class_name classes NOT NULL
);

-- Messages table
CREATE TABLE public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  message text NOT NULL,
  student_id uuid NOT NULL REFERENCES public.students(id) ON DELETE CASCADE,
  images text[],
  -- store auth.users.id of the sender; referencing users_public.auth_id (unique) is allowed
  sender_id uuid NOT NULL REFERENCES public.users_public(auth_id) ON DELETE CASCADE,
  log_id uuid REFERENCES public.logs(id) ON DELETE CASCADE,
  message_type message_type NOT NULL DEFAULT 'message'
);

-- Students pending table
CREATE TABLE public.students_pending (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  parent_auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name varchar NOT NULL,
  batch smallint NOT NULL,
  class_name classes NOT NULL,
  status student_status DEFAULT 'pending'
);

-- Notifications table
CREATE TABLE public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title varchar NOT NULL,
  body text NOT NULL
);

-- ========================
-- 3.1 Indexes for performance (common lookup patterns)
-- ========================
CREATE INDEX IF NOT EXISTS idx_student_access_auth_id ON public.student_access (auth_id);
CREATE INDEX IF NOT EXISTS idx_student_access_student_id ON public.student_access (student_id);
CREATE INDEX IF NOT EXISTS idx_get_messages ON public.messages (student_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_students_class_name ON public.students (class_name);

-- ========================
-- 4. FUNCTIONS
-- Note: SECURITY DEFINER kept as you had it; search_path locked to ''
-- ========================

-- Function to insert messages for every student in a class when a log is added
CREATE OR REPLACE FUNCTION public.insert_message_from_log()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
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
      -- If teacher is Bidang Study TK, send to students in TK classes
      NEW.class_name = 'Bidang Study TK'
      AND s.class_name IN (
        'Blue Pinter Morning', 'Blue Pinter Afternoon',
        'Green Motekar', 'Green Wanter', 'Green Maher',
        'Yellow Maher', 'Yellow Motekar', 'Yellow Wanter'
      )
    )
    OR
    (
      -- If teacher is Bidang Study SD, send to students in SD classes
      NEW.class_name = 'Bidang Study SD'
      AND s.class_name IN (
        'Gumujeng', 'Someah', 'Rancage', 'Gentur', 'Macakal',
        'Calakan', 'Singer', 'Rancingeus', 'Jatmika', 'Gumanti',
        'Marahmay', 'Rucita', 'Binangkit', 'Gumilang', 'Sonagar', 'Z Test Class'
      )
    )
    OR
    (
      -- default behavior: send to students of the same class
      NEW.class_name NOT IN ('Bidang Study TK', 'Bidang Study SD')
      AND s.class_name = NEW.class_name
    );
  RETURN NEW;
END;
$$;

-- Mirror auth.users into public tables
CREATE OR REPLACE FUNCTION public.mirror_auth_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- Create public and private rows for new auth user.
  INSERT INTO public.users_public (auth_id, display_name)
  VALUES (NEW.id, NEW.email);

  INSERT INTO public.users_private (role, auth_id, email)
  VALUES ('parent', NEW.id, NEW.email);

  RETURN NEW;
END;
$$;

-- Update update_student_access
CREATE OR REPLACE FUNCTION public.update_student_access()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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

  -- Bidang Study TK (all TK students)
  IF NEW.role = 'bidang_study_tk' THEN
    INSERT INTO public.student_access (student_id, auth_id)
    SELECT s.id, NEW.auth_id
    FROM public.students s
    WHERE s.class_name IN (
      'Blue Pinter Morning',
      'Blue Pinter Afternoon',
      'Green Motekar',
      'Green Wanter',
      'Green Maher',
      'Yellow Maher',
      'Yellow Motekar',
      'Yellow Wanter'
    )
    ON CONFLICT (student_id, auth_id) DO NOTHING;
  END IF;

  -- Bidang Study SD (all SD students)
  IF NEW.role = 'bidang_study_sd' THEN
    INSERT INTO public.student_access (student_id, auth_id)
    SELECT s.id, NEW.auth_id
    FROM public.students s
    WHERE s.class_name IN (
      'Gumujeng',
      'Someah',
      'Rancage',
      'Gentur',
      'Macakal',
      'Calakan',
      'Singer',
      'Rancingeus',
      'Jatmika',
      'Gumanti',
      'Marahmay',
      'Rucita',
      'Binangkit',
      'Gumilang',
      'Sonagar',
      'Z Test Class'
    )
    ON CONFLICT (student_id, auth_id) DO NOTHING;
  END IF;

  RETURN NEW;
END;
$$;


-- Update update_student_access_on_student_change
CREATE OR REPLACE FUNCTION public.update_student_access_on_student_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
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

    -- bidang_study_tk
    IF NEW.class_name IN (
      'Blue Pinter Morning','Blue Pinter Afternoon','Green Motekar','Green Wanter',
      'Green Maher','Yellow Maher','Yellow Motekar','Yellow Wanter'
    ) THEN
      INSERT INTO public.student_access (student_id, auth_id)
      SELECT NEW.id, up.auth_id
      FROM public.users_private up
      WHERE up.role = 'bidang_study_tk'
      ON CONFLICT (student_id, auth_id) DO NOTHING;
    END IF;

    -- bidang_study_sd
    IF NEW.class_name IN (
      'Gumujeng','Someah','Rancage','Gentur','Macakal','Calakan','Singer',
      'Rancingeus','Jatmika','Gumanti','Marahmay','Rucita','Binangkit','Gumilang','Sonagar','Z Test Class'
    ) THEN
      INSERT INTO public.student_access (student_id, auth_id)
      SELECT NEW.id, up.auth_id
      FROM public.users_private up
      WHERE up.role = 'bidang_study_sd'
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

      -- If old class was TK, remove bidang_study_tk access
      IF OLD.class_name IN (
        'Blue Pinter Morning','Blue Pinter Afternoon','Green Motekar','Green Wanter',
        'Green Maher','Yellow Maher','Yellow Motekar','Yellow Wanter'
      ) THEN
        DELETE FROM public.student_access
        WHERE student_id = NEW.id
          AND auth_id IN (
            SELECT up.auth_id
            FROM public.users_private up
            WHERE up.role = 'bidang_study_tk'
          );
      END IF;

      -- If new class is TK, add bidang_study_tk access
      IF NEW.class_name IN (
        'Blue Pinter Morning','Blue Pinter Afternoon','Green Motekar','Green Wanter',
        'Green Maher','Yellow Maher','Yellow Motekar','Yellow Wanter'
      ) THEN
        INSERT INTO public.student_access (student_id, auth_id)
        SELECT NEW.id, up.auth_id
        FROM public.users_private up
        WHERE up.role = 'bidang_study_tk'
        ON CONFLICT (student_id, auth_id) DO NOTHING;
      END IF;

      -- If old class was SD, remove bidang_study_sd access
      IF OLD.class_name IN (
        'Gumujeng','Someah','Rancage','Gentur','Macakal','Calakan','Singer',
        'Rancingeus','Jatmika','Gumanti','Marahmay','Rucita','Binangkit','Gumilang','Sonagar','Z Test Class'
      ) THEN
        DELETE FROM public.student_access
        WHERE student_id = NEW.id
          AND auth_id IN (
            SELECT up.auth_id
            FROM public.users_private up
            WHERE up.role = 'bidang_study_sd'
          );
      END IF;

      -- If new class is SD, add bidang_study_sd access
      IF NEW.class_name IN (
        'Gumujeng','Someah','Rancage','Gentur','Macakal','Calakan','Singer',
        'Rancingeus','Jatmika','Gumanti','Marahmay','Rucita','Binangkit','Gumilang','Sonagar','Z Test Class'
      ) THEN
        INSERT INTO public.student_access (student_id, auth_id)
        SELECT NEW.id, up.auth_id
        FROM public.users_private up
        WHERE up.role = 'bidang_study_sd'
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

-- Replace promote_student so promoting also creates student_access rows
CREATE OR REPLACE FUNCTION public.promote_student()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_student_id uuid;
BEGIN
  -- when pending becomes authenticated, create real student and grant access
  IF NEW.status = 'authenticated' AND (OLD.status IS DISTINCT FROM 'authenticated') THEN

    INSERT INTO public.students (parent_auth_id, name, batch, class_name)
    VALUES (NEW.parent_auth_id, NEW.name, NEW.batch, NEW.class_name)
    RETURNING id INTO v_student_id;

    -- Grant access to the parent (if not already present)
    INSERT INTO public.student_access (student_id, auth_id)
    VALUES (v_student_id, NEW.parent_auth_id)
    ON CONFLICT (student_id, auth_id) DO NOTHING;

    -- Grant access to teachers in that class (if any)
    INSERT INTO public.student_access (student_id, auth_id)
    SELECT v_student_id, up.auth_id
    FROM public.users_private up
    WHERE up.role = 'teacher'
      AND up.class_name = NEW.class_name
    ON CONFLICT (student_id, auth_id) DO NOTHING;

  END IF;

  RETURN NEW;
END;
$$;

-- Notify related users when a message is inserted
CREATE OR REPLACE FUNCTION public.notify_message()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN

  -- Case 1: If this is a log message → notify ONLY the parent
  IF NEW.message_type = 'log' THEN

    INSERT INTO public.notifications (auth_id, title, body)
    SELECT
      s.parent_auth_id AS auth_id,
      up.display_name || '(' || s.name || ')' AS title,
      SUBSTRING(NEW.message FROM 1 FOR 100) AS body
    FROM public.students s
    JOIN public.users_public up ON up.auth_id = NEW.sender_id
    WHERE s.id = NEW.student_id
      AND s.parent_auth_id <> NEW.sender_id; -- Avoid self-notify

  ELSE
    -- Case 2: Normal message → notify all student access except sender
    INSERT INTO public.notifications (auth_id, title, body)
    SELECT 
      sa.auth_id,
      up.display_name || ' (' || s.name || ')' AS title,
      SUBSTRING(NEW.message FROM 1 FOR 100) AS body
    FROM public.student_access sa
    JOIN public.students s ON s.id = sa.student_id
    JOIN public.users_public up ON up.auth_id = NEW.sender_id
    WHERE sa.student_id = NEW.student_id
      AND sa.auth_id <> NEW.sender_id;

  END IF;

  RETURN NEW;
END;
$$;

-- ========================
-- 5. TRIGGERS (attach functions to tables)
-- ========================
CREATE TRIGGER trg_mirror_auth_user
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.mirror_auth_user();

CREATE TRIGGER trg_update_student_access
AFTER INSERT OR UPDATE ON public.users_private
FOR EACH ROW EXECUTE FUNCTION public.update_student_access();

CREATE TRIGGER trg_update_student_access_on_student_change
AFTER INSERT OR UPDATE OR DELETE ON public.students
FOR EACH ROW EXECUTE FUNCTION public.update_student_access_on_student_change();

CREATE TRIGGER trg_insert_message_from_log
AFTER INSERT ON public.logs
FOR EACH ROW EXECUTE FUNCTION public.insert_message_from_log();

CREATE TRIGGER trg_promote_student
AFTER UPDATE OF status ON public.students_pending
FOR EACH ROW EXECUTE FUNCTION public.promote_student();

CREATE TRIGGER trigger_notify_related_users
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.notify_message();

-- ========================
-- 6. ENABLE RLS
-- ========================
ALTER TABLE public.users_public ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users_private ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students_pending ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ========================
-- 7. POLICIES (kept as you wrote them, minor cleanup)
-- ========================

-- USERS_PUBLIC
CREATE POLICY "Public can view users_public" ON public.users_public
  FOR SELECT USING (true);

CREATE POLICY "User can update own users_public" ON public.users_public
  FOR UPDATE USING ((SELECT auth.uid()) = auth_id);

-- MESSAGES
CREATE POLICY "Can read messages for accessible students" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.student_access sa
      WHERE sa.student_id = public.messages.student_id
        AND sa.auth_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Can insert messages for accessible students as own user" ON public.messages
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.student_access sa
      WHERE sa.student_id = public.messages.student_id
        AND sa.auth_id = (SELECT auth.uid())
        AND public.messages.sender_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Can delete own messages" ON public.messages
  FOR DELETE USING (public.messages.sender_id = (SELECT auth.uid()));

CREATE POLICY "Can update own messages" ON public.messages
  FOR UPDATE USING (public.messages.sender_id = (SELECT auth.uid()));

-- STUDENTS
CREATE POLICY "Can view accessible students" ON public.students
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.student_access sa
      WHERE sa.student_id = public.students.id
        AND sa.auth_id = (SELECT auth.uid())
    )
  );

-- USERS_PRIVATE
CREATE POLICY "User can view own private data" ON public.users_private
  FOR SELECT USING ((SELECT auth.uid()) = auth_id);

-- STUDENT_ACCESS
CREATE POLICY "User can view their own student_access" ON public.student_access
  FOR SELECT USING (auth_id = (SELECT auth.uid()));

-- LOGS
CREATE POLICY "Can view logs for accessible students" ON public.logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1
      FROM public.students s
      JOIN public.student_access sa ON sa.student_id = s.id
      WHERE sa.auth_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "only non parent can create logs" ON public.logs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users_private up
      WHERE up.auth_id = (SELECT auth.uid())
        AND up.role <> 'parent'
        AND up.class_name = public.logs.class_name
    )
  );

CREATE POLICY "only writer can delete own logs" ON public.logs
  FOR DELETE USING (public.logs.user_id = (SELECT auth.uid()));

-- FCM_TOKENS
CREATE POLICY "User can manage their own FCM tokens" ON public.fcm_tokens
  FOR ALL USING (auth_id = (SELECT auth.uid()))
  WITH CHECK (auth_id = (SELECT auth.uid()));

-- STUDENTS_PENDING
CREATE POLICY "Only parent can insert own pending student" ON public.students_pending
  FOR INSERT WITH CHECK (parent_auth_id = (SELECT auth.uid()));
CREATE POLICY "Parent can view own pending students" ON public.students_pending
  FOR SELECT USING (parent_auth_id = (SELECT auth.uid()));
CREATE POLICY "Only parent can delete own pending students" ON public.students_pending
  FOR DELETE USING (parent_auth_id = (SELECT auth.uid()));
