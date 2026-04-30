# Safira — Geliştirme Raporu & Yol Haritası

> **Tarih:** Nisan 2026 · **Sürüm:** 1.0.0 (pre-release)

---

## 📋 İçindekiler

1. [Mevcut Durum Analizi](#1-mevcut-durum-analizi)
2. [Linux'ta Geliştirme Kurulumu](#2-linuxta-geliştirme-kurulumu)
3. [Kritik Hatalar & Acil Düzeltmeler](#3-kritik-hatalar--acil-düzeltmeler)
4. [Geliştirme Yol Haritası](#4-geliştirme-yol-haritası)
5. [Güvenlik İyileştirmeleri](#5-güvenlik-i̇yileştirmeleri)
6. [Test Stratejisi](#6-test-stratejisi)
7. [Öncelik Sırası](#7-öncelik-sırası)

---

## 1. Mevcut Durum Analizi

### ✅ Tamamlanan Bileşenler

| Bileşen | Durum | Notlar |
|---------|-------|--------|
| `CryptoEngine` (AES-256-GCM) | ✅ Tam | Üretim kalitesi |
| `KeyDerivation` (Argon2id) | ✅ Tam | Isolate'de çalışıyor |
| `TotpEngine` (RFC 6238) | ✅ Tam | — |
| `PasswordGenerator` (CSPRNG) | ✅ Tam | Pronounceable mod var |
| `SessionManager` (auto-lock) | ✅ Tam | Memory zeroing var |
| `ClipboardManager` | ✅ Tam | 30s auto-clear |
| `AppRouter` (go_router) | ✅ Tam | Auth guard var |
| `AppTheme` (Material 3) | ✅ Tam | FlexColorScheme |
| `VaultEntryModel` (Isar şema) | ✅ Tam | Şifreli alan yapısı |
| Onboarding UI (4 sayfa) | ✅ Tam | — |
| Dashboard UI | ✅ Tam | Responsive layout |
| Lock Page (brute-force koruma) | ✅ Tam | Exponential backoff |
| Generator Page | ✅ Tam | — |
| TOTP Page | ✅ Tam | — |
| Health Page | ⚠️ Kısmi | SHA-1 placeholder |
| Settings Page | ✅ Tam | — |
| Secure Notes Page | ✅ Tam | — |
| Import/Export Page | ✅ Tam | — |
| Bitwarden Parser | ✅ Tam | — |
| KeePass CSV Parser | ✅ Tam | — |

### ❌ Eksik / TODO Olan Bileşenler

| Bileşen | Sorun |
|---------|-------|
| `VaultProvider` | Gerçek Isar sorguları yok — tüm methodlar placeholder |
| `AuthProvider.unlockWithPassword` | Argon2id doğrulama yok — `password.isNotEmpty` placeholder |
| `OnboardingProvider.setMasterPassword` | Isar'a yazma yok — key bundle kayboluyor |
| `HealthPage._sha1` | SHA-1 implementasyonu yok — HIBP çalışmıyor |
| `DashboardPage` | `appStateProvider` import eksik (`_AppStateX` placeholder) |
| `linux/` klasörü | CMake build dosyaları yok → `flutter run -d linux` çalışmıyor |
| `android/` klasörü | Gradle dosyaları yok → `flutter run -d android` çalışmıyor |
| `assets/` klasörü | Lottie animasyonları, ikonlar yok — başlatmada crash |
| `.g.dart` dosyaları | `build_runner` çalıştırılmadı — tüm provider'lar compile etmez |

---

## 2. Linux'ta Geliştirme Kurulumu

### 🔴 Neden `flutter run` çalışmıyor?

Üç ana neden var:

1. **`linux/` klasörü yok** — Flutter Linux app için `linux/CMakeLists.txt` ve ilgili dosyalar olmadan build yapılamaz
2. **`.g.dart` dosyaları yok** — Riverpod, Isar ve Freezed için code generation yapılmamış
3. **`assets/` klasörü yok** — `pubspec.yaml`'da tanımlı asset yolları yok → başlatmada hata

### 🟢 Adım Adım Çözüm

#### Adım 1 — Sistem paketleri (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libstdc++-12-dev \
  libsecret-1-dev \
  libjsoncpp-dev \
  libssl-dev
```

> **Arch Linux** kullanıyorsan:
> ```bash
> sudo pacman -S clang cmake ninja pkg-config gtk3 openssl jsoncpp
> ```

#### Adım 2 — Flutter kurulumu & Linux desktop aktifleştirme

```bash
# Flutter'ın doğru sürümde olduğunu kontrol et
flutter --version   # 3.19+ olmalı

# Linux desktop'u aktifleştir
flutter config --enable-linux-desktop

# Kontrol et
flutter devices     # "linux (desktop)" çıkmalı
```

#### Adım 3 — Repo'yu klonla

```bash
git clone https://github.com/lunanoir21/safira-project.git
cd safira-project
```

#### Adım 4 — Flutter projesi olarak başlat (KRITIK)

Repoda şu an sadece `lib/` kaynak kodları var. Flutter'ın beklediği platform dosyaları yok.
**Yeni bir Flutter projesi oluşturup kaynak kodları taşımak gerekiyor:**

```bash
# 1. Aynı dizine geç, geçici proje oluştur
cd ..
flutter create --platforms=linux,android --org dev.safira safira_scaffold
cd safira_scaffold

# 2. Platform dosyalarını kopyala
cp -r linux/ ../safira-project/linux/
cp -r android/ ../safira-project/android/
cp pubspec_lock_template.yaml ../safira-project/   # opsiyonel

# 3. safira-project klasörüne dön
cd ../safira-project
```

#### Adım 5 — `pubspec.yaml`'ı düzelt (assets bölümü)

`assets/` klasörü olmadığı için uygulama crash yapıyor.
Geçici olarak assets satırlarını yorum satırına al:

```yaml
# pubspec.yaml içinde şunu bul ve yoruma al:
flutter:
  uses-material-design: true
  # assets:            ← BU SATIRLARI YOR SATIRI YAP
  #   - assets/animations/
  #   - assets/icons/
  #   - assets/images/
  # fonts:
  #   - family: SafiraIcons
  #     fonts:
  #       - asset: assets/fonts/SafiraIcons.ttf
```

#### Adım 6 — Bağımlılıkları yükle

```bash
flutter pub get
```

Hata alırsan bazı paketler Linux'ta desteklenmeyebilir.
Bu paketleri geçici olarak `pubspec.yaml`'dan kaldır:

```yaml
# Linux'ta sorun çıkarabilecek paketler — geçici kaldır:
# mobile_scanner: ^5.1.0       ← kamera API'si, Linux'ta çalışmaz
# local_auth: ^2.3.0           ← biyometrik, Linux'ta sınırlı
# flutter_clipboard_manager    ← super_clipboard kullan
```

#### Adım 7 — Code generation çalıştır (ZORUNLU)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Bu komut şu dosyaları üretir:
- `lib/core/router/app_router.g.dart`
- `lib/shared/providers/app_state_provider.g.dart`
- `lib/shared/providers/session_provider.g.dart`
- `lib/shared/providers/database_provider.g.dart`
- `lib/features/auth/presentation/providers/auth_provider.g.dart`
- `lib/features/vault/presentation/providers/vault_provider.g.dart`
- `lib/features/onboarding/presentation/providers/onboarding_provider.g.dart`
- `lib/shared/models/vault_entry_model.g.dart` (Isar schema)

> **Hata alırsan:** `dart run build_runner clean` çalıştır, sonra tekrar dene.

#### Adım 8 — `DashboardPage` import hatasını düzelt

`dashboard_page.dart` dosyasının en altında bu satır var:
```dart
// KALDIR — bu placeholder:
extension _AppStateX on WidgetRef {
  dynamic get appStateProvider => throw UnimplementedError();
}
```

Dosyanın başına şu import'u ekle:
```dart
import 'package:safira/shared/providers/app_state_provider.dart';
```

#### Adım 9 — Uygulamayı çalıştır

```bash
# Linux masaüstü
flutter run -d linux

# Debug modda daha fazla log için:
flutter run -d linux --verbose
```

### 🔧 Hızlı Sorun Giderme

| Hata Mesajı | Çözüm |
|-------------|-------|
| `No Linux desktop app` | `flutter config --enable-linux-desktop` çalıştır |
| `linux/CMakeLists.txt not found` | Adım 4'ü uygula (platform dosyalarını oluştur) |
| `*.g.dart not found` | `dart run build_runner build` çalıştır |
| `Could not find asset` | `pubspec.yaml`'dan assets bölümünü yorum satırına al |
| `clang not found` | `sudo apt-get install clang cmake ninja-build libgtk-3-dev` |
| `isar_generator` hatası | `dart run build_runner clean && dart run build_runner build` |
| `mobile_scanner` build hatası | `pubspec.yaml`'dan kaldır, `flutter pub get` çalıştır |

---

## 3. Kritik Hatalar & Acil Düzeltmeler

### 🔴 P0 — Uygulama çalışmıyor

#### Sorun 1: `VaultProvider` hiç veri okumuyor
```dart
// MEVCUT (placeholder):
Future<void> _loadEntries() async {
  await Future.delayed(Duration(milliseconds: 300));
  state = const VaultLoaded(entries: []); // Boş liste!
}

// OLMASI GEREKEN:
Future<void> _loadEntries() async {
  final db = ref.read(databaseProvider);
  final rawEntries = await db.vaultEntryModels
      .where()
      .isDeletedEqualTo(false)
      .findAll();
  // Decrypt each entry...
  state = VaultLoaded(entries: decryptedEntries);
}
```

#### Sorun 2: `AuthProvider` şifreyi doğrulamıyor
```dart
// MEVCUT (placeholder):
final isCorrect = password.isNotEmpty; // HER ŞİFRE ÇALIŞIYOR!

// OLMASI GEREKEN:
final metadata = await db.vaultMetadataModels.get(1);
final isCorrect = await KeyDerivation.instance.verifyPassword(
  masterPassword: password,
  verificationHash: Uint8List.fromList(metadata.verificationHash),
  verificationSalt: Uint8List.fromList(metadata.verificationSalt),
);
```

#### Sorun 3: `OnboardingProvider` vault metadata'yı kaydetmiyor
```dart
// MEVCUT (TODO yorum satırı):
// TODO: Persist keySalt, verificationHash, verificationSalt to Isar

// OLMASI GEREKEN:
final db = ref.read(databaseProvider);
await db.writeTxn(() async {
  await db.vaultMetadataModels.put(VaultMetadataModel(
    id: 1,
    keySalt: bundle.keySalt,
    verificationHash: bundle.verificationHash,
    verificationSalt: bundle.verificationSalt,
    createdAt: DateTime.now(),
    schemaVersion: DatabaseConstants.isarSchemaVersion,
  ));
});
```

#### Sorun 4: `HealthPage` SHA-1 çalışmıyor
```dart
// MEVCUT (placeholder):
List<int> _sha1(List<int> data) {
  return List.filled(20, 0); // HER ZAMAN SIFIR!
}

// OLMASI GEREKEN (pointycastle ile):
import 'package:pointycastle/digests/sha1.dart';
List<int> _sha1(List<int> data) {
  final digest = SHA1Digest();
  return digest.process(Uint8List.fromList(data));
}
```

### 🟡 P1 — Önemli Eksikler

| # | Sorun | Etki |
|---|-------|------|
| 5 | `DatabaseProvider` Isar'ı başlatmıyor | Tüm DB işlemleri çöküyor |
| 6 | `SessionProvider` ile `AppStateProvider` bağlantısı yok | Auto-lock çalışmıyor |
| 7 | `VaultCreatePage` entry'i kaydetmiyor | Yeni şifre eklenemiyor |
| 8 | `VaultEntryPage` entry detayını gösteremiyor | Şifre görüntülenemiyor |
| 9 | `RoutePaths.splash` için route yok | Router crash yapıyor |

---

## 4. Geliştirme Yol Haritası

### 🏁 v0.1 — Çalışan MVP (Öncelik: Hemen)

**Hedef:** Linux masaüstünde temel şifre saklama/gösterme çalışsın.

- [ ] Linux platform dosyaları oluştur (`linux/CMakeLists.txt` vb.)
- [ ] `DatabaseProvider` — Isar singleton başlat
- [ ] `OnboardingProvider` — Vault metadata'yı Isar'a kaydet
- [ ] `AuthProvider` — Gerçek Argon2id doğrulama
- [ ] `VaultProvider._loadEntries()` — Gerçek Isar sorgusu + şifre çözme
- [ ] `VaultCreatePage` — Entry'i şifrele + Isar'a yaz
- [ ] `VaultEntryPage` — Entry'i oku + şifresini çöz + göster
- [ ] `HealthPage._sha1` — pointycastle ile gerçek SHA-1
- [ ] `SessionProvider` ↔ `AppStateProvider` bağlantısı
- [ ] Splash route ekle veya `RoutePaths.splash`'ı kaldır
- [ ] Assets klasörünü oluştur (boş animasyon placeholder'ları)

**Tahmini süre:** 2-3 gün

---

### 🚀 v0.2 — Vault Yönetimi

**Hedef:** Tam CRUD, arama, kategori filtresi çalışsın.

- [ ] Vault entry düzenleme (`VaultEditPage`)
- [ ] Soft delete + trash (çöp kutusu sayfası)
- [ ] Fuzzy search (fuzzywuzzy paketi entegrasyonu)
- [ ] Kategori filtresi (Isar index kullanarak)
- [ ] Favori listesi
- [ ] Sürükle-bırak ile sıralama
- [ ] Bulk seçim (çoklu silme)
- [ ] Entry geçmişi (şifre değişiklik tarihleri)

**Tahmini süre:** 1 hafta

---

### 🔐 v0.3 — Güvenlik & Auth Tamamlama

**Hedef:** Güvenlik katmanları production-ready olsun.

- [ ] Linux Keyring entegrasyonu (`flutter_secure_storage` Linux backend)
- [ ] Biometrik unlock (Linux'ta PAM veya GNOME Keyring)
- [ ] `SessionManager` ↔ `WidgetsBindingObserver` bağlantısı (arka plana geçince kilitle)
- [ ] Brute-force: kalıcı lockout (uygulama kapansa bile sayaç devam etsin)
- [ ] Master password değiştirme (re-encrypt all entries)
- [ ] Acil erişim silme (birden fazla yanlış → vault sil)
- [ ] Anti-screenshot (Linux pencere flag'i)

**Tahmini süre:** 1 hafta

---

### 📊 v0.4 — Password Health

**Hedef:** HIBP entegrasyonu tam çalışsın.

- [ ] Gerçek SHA-1 (pointycastle)
- [ ] HIBP k-anonymity API çağrısı (gerçek vault entries üzerinde)
- [ ] Şifre gücü analizi (Shannon entropy)
- [ ] Tekrarlanan şifre tespiti (hash karşılaştırma)
- [ ] Eski şifre tespiti (`updatedAt` field kontrolü)
- [ ] Issue card'larından affected entries'e geçiş
- [ ] Scan önbelleği (her açılışta API çağırma)
- [ ] Offline mod (HIBP erişilemezse ne olur?)

**Tahmini süre:** 3-4 gün

---

### 📲 v0.5 — TOTP & Import/Export

**Hedef:** TOTP vault entrylerinden okusun, import gerçekten çalışsın.

- [ ] TOTP entries → vault'tan OTP secret oku
- [ ] QR kod tarama (Linux'ta webcam veya ekran görüntüsü)
- [ ] TOTP entry ekleme/silme → vault'a yaz
- [ ] Bitwarden import → gerçekten VaultEntryModel'e çevir
- [ ] KeePass CSV import → gerçekten VaultEntryModel'e çevir
- [ ] Şifreli `.safira` export format (AES-256-GCM)
- [ ] Şifreli `.safira` import (şifre ile açma)
- [ ] CSV export (uyarı göstererek)

**Tahmini süre:** 1 hafta

---

### 📝 v0.6 — Secure Notes

**Hedef:** Not içerikleri gerçekten şifreli kaydedilsin.

- [ ] `SecureNoteModel` Isar şeması oluştur
- [ ] Not oluşturma → şifrele → Isar'a kaydet
- [ ] Not okuma → Isar'dan oku → şifre çöz
- [ ] Not silme (soft + hard delete)
- [ ] Markdown önizleme modu
- [ ] Not kategorileri (tag sistemi)
- [ ] Not arama (sadece başlık — içerik şifreli)

**Tahmini süre:** 3-4 gün

---

### ⚙️ v0.7 — Settings & UX İyileştirmeleri

**Hedef:** Settings sayfasındaki tüm butonlar gerçekten çalışsın.

- [ ] Biometric toggle → gerçekten aktifleştir/devre dışı bırak
- [ ] Auto-lock slider → `SessionManager.updateTimeout()` bağla
- [ ] Clipboard clear slider → `ClipboardManager`'a bağla
- [ ] Theme mode değişikliği → kalıcı kaydet (Isar `AppSettingsModel`)
- [ ] Master password değiştirme (modal flow)
- [ ] Vault wipe (gerçek Isar.deleteDatabase() çağrısı)
- [ ] Backup/restore settings
- [ ] "About" sayfası (lisanslar, changelog)
- [ ] Linux tray icon (system tray'e minimize)

**Tahmini süre:** 3-4 gün

---

### 🌍 v0.8 — i18n & Erişilebilirlik

- [ ] `flutter_localizations` + `intl` entegrasyonu
- [ ] Türkçe dil desteği
- [ ] İngilizce (varsayılan)
- [ ] Semantics labels (ekran okuyucu desteği)
- [ ] Yüksek kontrast tema
- [ ] Büyük font boyutu desteği
- [ ] Klavye navigasyonu (Tab order)

**Tahmini süre:** 1 hafta

---

### 📱 v0.9 — Android

- [ ] Android minimum API 23 kontrolü
- [ ] Android Keystore ile biyometrik
- [ ] Uygulama arka plana geçince ekranı gizle
- [ ] Android autofill service (`AutofillService` implement)
- [ ] Material You dinamik renk
- [ ] Deep link desteği (otpauth:// URI)
- [ ] Google Play Store hazırlığı (signing, metadata)

**Tahmini süre:** 1-2 hafta

---

### 🏆 v1.0 — Stable Release

- [ ] Tüm P0 ve P1 hatalar düzeltildi
- [ ] %80+ test coverage
- [ ] Güvenlik audit (bağımsız inceleme)
- [ ] F-Droid başvurusu
- [ ] GitHub Releases (APK + Linux binary)
- [ ] Changelog yazıldı
- [ ] README güncellendi

---

## 5. Güvenlik İyileştirmeleri

### Kısa Vadeli (v0.1-v0.3)

| Öncelik | Başlık | Açıklama |
|---------|--------|----------|
| 🔴 | Vault metadata persistansı | Şu an onboarding'de key kayboluyor |
| 🔴 | Gerçek şifre doğrulama | Auth provider placeholder kullanıyor |
| 🟡 | Linux Keyring | Session key için güvenli depolama |
| 🟡 | Anti-screenshot | Pencere içeriğini ekran görüntüsünden koru |
| 🟡 | Memory pinning | mlock() ile key sayfalarını RAM'de tut |

### Orta Vadeli (v0.4-v0.7)

| Öncelik | Başlık | Açıklama |
|---------|--------|----------|
| 🟡 | Entry title şifreleme | Şu an başlıklar plaintext — arama vs. gizlilik trade-off |
| 🟡 | Trafik şifreleme | HIBP API'ye TLS certificate pinning |
| 🟠 | Audit log | Kim ne zaman erişti? (yerel log) |
| 🟠 | Side-channel testler | Argon2id timing ölçümleri |

### Uzun Vadeli (v1.0+)

| Öncelik | Başlık | Açıklama |
|---------|--------|----------|
| 🟠 | Formal security audit | Bağımsız güvenlik firması |
| 🟠 | Reproducible builds | Deterministic APK build |
| 🟠 | Canary release | Beta kullanıcılarla test |

---

## 6. Test Stratejisi

### Mevcut Durum

| Test Tipi | Mevcut | Hedef |
|-----------|--------|-------|
| Unit (güvenlik) | 4 dosya (placeholder) | 20+ dosya |
| Unit (UI provider) | 1 dosya | 10+ dosya |
| Widget test | 0 | 15+ |
| Integration test | 1 (iskelet) | 5+ flow |
| Golden test | 0 | 10+ |

### Öncelikli Testler

1. **`AuthProvider`** — yanlış şifre lockout, brute force sayacı
2. **`VaultProvider`** — CRUD işlemleri Isar mock ile
3. **`CryptoEngine`** — round-trip encrypt/decrypt (gerçek uygulama)
4. **`KeyDerivation`** — aynı salt + şifre = aynı key
5. **Onboarding flow** — baştan sona integration test
6. **Lock/unlock flow** — 5 yanlış şifre → lockout

---

## 7. Öncelik Sırası

### Bu Hafta Yapılacaklar (v0.1 MVP)

```
1. Linux platform dosyalarını oluştur
   → flutter create --platforms=linux . (mevcut dizinde)
   
2. build_runner çalıştır
   → dart run build_runner build --delete-conflicting-outputs
   
3. DatabaseProvider'ı implement et
   → Isar.open() + schema kayıt
   
4. OnboardingProvider → Isar'a yaz
   → VaultMetadataModel persist
   
5. AuthProvider → gerçek Argon2id verify
   → KeyDerivation.verifyPassword() çağır
   
6. VaultProvider → Isar okuma + şifre çözme
   → CryptoEngine.decrypt() + VaultEntryModel
   
7. VaultCreatePage → Isar'a şifreli yaz
   → CryptoEngine.encrypt() + Isar.put()
   
8. flutter run -d linux → çalışıyor!
```

### Bu Ay Yapılacaklar (v0.2-v0.3)

- Tam CRUD (edit, delete, restore)
- HIBP gerçek entegrasyon
- Session ↔ AppState bağlantısı
- Linux Keyring desteği
- %50 test coverage

### Sonraki Ay (v0.4-v0.6)

- TOTP vault entegrasyonu
- Import/Export gerçek implementasyon
- Secure Notes Isar backend
- Android build + test

---

*Bu rapor otomatik olarak Nisan 2026'da oluşturulmuştur.*
*Proje: https://github.com/lunanoir21/safira-project*
