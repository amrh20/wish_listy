# 🌍 نظام الترجمة - Localization System

## 📋 نظرة عامة
تم إضافة دعم كامل للغتين العربية والإنجليزية في التطبيق مع نظام ترجمة متقدم ومتجاوب.

## 🚀 الميزات

### ✅ **اللغات المدعومة:**
- 🇺🇸 **الإنجليزية (English)** - اللغة الافتراضية
- 🇸🇦 **العربية (العربية)** - مع دعم RTL

### ✨ **الميزات المتقدمة:**
- 🔄 **تبديل تلقائي للغة** مع حفظ التفضيل
- 📱 **Haptic Feedback** عند تغيير اللغة
- 🎨 **أيقونة تغيير اللغة** جميلة ومتحركة
- 📍 **دعم RTL/LTR** تلقائي
- 💾 **حفظ اللغة** في التخزين المحلي
- 🎭 **تأثيرات بصرية** عند تغيير اللغة

## 🛠️ كيفية الاستخدام

### 1. **إضافة ترجمة جديدة:**

#### في ملف الترجمة العربية (`assets/translations/ar.json`):
```json
{
  "new_section": {
    "title": "العنوان الجديد",
    "description": "الوصف الجديد"
  }
}
```

#### في ملف الترجمة الإنجليزية (`assets/translations/en.json`):
```json
{
  "new_section": {
    "title": "New Title",
    "description": "New Description"
  }
}
```

### 2. **استخدام الترجمة في الكود:**

#### الطريقة البسيطة:
```dart
Text(context.tr('new_section.title'))
```

#### مع متغيرات:
```dart
Text(context.tr('validation.minLength', args: {'length': '8'}))
```

### 3. **إضافة أيقونة تغيير اللغة:**

#### الأيقونة الكاملة:
```dart
LanguageSwitcher(
  showLabel: true,
  showFlag: true,
  showNativeName: true,
  size: 40,
  onLanguageChanged: () {
    // Handle language change
  },
)
```

#### الأيقونة المدمجة:
```dart
CompactLanguageSwitcher(
  size: 32,
  backgroundColor: Colors.white.withOpacity(0.2),
)
```

### 4. **الوصول إلى خدمة الترجمة:**
```dart
final localization = LocalizationService();

// تغيير اللغة
await localization.changeLanguage('ar');

// الحصول على اللغة الحالية
String currentLang = localization.currentLanguage;

// التحقق من اتجاه النص
bool isRTL = localization.isRTL;

// تنسيق التاريخ
String formattedDate = localization.formatDate(DateTime.now());

// تنسيق العملة
String formattedCurrency = localization.formatCurrency(99.99);
```

## 📁 هيكل الملفات

```
lib/
├── services/
│   └── localization_service.dart    # خدمة الترجمة الرئيسية
├── widgets/
│   └── language_switcher.dart      # أيقونات تغيير اللغة
└── assets/
    └── translations/
        ├── ar.json                 # الترجمة العربية
        └── en.json                 # الترجمة الإنجليزية
```

## 🎯 أمثلة على الاستخدام

### **في الشاشات:**
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr('screen.title')),
          ),
          body: Column(
            children: [
              Text(context.tr('screen.welcome')),
              CustomButton(
                text: context.tr('common.save'),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### **في النماذج:**
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: context.tr('auth.email'),
    hintText: context.tr('auth.emailHint'),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return context.tr('validation.required');
    }
    return null;
  },
)
```

### **في الرسائل:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(context.tr('messages.loginSuccess')),
    backgroundColor: AppColors.success,
  ),
);
```

## 🔧 التخصيص

### **إضافة لغة جديدة:**
1. أنشئ ملف ترجمة جديد في `assets/translations/`
2. أضف اللغة في `LocalizationService.supportedLanguages`
3. أضف دعم RTL إذا لزم الأمر

### **تخصيص أيقونة تغيير اللغة:**
```dart
LanguageSwitcher(
  size: 50,
  showLabel: false,
  showFlag: true,
  showNativeName: false,
  padding: EdgeInsets.all(12),
  onLanguageChanged: () {
    // Custom logic
  },
)
```

## 📱 دعم RTL

### **تطبيق تلقائي:**
- اللغة العربية: RTL تلقائياً
- اللغة الإنجليزية: LTR تلقائياً

### **تخصيص يدوي:**
```dart
Directionality(
  textDirection: localization.textDirection,
  child: YourWidget(),
)
```

## 🎨 التصميم

### **الألوان:**
- تستخدم `AppColors` للتأكد من التناسق
- شفافية زجاجية مع حدود وظلال
- تأثيرات متحركة عند النقر

### **الحركات:**
- Scale animation عند النقر
- Rotation animation للتبديل
- Smooth transitions بين اللغات

## 🚨 استكشاف الأخطاء

### **مشاكل شائعة:**

#### 1. **الترجمة لا تظهر:**
- تأكد من استدعاء `LocalizationService().initialize()`
- تحقق من وجود `ListenableBuilder` في الشاشة
- تأكد من صحة مفتاح الترجمة

#### 2. **اللغة لا تتغير:**
- تأكد من وجود `context.tr()` في `ListenableBuilder`
- تحقق من حفظ اللغة في `SharedPreferences`

#### 3. **RTL لا يعمل:**
- تأكد من تطبيق `Directionality` في `main.dart`
- تحقق من `localization.textDirection`

## 📚 أفضل الممارسات

### ✅ **افعل:**
- استخدم مفاتيح ترجمة واضحة ومنظمة
- اجمع الترجمات المتشابهة في أقسام
- استخدم `context.tr()` بدلاً من النصوص المباشرة
- اختبر التطبيق باللغتين

### ❌ **لا تفعل:**
- لا تضع نصوص مباشرة في الكود
- لا تنس إضافة الترجمة للغتين
- لا تستخدم مفاتيح ترجمة طويلة ومعقدة
- لا تنس اختبار RTL

## 🔄 تحديث التطبيق

### **عند إضافة نصوص جديدة:**
1. أضف الترجمة في `ar.json`
2. أضف الترجمة في `en.json`
3. استخدم `context.tr()` في الكود
4. اختبر باللغتين

### **عند تغيير ترجمة موجودة:**
1. عدل النص في ملفي الترجمة
2. أعد تشغيل التطبيق
3. اختبر التغييرات

## 🌟 الميزات المستقبلية

- [ ] دعم لغات إضافية
- [ ] ترجمة ديناميكية من الخادم
- [ ] دعم الترجمة التلقائية
- [ ] حفظ تفضيلات اللغة لكل مستخدم
- [ ] دعم اللهجات المختلفة

---

## 📞 الدعم

إذا واجهت أي مشاكل أو لديك أسئلة حول نظام الترجمة، لا تتردد في التواصل معنا! 🚀✨
