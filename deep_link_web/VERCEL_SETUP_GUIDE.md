# دليل إعداد Vercel - خطوة بخطوة

## ⚠️ إعدادات مهمة يجب تغييرها:

### 1. Root Directory (مهم جداً!)
**غير:** `./`  
**إلى:** `deep_link_web`

**كيف:**
- اضغط على زر "Edit" بجانب Root Directory
- اكتب: `deep_link_web`
- اضغط Enter

### 2. Build Command
**غير:** `flutter build web --release`  
**إلى:** اتركه **فارغ** (لا حاجة لـ build)

**كيف:**
- اضغط على أيقونة القلم (pencil) بجانب Build Command
- احذف النص: `flutter build web --release`
- اتركه فارغ تماماً
- اضغط Enter

### 3. Output Directory
**غير:** `build/web`  
**إلى:** `.` (نقطة فقط)

**كيف:**
- اضغط على أيقونة القلم بجانب Output Directory
- احذف: `build/web`
- اكتب: `.`
- اضغط Enter

### 4. Framework Preset
**اتركه:** `Other` (صحيح)

### 5. Install Command
**اتركه:** مغلق (Toggle OFF) - صحيح

---

## 📋 ملخص الإعدادات النهائية:

```
Root Directory: deep_link_web
Framework Preset: Other
Build Command: (فارغ)
Output Directory: .
Install Command: (مغلق)
```

---

## ✅ بعد التعديل:

1. **اضغط "Deploy"** في الأسفل
2. انتظر حتى ينتهي الـ Deploy
3. ستحصل على رابط مثل: `https://wish-listy.vercel.app`

---

## 🧪 اختبار بعد النشر:

افتح هذه الروابط للتأكد:

1. **Landing Page:**
   - `https://wish-listy.vercel.app/`

2. **Android Verification:**
   - `https://wish-listy.vercel.app/.well-known/assetlinks.json`
   - يجب أن ترى JSON صحيح

3. **iOS Verification:**
   - `https://wish-listy.vercel.app/.well-known/apple-app-site-association`
   - يجب أن ترى JSON صحيح

---

## ⚠️ إذا ظهرت أخطاء:

### خطأ: "Cannot find module"
- تأكد من Root Directory = `deep_link_web`
- تأكد من Build Command فارغ

### خطأ: "Build failed"
- تأكد من Build Command فارغ
- تأكد من Output Directory = `.`

### الملفات لا تظهر
- تحقق من Root Directory
- تأكد من رفع مجلد `deep_link_web` في Git

---

## 💡 نصيحة:

بعد النشر الناجح، يمكنك:
- إضافة Domain مخصص في Settings → Domains
- استخدام الرابط في إعدادات Deep Links في التطبيق

