# حل مشكلة Build Command في Vercel

إذا لم تستطع تعديل Build Command من الواجهة، استخدم أحد الحلول التالية:

## الحل 1: استخدام vercel.json (تم التطبيق)

تم تحديث ملف `vercel.json` ليتضمن:
- `"buildCommand": ""` - لتعطيل Build
- `"outputDirectory": "."` - لتحديد Output Directory

**الآن:**
1. Commit و Push التغييرات إلى GitHub
2. Vercel سيعيد Deploy تلقائياً
3. أو اضغط "Redeploy" في Vercel Dashboard

---

## الحل 2: تعطيل Build Command يدوياً

في Vercel Dashboard:

1. **Settings** → **General**
2. ابحث عن **"Build & Development Settings"**
3. في **"Build Command"**:
   - اتركه فارغ، أو
   - اكتب: `echo "No build needed"`
4. في **"Output Directory"**:
   - اكتب: `.`
5. **Save**

---

## الحل 3: استخدام Ignore Build Step

في Settings → General:

1. ابحث عن **"Ignore Build Step"**
2. اكتب: `echo "Skip build"`
3. Build Command سيتم تجاهله

---

## الحل 4: تغيير Framework Preset

1. في Project Settings
2. غير **Framework Preset** من "Other" إلى **"Static Site"**
3. سيتم تعطيل Build Command تلقائياً

---

## ✅ الحل الموصى به:

استخدم **الحل 1** (vercel.json) - تم التطبيق بالفعل.

بعد Push التغييرات، Vercel سيعرف أنه لا حاجة لـ Build.

