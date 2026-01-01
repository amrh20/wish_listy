# رفع Deep Link Web Assets على Vercel

## الطريقة 1: رفع مجلد `deep_link_web` كمشروع منفصل (موصى بها)

هذه الطريقة الأسهل - Vercel سيتعرف تلقائياً على الإعدادات.

### الخطوات:

1. **اذهب إلى [vercel.com](https://vercel.com)**
   - سجل دخول أو أنشئ حساب

2. **اضغط على "Add New Project"**

3. **اختر "Import Git Repository"**
   - إذا كان الـ repository على GitHub/GitLab/Bitbucket
   - أو استخدم "Deploy" لرفع الملفات مباشرة

4. **إذا كنت ترفع مباشرة (بدون Git):**
   - اضغط "Deploy"
   - اسحب مجلد `deep_link_web` إلى المتصفح
   - أو استخدم Vercel CLI (انظر الطريقة 2)

5. **إعدادات المشروع:**
   - **Project Name:** `wishlisty-deep-links` (أو أي اسم تختاره)
   - **Framework Preset:** Other (أو Static)
   - **Root Directory:** `.` (لأنك رفعت مجلد `deep_link_web` مباشرة)
   - **Build Command:** اتركه فارغ
   - **Output Directory:** `.`

6. **اضغط "Deploy"**

7. **بعد النشر:**
   - ستحصل على رابط مثل: `https://wishlisty-deep-links.vercel.app`
   - استخدم هذا الرابط في إعدادات Deep Links

---

## الطريقة 2: استخدام Vercel CLI (للمطورين)

### التثبيت:

```bash
npm i -g vercel
```

### النشر:

```bash
cd deep_link_web
vercel
```

اتبع التعليمات في Terminal:
- `? Set up and deploy?` → Yes
- `? Which scope?` → اختر حسابك
- `? Link to existing project?` → No (أول مرة)
- `? What's your project's name?` → `wishlisty-deep-links`
- `? In which directory is your code located?` → `./`

### للنشر الإنتاجي:

```bash
vercel --prod
```

---

## الطريقة 3: ربط Repository الحالي (إذا كان على Git)

إذا كان المشروع الأساسي على GitHub/GitLab:

### الخطوات:

1. **في Vercel Dashboard:**
   - اضغط "Add New Project"
   - اختر الـ repository الخاص بمشروعك

2. **إعدادات Build:**
   - **Framework Preset:** Other
   - **Root Directory:** `deep_link_web` (مهم!)
   - **Build Command:** اتركه فارغ
   - **Output Directory:** `.`

3. **Environment Variables:** (لا حاجة لإضافة شيء الآن)

4. **اضغط "Deploy"**

---

## بعد النشر - التحقق من الملفات:

بعد النشر، تأكد من أن الملفات متاحة:

1. **افتح:** `https://YOUR-DOMAIN.vercel.app/.well-known/assetlinks.json`
   - يجب أن ترى محتوى JSON

2. **افتح:** `https://YOUR-DOMAIN.vercel.app/.well-known/apple-app-site-association`
   - يجب أن ترى محتوى JSON (بدون extension)

3. **تحقق من Headers:**
   - افتح Developer Tools → Network
   - تحقق أن `Content-Type: application/json`

---

## ملاحظات مهمة:

1. **Domain مخصص:**
   - في Vercel Dashboard → Settings → Domains
   - يمكنك إضافة domain مخصص مثل `links.wishlisty.app`

2. **ملف `vercel.json`:**
   - موجود بالفعل في المشروع
   - يضمن أن `.well-known` يتم تقديمها كـ JSON

3. **HTTPS مطلوب:**
   - Vercel يوفر HTTPS تلقائياً
   - Deep Links تحتاج HTTPS للعمل

4. **اختبار Deep Links:**
   - استخدم الرابط في Android/iOS app configuration
   - مثال: `https://YOUR-DOMAIN.vercel.app/.well-known/assetlinks.json`

---

## استكشاف الأخطاء:

### الملفات لا تظهر:
- تحقق من Root Directory في Vercel settings
- تأكد من رفع جميع الملفات

### Content-Type غير صحيح:
- تحقق من `vercel.json`
- أعد النشر

### 404 Not Found:
- تأكد من مسار الملفات
- تحقق من وجود `.well-known` folder

