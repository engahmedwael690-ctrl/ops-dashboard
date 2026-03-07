-- =============================================
-- نظام المواقع والزيارات — Phase 1
-- شغّل كل ده في SQL Editor في Supabase
-- =============================================

-- 1. جدول المواقع
CREATE TABLE IF NOT EXISTS sites (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,                          -- اسم الموقع
  address TEXT,                                -- العنوان
  region TEXT,                                 -- المنطقة / المحافظة
  client_name TEXT,                            -- اسم العميل / المسؤول
  client_phone TEXT,                           -- رقم العميل
  client_email TEXT,                           -- إيميل العميل
  agreed_visits INTEGER DEFAULT 0,             -- عدد الزيارات المتفق عليها
  contract_start DATE,                         -- بداية العقد
  contract_end DATE,                           -- نهاية العقد
  visit_frequency TEXT DEFAULT 'monthly',      -- تكرار الزيارة: monthly / weekly / quarterly
  notes TEXT,                                  -- ملاحظات عامة
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE sites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sites_all" ON sites FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_sites_active ON sites(is_active);

-- 2. جدول المهندسين
CREATE TABLE IF NOT EXISTS engineers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,                          -- الاسم
  phone TEXT,                                  -- رقم الهاتف
  email TEXT,                                  -- الإيميل
  address TEXT,                                -- العنوان
  specialty TEXT,                              -- التخصص
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE engineers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "engineers_all" ON engineers FOR ALL USING (true) WITH CHECK (true);

-- 3. جدول الزيارات
CREATE TABLE IF NOT EXISTS visits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  site_id UUID REFERENCES sites(id) ON DELETE CASCADE NOT NULL,
  scheduled_date DATE NOT NULL,                -- التاريخ المجدول
  actual_date DATE,                            -- التاريخ الفعلي
  status TEXT DEFAULT 'scheduled' CHECK (
    status IN ('scheduled','completed','postponed','cancelled')
  ),
  postpone_reason TEXT,                        -- سبب التأجيل
  postponed_to DATE,                           -- مؤجل إلى
  cancel_reason TEXT,                          -- سبب الإلغاء
  general_notes TEXT,                          -- ملاحظات الزيارة
  followup_notes TEXT,                         -- ملاحظات الفولو أب
  visit_number INTEGER,                        -- رقم الزيارة (1,2,3...)
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE visits ENABLE ROW LEVEL SECURITY;
CREATE POLICY "visits_all" ON visits FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_visits_site ON visits(site_id);
CREATE INDEX IF NOT EXISTS idx_visits_date ON visits(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_visits_status ON visits(status);

-- 4. جدول المهندسين في الزيارة (many-to-many)
CREATE TABLE IF NOT EXISTS visit_engineers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  visit_id UUID REFERENCES visits(id) ON DELETE CASCADE NOT NULL,
  engineer_id UUID REFERENCES engineers(id) ON DELETE CASCADE NOT NULL,
  rating INTEGER CHECK (rating >= 1 AND rating <= 5), -- تقييم من 1 لـ 5
  rating_notes TEXT,                           -- ملاحظات التقييم
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(visit_id, engineer_id)
);

ALTER TABLE visit_engineers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "visit_engineers_all" ON visit_engineers FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_ve_visit ON visit_engineers(visit_id);
CREATE INDEX IF NOT EXISTS idx_ve_engineer ON visit_engineers(engineer_id);

-- 5. جدول صور الزيارة
CREATE TABLE IF NOT EXISTS visit_photos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  visit_id UUID REFERENCES visits(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,                     -- رابط الصورة في Supabase Storage
  caption TEXT,                                -- وصف الصورة
  uploaded_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE visit_photos ENABLE ROW LEVEL SECURITY;
CREATE POLICY "visit_photos_all" ON visit_photos FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_photos_visit ON visit_photos(visit_id);

-- 6. جدول ملاحظات الفولو أب (مستمرة لكل موقع)
CREATE TABLE IF NOT EXISTS site_followup (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  site_id UUID REFERENCES sites(id) ON DELETE CASCADE NOT NULL,
  note TEXT NOT NULL,
  note_date DATE DEFAULT CURRENT_DATE,
  created_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE site_followup ENABLE ROW LEVEL SECURITY;
CREATE POLICY "followup_all" ON site_followup FOR ALL USING (true) WITH CHECK (true);
CREATE INDEX IF NOT EXISTS idx_followup_site ON site_followup(site_id);

-- 7. Supabase Storage bucket للصور
INSERT INTO storage.buckets (id, name, public)
VALUES ('visit-photos', 'visit-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "visit_photos_storage" ON storage.objects
  FOR ALL USING (bucket_id = 'visit-photos') WITH CHECK (bucket_id = 'visit-photos');
