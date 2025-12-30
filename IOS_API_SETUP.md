# ✅ تم ضبط إعدادات API للـ iPhone

## 🎉 التعديلات المطبقة:

تم تعديل ملفين:

1. **`lib/core/services/api_service.dart`**
   - تغيير iOS من `localhost` إلى `192.168.1.11` (IP الـ Mac)

2. **`lib/core/services/socket_service.dart`**
   - تغيير iOS من `localhost` إلى `192.168.1.11` (IP الـ Mac)

---

## ⚠️ متطلبات مهمة:

### 1️⃣ تأكد أن Backend يستمع على `0.0.0.0` وليس `localhost` فقط:

في الـ backend (Node.js/Express مثلاً):

```javascript
// ❌ خطأ - لا يعمل مع iPhone
app.listen(4000, 'localhost', () => {
  console.log('Server running on localhost:4000');
});

// ✅ صحيح - يعمل مع iPhone وكل الأجهزة
app.listen(4000, '0.0.0.0', () => {
  console.log('Server running on 0.0.0.0:4000');
});

// أو بس بدون تحديد host:
app.listen(4000, () => {
  console.log('Server running on port 4000');
});
```

### 2️⃣ تأكد أن Mac و iPhone على نفس WiFi network

### 3️⃣ تأكد أن Firewall على Mac يسمح بالاتصالات على port 4000

**System Preferences → Security & Privacy → Firewall → Firewall Options**

---

## 🚀 الآن:

1. **أعد تشغيل التطبيق على iPhone:**
   ```bash
   flutter run -d 00008030-001D18AA14DB802E
   ```
   
   أو من Xcode اضغط **▶️**

2. **التطبيق الآن سيستخدم:** `http://192.168.1.11:4000/api`

---

## 📝 ملاحظة:

لو IP الـ Mac اتغير، غير الـ IP في:
- `lib/core/services/api_service.dart` (السطر 74)
- `lib/core/services/socket_service.dart` (السطر 30)

**للعثور على IP الجديد:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

---

**جرب الآن! 🎯**

