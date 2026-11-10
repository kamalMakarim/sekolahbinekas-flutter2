-- SCANNER
CREATE TABLE public.scanners (
  id int PRIMARY KEY, 
  created_at timestamptz DEFAULT now()
);

-- EMPLOYEE DAN FINGERPRINT
-- BUAT TABEL fingerprint employee
DROP TABLE IF EXISTS public.employee_fingerprints CASCADE;
CREATE TABLE public.employee_fingerprints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  fingerprint_id int NOT NULL,
  scanner_id int NOT NULL REFERENCES public.scanners(id) ON DELETE CASCADE, -- ditambah scanner
  created_at timestamp DEFAULT now(),
  CONSTRAINT unique_fingerprint_per_scanner UNIQUE (scanner_id, fingerprint_id), -- scanner id dan fingerprint id harus unik
  CONSTRAINT unique_user_per_scanner UNIQUE (auth_id, scanner_id) -- user id dan scanner id harus unik
);

-- BUAT FUNGSI UPSERT fingerprint employee
CREATE OR REPLACE FUNCTION public.register_employee_fingerprint(
  p_email text, -- sekarang inputnya pakai email
  p_fingerprint_id int,
  p_scanner_id int
)
RETURNS void
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = '' 
AS $$
DECLARE
  v_auth_id uuid;
BEGIN
  SELECT auth_id INTO v_auth_id
  FROM public.users_public
  WHERE display_name = p_email;

  IF v_auth_id IS NULL THEN
    RAISE EXCEPTION 'User dengan email % tidak ditemukan.', p_email;
  END IF;

  INSERT INTO public.employee_fingerprints (auth_id, fingerprint_id, scanner_id)
  VALUES (v_auth_id, p_fingerprint_id, p_scanner_id)
  ON CONFLICT (auth_id, scanner_id)
  DO UPDATE SET fingerprint_id = EXCLUDED.fingerprint_id;
END;
$$;

-- FITUR ABSENSI
-- tipe absensi finger print atau selfie
CREATE TYPE attendance_method AS ENUM ('fingerprint', 'selfie');
-- buat tabel absen
DROP TABLE IF EXISTS public.employee_attendance CASCADE;
CREATE TABLE public.employee_attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  attendance_date date NOT NULL DEFAULT (now() AT TIME ZONE 'wast')::date,
  check_in time,
  check_in_method attendance_method,
  -- tambah metode lagi untuk cekoutnya, in case beda metode
  check_out time,
  check_out_method attendance_method,
  status text DEFAULT 'present', 
  -- koordinat lokasi dipindahkan ke tabel manual attendence
  CONSTRAINT unique_daily_attendance UNIQUE (auth_id, attendance_date),
  created_at timestamptz DEFAULT now()
);

-- tabel khusus manual attendence atau selfie
-- dari aplikasi, insert semuanya dulu ke sini jika selfie. lalu admin kenotif dan tinggal ubah is_verified dari false jadi true. kemudian, masuk ke employee_attendance
DROP TABLE IF EXISTS public.manual_attendance_details CASCADE;
CREATE TABLE public.manual_attendance_details (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_id uuid NOT NULL REFERENCES public.employee_attendance(id) ON DELETE CASCADE,
  auth_id uuid NOT NULL REFERENCES auth.users(id),
  selfie_url text NOT NULL,
  location_lat double precision NOT NULL,
  location_lng double precision NOT NULL,
  record_type text CHECK (record_type IN ('IN', 'OUT')),
  is_verified boolean DEFAULT NULL, -- is_verified jadinya di tabel manual
  created_at timestamptz DEFAULT (now() AT TIME ZONE 'wast')::timestamp
);

-- RLS Policy
ALTER TABLE public.employee_attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Employees can insert own attendance" ON public.employee_attendance;
DROP POLICY IF EXISTS "Employees and admins can view attendance" ON public.employee_attendance;

CREATE POLICY "Employees and admins can view attendance" ON public.employee_attendance
  FOR SELECT USING (
    auth_id = (select auth.uid())
    OR EXISTS (
      SELECT 1
      FROM public.users_private
      WHERE auth_id = (select auth.uid())
        AND (role = 'admin' OR role = 'hr') -- hr juga punya akses buat verif
    )
  );

  --RLS manual_attendance_details
ALTER TABLE public.manual_attendance_details ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Employees can insert own manual attendance" ON public.manual_attendance_details;
DROP POLICY IF EXISTS "Employees or HR can view own manual attendance" ON public.manual_attendance_details;
DROP POLICY IF EXISTS "HR can update manual attendance" ON public.manual_attendance_details;

CREATE POLICY "Employees can insert own manual attendance" ON public.manual_attendance_details
  FOR INSERT WITH CHECK (auth_id = (select auth.uid()) AND is_verified IS NULL);

CREATE POLICY "Employees or HR can view own manual attendance" ON public.manual_attendance_details
  AS PERMISSIVE
  FOR SELECT 
  USING (
    auth_id = (select auth.uid()) 
    OR EXISTS (SELECT 1 FROM public.users_private WHERE auth_id = (select auth.uid()) AND (role = 'admin' OR role = 'hr'))
);

CREATE POLICY "HR can update manual attendance" ON public.manual_attendance_details
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users_private WHERE auth_id = (select auth.uid()) AND (role = 'admin' OR role = 'hr'))
  );

  --RLS employee_fingerprints
ALTER TABLE public.employee_fingerprints ENABLE ROW LEVEL SECURITY;

  -- buat fungsi notif ke admin jika employee absen dengan selfie
CREATE OR REPLACE FUNCTION public.notify_manual_to_admin()
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.notifications (auth_id, title, body)
    SELECT 
        up.auth_id,
        'Perlu Verifikasi Absensi',
        'User ' || (SELECT COALESCE(display_name, 'Unknown') FROM public.users_public WHERE auth_id = NEW.auth_id) || ' absen via selfie.'
    FROM public.users_private up
    WHERE up.role = 'admin' OR up.role = 'hr';
    
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_notify_manual_attendance
AFTER INSERT ON public.manual_attendance_details
FOR EACH ROW EXECUTE FUNCTION public.notify_manual_to_admin(); -- trigger kalau ada insert ke manual attendance


-- buat edge function buat absen fingerprint (khusus metode fingerprint)
CREATE OR REPLACE FUNCTION public.process_fingerprint_attendance(
  p_fingerprint_id int,
  p_scanner_id int -- tambahin scannernya juga
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER 
SET search_path = ''
AS $$
DECLARE
  v_auth_id uuid;
  v_emp_name text;
  v_attendance_id uuid;
BEGIN
    -- cek siapa punya fingerprintnya
  SELECT ef.auth_id, COALESCE(up.display_name, 'User')
  INTO v_auth_id, v_emp_name
  FROM public.employee_fingerprints ef
  LEFT JOIN public.users_public up ON ef.auth_id = up.auth_id
  WHERE ef.fingerprint_id = p_fingerprint_id AND ef.scanner_id = p_scanner_id;

  -- jika tidak ada return error
  IF v_auth_id IS NULL THEN
    RETURN json_build_object('status', 'error', 'message', 'ID tidak dikenal');
  END IF;

    -- jika ada, upsert ke tabel absen
  INSERT INTO public.employee_attendance (
    auth_id, 
    check_in, 
    check_in_method
  )
  VALUES (
    v_auth_id,
    (now() AT TIME ZONE 'Asia/Jakarta')::time,
    'fingerprint'
  )
  
  ON CONFLICT (auth_id, attendance_date) 
  DO UPDATE SET 
    check_out = (now() AT TIME ZONE 'Asia/Jakarta')::time,
    check_out_method = 'fingerprint'
  RETURNING id INTO v_attendance_id;

-- return ke hardware
  RETURN json_build_object(
    'status', 'success', 
    'name', v_emp_name, 
    'time', (now() AT TIME ZONE 'Asia/Jakarta')::time
  );

EXCEPTION WHEN OTHERS THEN
  RETURN json_build_object('status', 'error', 'message', SQLERRM);
END;
$$;

-- fungsi untuk mencatat cekin cekout dari selfie ke employee_attendance
CREATE OR REPLACE FUNCTION public.sync_manual_to_master()
RETURNS trigger 
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
  -- hanya jalan jika yang diupdate is_verifiednya dari false ke true
  IF NEW.is_verified IS TRUE AND OLD.is_verified IS FALSE THEN
    INSERT INTO public.employee_attendance (id, auth_id, attendance_date, shift_id)
    VALUES (NEW.attendance_id, NEW.auth_id, (NEW.created_at AT TIME ZONE 'Asia/Jakarta')::date, NEW.shift_id)
    ON CONFLICT (auth_id, attendance_date) DO NOTHING; 

    IF NEW.record_type = 'IN' THEN
      UPDATE public.employee_attendance 
      SET check_in = NEW.created_at::time, check_in_method = 'selfie'
      WHERE id = NEW.attendance_id;
    ELSE
      UPDATE public.employee_attendance 
      SET check_out = NEW.created_at::time, check_out_method = 'selfie'
      WHERE id = NEW.attendance_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_manual_attendance
-- after update dari is_verified false jadi true
AFTER UPDATE ON public.manual_attendance_details
FOR EACH ROW EXECUTE FUNCTION public.sync_manual_to_master();
