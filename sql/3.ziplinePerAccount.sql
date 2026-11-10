CREATE TABLE IF NOT EXISTS public.user_zipline_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at timestamptz DEFAULT now(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  zipline_token varchar NOT NULL
);

ALTER TABLE public.user_zipline_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can select their own zipline tokens" ON public.user_zipline_tokens
  FOR SELECT USING ((SELECT auth.uid()) = auth_id);
CREATE POLICY "Users can insert their own zipline tokens" ON public.user_zipline_tokens
  FOR INSERT WITH CHECK ((SELECT auth.uid()) = auth_id);
CREATE POLICY "Users can update their own zipline tokens" ON public.user_zipline_tokens
  FOR UPDATE USING ((SELECT auth.uid()) = auth_id)
  WITH CHECK ((SELECT auth.uid()) = auth_id);