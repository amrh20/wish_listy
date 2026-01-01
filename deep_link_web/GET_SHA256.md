# استخراج SHA-256 Fingerprint للتطبيق Android

لإكمال إعداد Deep Links على Android، تحتاج إلى استخراج SHA-256 fingerprint من التطبيق ووضعه في ملف `assetlinks.json`.

## الطريقة 1: استخدام Gradle (موصى بها)

افتح Terminal في مجلد المشروع وقم بتشغيل:

```bash
cd android
./gradlew signingReport
```

ابحث في المخرجات عن:
- `SHA256:` أو `SHA-256:`
- سترى قيمة مثل: `AA:BB:CC:DD:EE:FF:...`

**ملاحظة مهمة:** استخدم SHA-256 fingerprint الخاص بـ **debug keystore** للتطوير، أو **release keystore** للإنتاج.

## الطريقة 2: استخدام keytool مباشرة (لـ Debug Keystore)

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

ابحث عن `SHA256:` في المخرجات.

## الطريقة 3: للحصول على Release Keystore SHA-256

إذا كان لديك release keystore:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your_alias_name
```

ستحتاج إلى إدخال كلمة مرور keystore.

## بعد الحصول على SHA-256:

1. افتح ملف `deep_link_web/.well-known/assetlinks.json`
2. استبدل `REPLACE_WITH_YOUR_SHA256_KEY` بقيمة SHA-256 (بدون مسافات أو فواصل)
3. على سبيل المثال، إذا كانت القيمة: `AA:BB:CC:DD:EE:FF:...`
4. ضعها في المصفوفة: `["AA:BB:CC:DD:EE:FF:..."]`

## مثال:

```json
{
  "sha256_cert_fingerprints": [
    "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99"
  ]
}
```

**ملاحظة:** تأكد من إزالة جميع المسافات وترك الصيغة بالضبط كما هي مع الفواصل `:`.

