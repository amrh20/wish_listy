# API Debugging Guide - حل مشاكل الاتصال بالـ Backend

## المشكلة الشائعة: Connection Refused

عندما تحصل على خطأ `Connection refused` أو `Connection errored`، هذا يعني أن التطبيق لا يستطيع الوصول إلى الـ backend server.

## الحلول حسب نوع الجهاز

### 1. Android Emulator (محاكي Android)

✅ **الحل**: استخدم `10.0.2.2` بدلاً من `localhost`

الكود محدث تلقائياً في `api_service.dart` لاستخدام `10.0.2.2` للـ Android Emulator.

**التحقق**:
```bash
# في terminal، تأكد أن backend يعمل
curl http://localhost:4000/api/auth/register
```

### 2. Android Physical Device (جهاز Android حقيقي)

❌ **المشكلة**: `localhost` و `10.0.2.2` لا يعملان على الأجهزة الحقيقية

✅ **الحل**: استخدم IP address الفعلي لجهاز الكمبيوتر

#### خطوات الحل:

1. **اكتشف IP address لجهازك**:

   **على macOS/Linux**:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
   أو
   ```bash
   ipconfig getifaddr en0
   ```

   **على Windows**:
   ```bash
   ipconfig
   ```
   ابحث عن `IPv4 Address` (مثلاً: `192.168.1.100`)

2. **تأكد أن Backend يعمل على IP address هذا**:
   ```bash
   # تأكد أن backend يستمع على 0.0.0.0 وليس localhost فقط
   # في ملف backend، استخدم:
   app.listen(4000, '0.0.0.0', () => {
     console.log('Server running on http://0.0.0.0:4000');
   });
   ```

3. **حدث Base URL في الكود**:

   في `lib/core/services/api_service.dart`، ابحث عن:
   ```dart
   } else if (Platform.isAndroid) {
     return 'http://10.0.2.2:4000/api';
   ```
   
   واستبدله بـ:
   ```dart
   } else if (Platform.isAndroid) {
     // Replace with your computer's IP address
     return 'http://192.168.1.100:4000/api'; // استبدل 192.168.1.100 بـ IP جهازك
   ```

4. **تأكد أن الجهاز والكمبيوتر على نفس الشبكة**:
   - كلاهما متصل بنفس WiFi
   - لا يوجد firewall يمنع الاتصال

### 3. iOS Simulator

✅ **يعمل مباشرة**: `localhost` يعمل بشكل صحيح

### 4. Web

✅ **يعمل مباشرة**: `localhost` يعمل بشكل صحيح

---

## طرق Debugging

### 1. تحقق من Logs في Flutter

الكود يطبع Base URL في debug mode. ابحث في console عن:
```
🔗 API Base URL: http://10.0.2.2:4000/api
📱 Platform: Android
```

### 2. تحقق من Request Details

في debug mode، Dio يطبع تفاصيل كل request:
- URL الكامل
- Headers
- Request Body
- Response

### 3. اختبر Backend مباشرة

```bash
# من terminal على الكمبيوتر
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "username": "test@example.com",
    "password": "123456"
  }'
```

### 4. اختبر من Android Device

إذا كان لديك IP address (مثلاً `192.168.1.100`):
```bash
# من terminal على الكمبيوتر
curl -X POST http://192.168.1.100:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "fullName": "Test User",
    "username": "test@example.com",
    "password": "123456"
  }'
```

---

## حلول سريعة

### للـ Android Physical Device:

**Option 1: استخدام IP address (موصى به)**
```dart
// في api_service.dart
} else if (Platform.isAndroid) {
  return 'http://YOUR_COMPUTER_IP:4000/api';
}
```

**Option 2: استخدام ngrok (للاختبار السريع)**
```bash
# على الكمبيوتر
ngrok http 4000
# استخدم الـ URL الذي يعطيه ngrok
```

**Option 3: استخدام adb port forwarding**
```bash
adb reverse tcp:4000 tcp:4000
# ثم استخدم localhost في الكود
```

---

## خطأ 403 (Forbidden) - الحل

### الأسباب المحتملة:

1. **CORS Issues** - Backend لا يسمح بـ requests من origin هذا
2. **Backend Configuration** - Backend يحتاج headers معينة
3. **Validation Failed** - Backend رفض البيانات (لكن رجع 403 بدلاً من 400)
4. **Missing Headers** - Backend يتطلب headers إضافية

### الحلول:

#### 1. تحقق من CORS في Backend
في ملف backend (Node.js/Express):
```javascript
// Allow requests from Flutter app
const cors = require('cors');
app.use(cors({
  origin: '*', // أو ['http://192.168.1.3:4000']
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
```

#### 2. تحقق من Request Format
من logs، تأكد أن الـ request body صحيح:
```json
{
  "username": "01010161601",
  "fullName": "amr hamdy", 
  "password": "123456"
}
```

#### 3. تحقق من Response من Backend
افتح backend logs وابحث عن:
- ما هو السبب الحقيقي للخطأ؟
- هل هناك validation errors؟
- هل هناك missing headers؟

#### 4. اختبر الـ API مباشرة
من terminal على الكمبيوتر:
```bash
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "01010161601",
    "fullName": "amr hamdy",
    "password": "123456"
  }'
```

### Debugging Steps:

1. **افحص Flutter Console** - الآن سترى:
   - URL الكامل
   - Request Data
   - Response Data
   - Response Headers

2. **افحص Backend Logs** - ما هو السبب الحقيقي؟

3. **اختبر من Postman/curl** - هل يعمل من هناك؟

## Checklist للـ Debugging

- [ ] Backend يعمل على port 4000؟
- [ ] Backend يستمع على `0.0.0.0` وليس `localhost` فقط؟
- [ ] IP address صحيح في الكود؟
- [ ] الجهاز والكمبيوتر على نفس WiFi？
- [ ] Firewall لا يمنع الاتصال؟
- [ ] CORS configured في Backend؟
- [ ] Request format صحيح (username, fullName, password)؟
- [ ] تحققت من logs في Flutter console؟
- [ ] اختبرت API من Postman/curl؟

---

## أمثلة على IP Addresses الشائعة

- `192.168.1.x` - شبكة منزلية عادية
- `192.168.0.x` - شبكة منزلية أخرى
- `10.0.2.2` - Android Emulator فقط
- `127.0.0.1` أو `localhost` - نفس الجهاز فقط

---

## ملاحظات مهمة

1. **Android Emulator**: استخدم `10.0.2.2` دائماً
2. **Android Physical Device**: استخدم IP address الفعلي
3. **Backend يجب أن يستمع على `0.0.0.0`** وليس `127.0.0.1` فقط
4. **تأكد من Firewall**: قد يحتاج port 4000 أن يكون مفتوحاً

---

**آخر تحديث**: Current session

