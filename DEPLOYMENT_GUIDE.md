# دليل رفع التطبيق على الإنترنت
# Deployment Guide

## طريقة رفع المشروع على Vercel

### الطريقة الأولى: من الـ Web Interface (الأسهل) 🚀

1. **سجّل دخول على Vercel:**
   - روح على https://vercel.com
   - سجل دخول بحساب GitHub أو Google

2. **ارفع المشروع:**
   - اضغط على "New Project"
   - اختار "Import Git Repository" 
   - أو اختار "Import from local folder"

3. **اختار مجلد build/web:**
   - بدل ما ترفع المشروع كله، ارفع مجلد `build/web` بس
   - أو ارفع المشروع كله وVercel هيبيلد تلقائياً

4. **خلاص! 🎉**
   - Vercel هيديك لينك زي: `https://wish-listy-xxxxx.vercel.app`
   - ابعت اللينك ده لصاحبك الـ Backend

---

### الطريقة الثانية: من الـ CLI (Command Line)

1. **نزّل Vercel CLI:**
   ```bash
   npm install -g vercel
   ```

2. **سجل دخول:**
   ```bash
   vercel login
   ```

3. **ارفع المشروع:**
   ```bash
   cd /Users/Marwa/wish_listy
   vercel --prod
   ```

4. **Vercel هيسألك أسئلة:**
   - Project name؟ اضغط Enter (هيستخدم اسم المجلد)
   - Build command؟ اكتب: `flutter build web --release`
   - Output directory؟ اكتب: `build/web`

---

## خيارات تانية لرفع المشروع:

### 1. Netlify 🟢
```bash
# نزّل Netlify CLI
npm install -g netlify-cli

# سجل دخول
netlify login

# ارفع المشروع
cd /Users/Marwa/wish_listy
netlify deploy --prod --dir=build/web
```

### 2. Firebase Hosting 🔥
```bash
# نزّل Firebase CLI
npm install -g firebase-tools

# سجل دخول
firebase login

# شغل Firebase في المشروع
firebase init hosting

# اختار:
# - Public directory: build/web
# - Single-page app: Yes
# - Automatic builds: No

# ارفع المشروع
firebase deploy --only hosting
```

### 3. GitHub Pages 📄
```bash
# نزّل GitHub Pages package
flutter pub add --dev flutter_gh_pages

# ارفع على GitHub Pages
flutter build web --release --base-href "/wish_listy/"
# بعدين ارفع مجلد build/web على branch gh-pages
```

### 4. Surge.sh ⚡ (الأسرع!)
```bash
# نزّل Surge
npm install -g surge

# ارفع المشروع
cd build/web
surge

# Surge هيديك لينك فوراً!
```

---

## ملاحظات مهمة:

1. **البيلد اللي موجود:**
   - البيلد جاهز في المجلد `build/web`
   - ممكن ترفعه على أي سيرفر مباشرة

2. **لو عايز تعمل بيلد جديد:**
   ```bash
   flutter build web --release
   ```

3. **لو صاحبك الـ Backend عايز يشوف APIs محتاجة:**
   - التطبيق دلوقتي بيشتغل بـ Mock Data
   - ممكن تديله اللينك يستكشف الـ UI
   - ويشوف الـ Network calls اللي المفروض تحصل

4. **لو عايز تعمل custom domain:**
   - كل الخدمات دي بتسمحلك تربط domain خاص بيك
   - بس Vercel و Netlify الأسهل في الموضوع ده

---

## الرابط اللي هيطلع:

بعد الرفع هيكون عندك لينك زي:
- Vercel: `https://wish-listy-xxxxx.vercel.app`
- Netlify: `https://wish-listy-xxxxx.netlify.app`
- Firebase: `https://wish-listy-xxxxx.web.app`
- Surge: `https://wish-listy-xxxxx.surge.sh`

**أنصحك بـ Surge لأنه أسرع وأسهل حاجة! ⚡**

---

## Quick Start (أسرع حل):

```bash
# نزّل Surge
npm install -g surge

# روح لمجلد البيلد
cd /Users/Marwa/wish_listy/build/web

# ارفع!
surge
```

**كده خلصت! 🎉**


