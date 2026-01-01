# حل مشكلة Java Runtime على macOS

إذا ظهرت رسالة الخطأ: "Unable to locate a Java Runtime"، يمكنك حل المشكلة بإحدى الطرق التالية:

## الطريقة 1: استخدام Java الموجود في Android Studio (الأسهل)

إذا كان لديك Android Studio مثبتاً، يمكنك استخدام Java الخاص به:

```bash
# تعيين JAVA_HOME لاستخدام Java من Android Studio
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# ثم شغل الأمر
cd android
./gradlew signingReport
```

أو في سطر واحد:

```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" ./gradlew signingReport
```

## الطريقة 2: تثبيت Java باستخدام Homebrew

إذا كان لديك Homebrew مثبتاً:

```bash
# تثبيت OpenJDK
brew install openjdk@17

# إضافة Java إلى PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## الطريقة 3: تثبيت Java من Oracle

1. اذهب إلى: https://www.oracle.com/java/technologies/downloads/#java17-mac
2. حمل Java 17 أو أحدث
3. ثبت الحزمة (.dmg)
4. اتبع التعليمات

## الطريقة 4: استخدام Flutter SDK (إذا كان متوفراً)

Flutter يأتي مع Java أحياناً:

```bash
# تحقق من Java في Flutter SDK
flutter doctor -v
```

## بعد تثبيت Java:

1. افتح Terminal جديد
2. تحقق من التثبيت:
   ```bash
   java -version
   ```

3. اذهب إلى مجلد android:
   ```bash
   cd /Users/amrhamdy/Documents/Projects/wish_listy/android
   ```

4. شغل الأمر:
   ```bash
   ./gradlew signingReport
   ```

5. ابحث عن `SHA256:` في المخرجات

## نصائح إضافية:

- تأكد من فتح Terminal جديد بعد تثبيت Java
- إذا استمرت المشكلة، أضف Java إلى PATH في `~/.zshrc`:
  ```bash
  export JAVA_HOME=$(/usr/libexec/java_home)
  export PATH=$JAVA_HOME/bin:$PATH
  ```

