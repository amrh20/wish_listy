# Wish Listy – Android production release (Google Play)

---

## ملخص بعد الإعداد (أين الملفات؟)

| الملف | المسار | ملاحظة |
|-------|--------|--------|
| **ملف الـ AAB للرفع على Google Play** | `build/app/outputs/bundle/release/app-release.aab` | بعد تشغيل `flutter build appbundle` |
| **الكيس ستور (احفظه نسخة آمنة)** | `android/upload-keystore.jks` | ضروري لتحديث التطبيق لاحقًا |
| **الباسوردات (key.properties)** | `android/key.properties` | فيه نفس باسورد الكيس ستور – احفظه ولا ترفعه على GitHub |

**ملف `key.properties` والكيس ستور مضافين في `.gitignore`** (في `android/.gitignore` و`.gitignore` الرئيسي) عشان الباسوردات ما تترفعش على GitHub بالغلط.

لو الـ build ما اكتملش من الـ IDE، شغّل من التيرمنال:
```bash
flutter build appbundle
```

---

## 1. Generate upload keystore

From the project root, create the keystore **once** and store it safely (e.g. `android/upload-keystore.jks`). Use a strong password and keep backups.

```bash
keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You will be prompted for:
- Keystore password (and confirmation)
- Key password (can be same as keystore)
- Name, organization, etc.

**Important:** Back up `upload-keystore.jks` and the passwords. Without them you cannot update the app on Play Store.

---

## 2. Configure `key.properties`

The file **android/key.properties** is already created. Edit it and replace the placeholders with your real values:

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../upload-keystore.jks
```

- `storeFile=../upload-keystore.jks` assumes the keystore is in the **android/** folder. If you put it elsewhere, set the path relative to **android/app/** (e.g. `../../upload-keystore.jks` if it’s in the project root).
- `key.properties` and `*.jks` are in `.gitignore` – do not commit them.

---

## 3. Build configuration

**android/app/build.gradle.kts** is already set up to:

- Read `android/key.properties` when present.
- Use the `release` signing config for release builds.
- Fall back to debug signing if `key.properties` is missing (so `flutter run --release` still works).

No further changes needed for signing.

---

## 4. Firebase & Phone Auth – SHA-1 and SHA-256

Phone Auth (and other Firebase features) need the **release** key fingerprints in Firebase Console.

Get SHA-1 and SHA-256 from your **upload** keystore:

```bash
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```

Enter the keystore password. In the output, copy:

- **SHA1:** …  
- **SHA-256:** …

Then:

1. Open [Firebase Console](https://console.firebase.google.com/) → your project.
2. Project settings (gear) → **Your apps** → select the Android app.
3. Add (or edit) the Android app and paste **SHA-1** and **SHA-256**.
4. Download the updated **google-services.json** and replace **android/app/google-services.json**.

---

## 5. Build the App Bundle (.aab)

From the project root:

```bash
flutter build appbundle
```

Output:

- **build/app/outputs/bundle/release/app-release.aab**

Upload this file to [Google Play Console](https://play.google.com/console) when creating or updating the release.

---

## Quick checklist

- [ ] Keystore created and backed up.
- [ ] **android/key.properties** updated with real passwords and correct `storeFile`.
- [ ] SHA-1 and SHA-256 from upload keystore added in Firebase Console.
- [ ] **android/app/google-services.json** updated if Firebase gave a new one.
- [ ] `flutter build appbundle` runs successfully.
- [ ] **app-release.aab** uploaded to Play Console.
