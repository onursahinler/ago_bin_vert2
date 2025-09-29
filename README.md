# 🗑️ AGO BinVert - Akıllı Çöp Kutusu Yönetim Sistemi

**AGO BinVert**, çöp kutularının doluluk oranını gerçek zamanlı olarak takip eden ve yöneten akıllı bir Flutter uygulamasıdır. Bluetooth sensörleri ile entegre çalışarak çevre dostu ve verimli atık yönetimi sağlar.

## ✨ Özellikler

### 🔗 Bluetooth Entegrasyonu
- **HC-05 Bluetooth modülü** ile gerçek zamanlı veri alımı
- Otomatik yeniden bağlanma sistemi
- Önceki cihazlara otomatik bağlanma
- Bağlantı durumu takibi ve loglama

### 📊 Çöp Kutusu Yönetimi
- **Gerçek zamanlı doluluk oranı** takibi
- Renk kodlu durum göstergeleri (Yeşil: <50%, Sarı: 50-80%, Kırmızı: >80%)
- Çöp kutusu detay sayfaları
- Son güncelleme zamanları

### 🗺️ Harita Görünümü
- **Google Maps** entegrasyonu
- Çöp kutusu konumlarını harita üzerinde görüntüleme
- Bluetooth sensörlü kutuları özel işaretleyicilerle gösterme
- Normal ve uydu harita görünümü

### 🔔 Akıllı Bildirim Sistemi
- **Firebase Cloud Messaging** ile push bildirimleri
- Doluluk oranına göre otomatik uyarılar:
  - %85+ : "Neredeyse Dolu" (Kırmızı)
  - %55+ : "%50 Dolu" (Sarı) 
  - %10- : "Boşaltıldı" (Yeşil)
- Bildirim geçmişi ve okunma durumu
- Kullanıcı tercihlerine göre bildirim ayarları

### 👤 Kullanıcı Yönetimi
- **Firebase Authentication** ile güvenli giriş
- Kullanıcı kayıt ve profil yönetimi
- Kullanıcı tercihlerini kaydetme
- Çoklu dil desteği hazırlığı

### 📱 Modern UI/UX
- Material Design prensiplerine uygun arayüz
- Responsive tasarım
- Özel drawer menü
- Profil sayfası ve ayarlar

## 🛠️ Teknolojiler

- **Flutter** 3.5.4+
- **Firebase** (Authentication, Firestore, Cloud Messaging, Storage)
- **Google Maps** Flutter plugin
- **Bluetooth Serial BLE** ile donanım entegrasyonu
- **Provider** state management
- **Shared Preferences** yerel veri saklama
- **Local Notifications** yerel bildirimler

## 📦 Kurulum

### Gereksinimler
- Flutter SDK 3.5.4 veya üzeri
- Android Studio / VS Code
- Android cihaz veya emülatör (Bluetooth test için fiziksel cihaz önerilir)

### Adımlar

1. **Projeyi klonlayın:**
```bash
git clone https://github.com/your-username/ago_bin_vert2.git
cd ago_bin_vert2
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Firebase yapılandırması:**
   - Firebase Console'da yeni proje oluşturun
   - `google-services.json` dosyasını `android/app/` klasörüne ekleyin
   - `ios/Runner/GoogleService-Info.plist` dosyasını iOS için ekleyin

4. **Uygulamayı çalıştırın:**
```bash
flutter run
```

## 🔧 Bluetooth Sensör Kurulumu

### HC-05 Modülü Yapılandırması
1. HC-05 modülünü Arduino'ya bağlayın
2. Sensör verilerini "Fill: XX.X%" formatında gönderecek şekilde programlayın
3. Bluetooth modülünü cihazınızla eşleştirin
4. Uygulamada "Bluetooth Logs" sayfasından cihazı seçin

### Veri Formatı
```
Fill: 45.5%
```

## 📱 Kullanım

### İlk Kurulum
1. Uygulamayı açın ve Firebase ile giriş yapın
2. Bluetooth izinlerini verin
3. HC-05 sensörünü eşleştirin
4. Bildirim izinlerini etkinleştirin

### Çöp Kutusu Takibi
- Ana sayfada tüm çöp kutularını görüntüleyin
- Renk kodları ile doluluk durumunu takip edin
- Detay sayfasında daha fazla bilgi alın
- Harita görünümünde konumları inceleyin

### Bildirim Yönetimi
- Ayarlar sayfasından bildirimleri açın/kapatın
- Bildirimler sayfasından geçmişi görüntüleyin
- Doluluk eşiklerini takip edin

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                          # Ana uygulama dosyası
├── services/                          # Servis katmanı
│   ├── auth_service.dart             # Firebase Authentication
│   ├── bluetooth_service.dart        # Bluetooth yönetimi
│   ├── notification_service.dart     # Bildirim sistemi
│   ├── storage_service.dart          # Yerel veri saklama
│   └── log_service.dart              # Loglama sistemi
├── widgets/                          # Özel widget'lar
│   ├── bluetooth_status_widget.dart
│   ├── bluetooth_troubleshooting_widget.dart
│   └── previous_devices_widget.dart
└── [sayfa_dosyalari].dart            # UI sayfaları
```
