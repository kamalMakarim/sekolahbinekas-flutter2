ALTER TABLE public.notifications
ADD COLUMN image_url text;

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

        INSERT INTO public.notifications (auth_id, title, body, image_url)
        SELECT
            s.parent_auth_id AS auth_id,
            up.display_name || '(' || s.name || ')' AS title,
            SUBSTRING(NEW.message FROM 1 FOR 100) AS body,
            up.profile_picture AS image_url
        FROM public.students s
        JOIN public.users_public up ON up.auth_id = NEW.sender_id
        WHERE s.id = NEW.student_id
            AND s.parent_auth_id <> NEW.sender_id; -- Avoid self-notify

    ELSE
        -- Case 2: Normal message → notify all student access except sender
        INSERT INTO public.notifications (auth_id, title, body, image_url)
        SELECT 
            sa.auth_id,
            up.display_name || ' (' || s.name || ')' AS title,
            SUBSTRING(NEW.message FROM 1 FOR 100) AS body,
            up.profile_picture AS image_url
        FROM public.student_access sa
        JOIN public.students s ON s.id = sa.student_id
        JOIN public.users_public up ON up.auth_id = NEW.sender_id
        WHERE sa.student_id = NEW.student_id
            AND sa.auth_id <> NEW.sender_id;

    END IF;
  RETURN NEW;
END;
$$;
