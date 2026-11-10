CREATE TABLE
    public.read_check (
        id uuid PRIMARY KEY DEFAULT gen_random_uuid (),
        created_at timestamptz NOT NULL DEFAULT now (),
        auth_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
        message_id uuid NOT NULL REFERENCES public.messages (id) ON DELETE CASCADE,
        UNIQUE (auth_id, message_id)
    );

-- create index for faster lookup
CREATE INDEX idx_read_check_auth_id ON public.read_check (auth_id);

CREATE INDEX idx_read_check_message_id ON public.read_check (message_id);

-- enable row level security
ALTER TABLE public.read_check ENABLE ROW LEVEL SECURITY;

-- add policy to allow users to insert their own read_check
CREATE POLICY "allow users to insert their own read_check" ON public.read_check FOR INSERT
WITH
    CHECK (
        auth_id = (
            SELECT
                auth.uid ()
        )
    );

-- all user sellect read check for messages they have access to
CREATE POLICY "user with access to message can read read_check" ON public.read_check FOR
SELECT
    USING (
        EXISTS (
            SELECT
                1
            FROM
                public.messages AS m
                JOIN public.student_access AS sa ON m.student_id = sa.student_id
            WHERE
                m.id = public.read_check.message_id
                AND sa.auth_id = (
                    SELECT
                        auth.uid ()
                )
        )
    );