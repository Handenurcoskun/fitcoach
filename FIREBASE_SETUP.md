# Firebase Kurulum Adımları

## 1. Firebase Projesi Oluştur
1. [firebase.google.com](https://firebase.google.com) → **Console'a Git**
2. **Proje Ekle** → "fitcoach" adını ver → Devam et
3. Google Analytics'i etkinleştir (opsiyonel) → Proje oluştur

## 2. Android Uygulaması Ekle
1. Firebase Console'da proje açık → Android simgesine tıkla
2. Android paket adı: `com.fitcoach.fitcoach`
3. Uygulama kaydet
4. `google-services.json` dosyasını indir
5. İndirilen dosyayı `android/app/` klasörüne koy

## 3. Firebase Servislerini Etkinleştir
Firebase Console'da:
- **Authentication** → Oturum açma yöntemleri → **E-posta/Şifre** → Etkinleştir
- **Firestore Database** → Veritabanı oluştur → **Test modunda başla** → Konum seç (eur3 öneririz)

## 4. Firestore Güvenlik Kuralları
Firestore → Kurallar sekmesine git ve şu kuralları yapıştır:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null;
    }
    match /tasks/{taskId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'trainer';
    }
    match /task_completions/{completionId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

## 5. firebase_options.dart Güncelle
`lib/firebase_options.dart` dosyasını aç ve Firebase Console'daki değerleri gir.

**YA DA** FlutterFire CLI kullanarak otomatik üret:
```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_PROJECT_ID
```

## 6. Uygulamayı Çalıştır
```bash
flutter pub get
flutter run
```
