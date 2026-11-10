CREATE TABLE public.unread_count(
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at timestamptz NOT NULL DEFAULT now(),
    auth_id uuid NOT NULL,
    student_id uuid NOT NULL,
    count integer NOT NULL DEFAULT 0,
    UNIQUE(auth_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_unread_count_auth ON public.unread_count (auth_id);
CREATE INDEX IF NOT EXISTS idx_unread_count_student ON public.unread_count (student_id);

-- Insert existing student_access records into unread_count with count 0
INSERT INTO public.unread_count (auth_id, student_id, count)
SELECT sa.auth_id, sa.student_id, 0
FROM public.student_access sa
ON CONFLICT (auth_id, student_id) DO NOTHING;

-- Trigger function to handle insert on student_access
CREATE OR REPLACE FUNCTION public.handle_student_access_insert()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.unread_count (auth_id, student_id, count)
    VALUES (NEW.auth_id, NEW.student_id, 0)
    ON CONFLICT (auth_id, student_id) DO NOTHING;
    RETURN NEW;
END;
$$;

-- Trigger function on student_access delete to remove from unread_count
CREATE OR REPLACE FUNCTION public.handle_student_access_delete()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    DELETE FROM public.unread_count
    WHERE auth_id = OLD.auth_id AND student_id = OLD.student_id;
    RETURN OLD;
END;
$$;


-- Create trigger after insert student_access
CREATE TRIGGER trg_student_access_insert
AFTER INSERT ON public.student_access
FOR EACH ROW
EXECUTE FUNCTION public.handle_student_access_insert();

-- Create trigger after delete student_access
CREATE TRIGGER trg_student_access_delete
AFTER DELETE ON public.student_access
FOR EACH ROW 
EXECUTE FUNCTION public.handle_student_access_delete();

-- enable row level security
ALTER TABLE public.unread_count ENABLE ROW LEVEL SECURITY;

-- Policy to allow users to manage their own unread counts
CREATE POLICY "Users can update their own unread counts"
ON public.unread_count
FOR UPDATE
USING ((SELECT auth.uid()) = auth_id);
CREATE POLICY "Users can select their own unread counts"
ON public.unread_count
FOR SELECT
USING ((SELECT auth.uid()) = auth_id);

-- create function after messages insert to update unread counts for every unread_count of the student except the sender
CREATE OR REPLACE FUNCTION public.update_unread_count_on_message_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    UPDATE public.unread_count
    SET count = count + 1
    WHERE student_id = NEW.student_id AND auth_id <> NEW.sender_id;
    RETURN NEW;
END;
$$;

-- create trigger after insert on messages table
CREATE TRIGGER trg_update_unread_count_on_message_insert
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.update_unread_count_on_message_insert();

-- add reference
ALTER TABLE public.unread_count
ADD CONSTRAINT fk_unread_count_auth
FOREIGN KEY (auth_id) REFERENCES auth.users(id)
ON DELETE CASCADE;

ALTER TABLE public.unread_count
ADD CONSTRAINT fk_unread_count_student
FOREIGN KEY (student_id) REFERENCES public.students(id)
ON DELETE CASCADE;