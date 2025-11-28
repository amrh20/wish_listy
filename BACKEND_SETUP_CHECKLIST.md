# ✅ Backend Setup Checklist - للتحقق من إعدادات الـ Backend

## 📋 الخطوات المهمة للتأكد أن كل حاجة شغالة

### 1. ✅ تأكد أن Backend يستمع على `0.0.0.0` وليس `localhost` فقط

**المشكلة**: إذا كان Backend مستمع على `localhost` أو `127.0.0.1` فقط، الأجهزة التانية مش هتقدر توصله.

**الحل**: في ملف `server.js` في الـ backend، تأكد أن الكود كالتالي:

```javascript
// ❌ خطأ - فقط localhost يستطيع الوصول
app.listen(4000, 'localhost', () => {
  console.log('Server running on localhost:4000');
});

// ✅ صح - كل الأجهزة على الشبكة تستطيع الوصول
app.listen(4000, '0.0.0.0', () => {
  console.log('Server running on http://0.0.0.0:4000');
});

// ✅ أو ببساطة بدون تحديد host (Node.js بيستخدم 0.0.0.0 افتراضياً)
app.listen(4000, () => {
  console.log('Server running on port 4000');
});
```

**كيف تتحقق:**
1. افتح ملف `server.js` في الـ backend
2. ابحث عن `app.listen` أو `server.listen`
3. تأكد أنه يستخدم `'0.0.0.0'` أو بدون تحديد host

---

### 2. ✅ تأكد من CORS Configuration

**المشكلة**: إذا CORS مش مفعّل، الـ browser/Flutter app مش هتقدر يبعت requests للـ backend.

**الحل**: في ملف backend (عادة `server.js` أو `app.js`)، تأكد من وجود:

```javascript
const cors = require('cors');

// للـ development - يسمح بكل الأصول
app.use(cors({
  origin: '*', // أو ['http://192.168.1.3:4000', 'http://localhost:4000']
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));
```

**أو إذا كنت تستخدم Express:**

```javascript
const express = require('express');
const cors = require('cors');
const app = express();

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  credentials: true,
}));
```

---

### 3. ✅ تأكد من IP Address في Flutter App

**الحالة الحالية:**
- ✅ IP Address المكتشف: `192.168.1.3`
- ✅ الكود بيستخدمه في `api_service.dart`

**كيف تتحقق:**
1. افتح `lib/core/services/api_service.dart`
2. ابحث عن السطر:
   ```dart
   return 'http://192.168.1.3:4000/api'; // Physical device
   ```
3. تأكد أن الـ IP صحيح (هو `192.168.1.3` ✅)

---

### 4. ✅ تأكد أن كلاهما على نفس الشبكة

**المطلوب:**
- ✅ الكمبيوتر متصل بـ WiFi
- ✅ Samsung device متصل بنفس الـ WiFi
- ✅ الاثنين على نفس الشبكة المحلية

**كيف تتحقق:**
1. افتح Settings على Samsung
2. WiFi → تأكد من اسم الشبكة
3. على الكمبيوتر → تأكد من نفس اسم الشبكة

---

### 5. ✅ اختبر Backend من الكمبيوتر

افتح terminal على الكمبيوتر وجرب:

```bash
# اختبر أن Backend شغال
curl http://localhost:4000/api/auth/register

# أو اختبر الـ IP المباشر
curl http://192.168.1.3:4000/api/auth/register
```

إذا عمل، معناه Backend شغال ✅

---

### 6. ✅ اختبر Backend من Postman/Insomnia

افتح Postman وجرب:

```http
POST http://192.168.1.3:4000/api/auth/register
Content-Type: application/json

{
  "username": "01010161601",
  "fullName": "amr hamdy",
  "password": "123456"
}
```

إذا عمل من Postman وفشل من Flutter، المشكلة في Flutter app configuration.
إذا فشل من Postman أيضاً، المشكلة في Backend configuration.

---

### 7. ✅ راقب Backend Logs

عندما تبعت request من Flutter app:

1. راقب الـ terminal اللي شغال فيه Backend
2. يجب أن تشوف:
   - Request received ✅
   - Request details (method, path, body)
   - Response sent ✅

**إذا لم ترى أي شيء:**
- المشكلة في الاتصال (Connection refused)
- تحقق من IP address
- تحقق من Firewall

**إذا رأيت Request لكن رجع 403:**
- المشكلة في CORS أو Authorization
- تحقق من CORS settings
- تحقق من Backend logs للتفاصيل

---

## 🔧 حلول سريعة للمشاكل الشائعة

### مشكلة: Connection Refused

**الأسباب:**
1. Backend مش شغال
2. Backend مستمع على `localhost` فقط
3. IP address غلط
4. Firewall يمنع الاتصال

**الحل:**
1. تأكد Backend شغال
2. غير `app.listen` لـ `0.0.0.0`
3. تحقق من IP address
4. افتح Firewall للـ port 4000

---

### مشكلة: 403 Forbidden

**الأسباب:**
1. CORS مش مفعّل
2. Backend validation فشل
3. Missing headers

**الحل:**
1. فعّل CORS في Backend
2. افحص Backend logs للتفاصيل
3. تأكد من Request format صحيح

---

### مشكلة: 404 Not Found

**الأسباب:**
1. URL غلط
2. Route مش موجود في Backend

**الحل:**
1. تأكد الـ endpoint موجود في Backend
2. تأكد الـ path صحيح (`/api/auth/register`)

---

## 📝 Checklist سريع

قبل ما تجرب من Flutter app، تأكد من:

- [ ] Backend شغال (`npm run dev`)
- [ ] Backend مستمع على `0.0.0.0` (مش `localhost` فقط)
- [ ] CORS مفعّل في Backend
- [ ] IP address في Flutter app صحيح (`192.168.1.3`)
- [ ] الكمبيوتر و Samsung على نفس WiFi
- [ ] Backend يستجيب من Postman/curl
- [ ] Firewall لا يمنع port 4000

---

## 🚀 الخطوات التالية

1. **تحقق من Backend configuration** - شوف `server.js` وتأكد من `app.listen(4000, '0.0.0.0')`
2. **تحقق من CORS** - تأكد CORS مفعّل
3. **اختبر من Postman** - تأكد Backend شغال
4. **جرب من Flutter** - راقب Logs في Flutter console و Backend terminal

---

**آخر تحديث**: Current session
