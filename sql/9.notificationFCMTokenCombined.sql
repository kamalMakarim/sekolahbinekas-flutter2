ALTER TABLE public.notifications
ADD COLUMN fcm_token text;

CREATE OR REPLACE FUNCTION set_fcm_token_before_insert()
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.fcm_token IS NULL THEN
        SELECT fcm_token INTO NEW.fcm_token
        FROM public.fcm_tokens
        WHERE auth_id = NEW.auth_id
        LIMIT 1;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER notifications_set_fcm_token
BEFORE INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION set_fcm_token_before_insert();