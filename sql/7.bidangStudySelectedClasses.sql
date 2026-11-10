-- remve existing policies
DROP POLICY IF EXISTS "only non parent can create logs" ON public.logs;


CREATE POLICY "only non parent can create logs" ON public.logs
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users_private up
      WHERE up.auth_id = (SELECT auth.uid())
        AND up.role <> 'parent'
    )
  );
