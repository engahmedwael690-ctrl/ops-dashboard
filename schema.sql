-- =============================================
-- لوحة المتابعة — Schema قاعدة البيانات
-- انسخ هذا الكود في SQL Editor في Supabase
-- =============================================

CREATE TABLE tasks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  section TEXT NOT NULL CHECK (section IN ('ops', 'qual')),
  subtype TEXT NOT NULL DEFAULT 'other',
  priority TEXT NOT NULL DEFAULT 'med' CHECK (priority IN ('high', 'med', 'low')),
  due_at TIMESTAMPTZ,
  reminder_minutes INTEGER DEFAULT 0,
  completed BOOLEAN DEFAULT FALSE,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- تفعيل أمان الصفوف
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- السماح بكل العمليات (غير القابل للمصادقة - للاستخدام الشخصي)
CREATE POLICY "Allow all operations" ON tasks
  FOR ALL USING (true) WITH CHECK (true);

-- فهارس للأداء
CREATE INDEX idx_tasks_due_at ON tasks(due_at);
CREATE INDEX idx_tasks_section ON tasks(section);
CREATE INDEX idx_tasks_completed ON tasks(completed);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);
