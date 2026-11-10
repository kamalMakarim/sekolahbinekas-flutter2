-- add file column to messeges table
ALTER TABLE messages ADD COLUMN files TEXT[];

--add file column to logs table
ALTER TABLE logs ADD COLUMN files TEXT[];


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
    log_id,
    files
  )
  SELECT NEW.message,
         s.id,
         NEW.images,
         NEW.user_id,
         'log',
         NEW.id,
         NEW.files
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