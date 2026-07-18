# Panevo

**🇬🇧 [English](README.md)** | 🇹🇷 Türkçe

**macOS için modern, yerel pencere yöneticisi.**

Panevo, pencerelerinizi klavye kısayolları, menü çubuğu veya kenara sürükleyerek saniyeler içinde düzenlemenizi sağlayan hafif bir menü çubuğu uygulamasıdır. Swift + SwiftUI + AppKit ile tamamen yerel geliştirilmiştir — sıfır harici bağımlılık.

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Sürüm](https://img.shields.io/badge/s%C3%BCr%C3%BCm-1.3.3-green)
![Lisans](https://img.shields.io/badge/lisans-MIT-lightgrey)
[![Buy Me A Coffee](https://img.shields.io/badge/☕-Bana%20bir%20kahve%20%C4%B1smarla-FFDD00)](https://buymeacoffee.com/bkrdmrcioglu)

---

## ✨ Özellikler

### 🪟 Pencere Yaslama (15 pozisyon)
- Sol / Sağ / Üst / Alt yarılar
- Dört çeyrek (Sol Üst, Sağ Üst, Sol Alt, Sağ Alt)
- Üçte birler ve üçte ikiler
- Büyüt ve Ortala
- **Döngü**: aynı kısayola tekrar basınca yarı → ⅓ → ⅔ döner
- **Geri Yükle**: pencereyi yaslamadan önceki boyutuna döndürür
- **Pencere boşlukları**: yaslanan pencereler arasında ayarlanabilir boşluk (0–24 pt)

### ⌨️ Sistem Genelinde Klavye Kısayolları
Her uygulamada çalışır. Varsayılanlar:

| Kısayol | İşlev |
|---|---|
| ⌃⌥ ← | Sol Yarı (→ ⅓ → ⅔) |
| ⌃⌥ → | Sağ Yarı (→ ⅓ → ⅔) |
| ⌃⌥ ↑ | Üst Yarı |
| ⌃⌥ ↓ | Alt Yarı |
| ⌃⌥ ↩ | Büyüt |
| ⌃⌥ C | Ortala |
| ⌃⌥ ⌫ | Geri Yükle |
| ⌃⌥ N | Sonraki Ekrana Taşı |
| ⌃⌥ P | Önceki Ekrana Taşı |

Her eylem **uygulama içinden yeniden atanabilir** (Kısayollar → Değiştir → kombinasyona bas). Çeyrekler ve üçte birler dahil her pozisyona kısayol verilebilir. Çakışmalar otomatik tespit edilir.

### 🖱️ Sürükle-Yasla
Pencereyi ekran kenarına sürükle: mavi önizleme belirir, bırakınca yaslanır. Köşeler çeyreklere yaslar. Kenar hassasiyeti ayarlanabilir ve yalnızca gerçek pencere sürüklemelerinde tetiklenir.

### 📐 Düzen Profilleri
- **Mevcut Düzeni Kaydet**: açık tüm pencerelerin konum ve boyutunu yakalar
- **Uygula**: kayıtlı düzeni geri yükler — kapalı uygulamaları gerekirse başlatır
- Profiller kalıcıdır

### 📍 Menü Çubuğuna Yerli
Dock ikonu yok — Panevo tamamen menü çubuğunda yaşar; hızlı yaslama eylemleri bir tık uzakta.

### ⚙️ Ayarlar
- Girişte Başlat
- Yaslama animasyonu: Anında / Çevik / Akıcı / Esnek
- Pencere boşluğu ve kenar hassasiyeti kaydırıcıları
- Önizleme katmanı aç/kapa
- Tüm ayarlar kalıcı

### 🌍 Diller
İngilizce ve Türkçe — sistem dilini takip eder.

---

## 📥 Kurulum

**Homebrew** (önerilen):
```bash
brew install --cask bkrdmrcioglu/tap/panevo
```

**Elle**: [**Releases**](https://github.com/bkrdmrcioglu/panevo/releases) sayfasından son DMG'yi indir, aç ve Panevo'yu Applications'a sürükle.

Uygulama **Apple tarafından imzalı ve onaylıdır (notarized)** — güvenlik uyarısı çıkmaz, direkt açılır.

> İlk açılış: Sistem Ayarları → Gizlilik ve Güvenlik → Erişilebilirlik'ten izin ver. Bu izin, diğer uygulamaların pencerelerini taşıyabilmek için tüm pencere yöneticilerinde zorunludur.

### Neden App Store'da değil?
App Store, App Sandbox'ı zorunlu kılar; sandbox'lı uygulamalar ise diğer uygulamaların pencerelerini kontrol edemez — ki bu bir pencere yöneticisinin varlık sebebidir. Rectangle'ın da App Store'da olmamasının nedeni aynıdır.

## 🔨 Kaynak Koddan Derleme

```bash
git clone https://github.com/bkrdmrcioglu/panevo.git
cd panevo
open Panevo.xcodeproj   # sonra ⌘R
```

macOS 15+ ve Xcode 16+ gerektirir.

## 🏗️ Mimari

```
Panevo/
├── App.swift                  # Giriş noktası + AppDelegate (menü çubuğu yaşam döngüsü)
├── ContentView.swift          # Ana SwiftUI arayüzü
├── Models/                    # WindowPosition, KeyboardShortcut, LayoutProfile…
├── Services/
│   ├── WindowManager          # Yaslama, döngü, geri yükleme, boşluklar
│   ├── AccessibilityManager   # macOS Erişilebilirlik API sarmalayıcısı
│   ├── HotKeyManager          # Global kısayollar (Carbon), canlı yeniden kayıt
│   ├── DisplayManager         # Çoklu ekran takibi
│   ├── LayoutProfileManager   # Düzen kaydet/geri yükle
│   ├── SettingsManager        # UserDefaults kalıcılığı
│   └── StatusBarManager       # Menü çubuğu öğesi ve menüsü
├── ViewModels/                # MVVM koordinasyonu
├── Views/                     # Yaslama önizlemesi, tercihler penceresi
├── Utilities/                 # Uzantılar ve yardımcılar
└── en.lproj / tr.lproj        # Yerelleştirme
```

**Desenler:** MVVM, bağımlılık enjeksiyonu, servis katmanı. **Bağımlılık:** yok — yalnızca Apple çerçeveleri.

## 🔒 Gizlilik

- ❌ Ağ bağlantısı yok
- ❌ Veri toplama yok
- ✅ Tüm ayarlar yalnızca yerel

## 📝 Sürüm Geçmişi

### 1.3.2
- Uygulama içi güncelleme: DMG indirilir, kurulur ve uygulama otomatik yeniden açılır

### 1.3.1
- Uygulama içi güncelleme kontrolü için bakım sürümü

### 1.3.0
- Altılılar, %40/%60 ve neredeyse büyüt pozisyonları
- Undo, tüm pencereleri döşe, görsel snap paleti
- Uygulama kuralları, yok sayma listesi, ekran profili bağlama
- Başlık çift tık, ⌃⌥ sürükle paleti
- Ayarları dışa/içe aktarma, ilk açılış turu
- GitHub üzerinden güncelleme kontrolü

### 1.2
- Ayarlanabilir pencere boşlukları
- **Tüm** eylemlere kısayol atama; uygulama içi kısayol kaydetme
- Köşe sürükleme bölgeleri (çeyreklere yaslama) + kenar hassasiyeti ayarı
- Saf menü çubuğu uygulaması — Dock ikonu yok

### 1.1
- Geri Yükle, kısayol döngüsü (yarı → ⅓ → ⅔)
- Ekran taşıma kısayolları, kapalı uygulamaları başlatan düzen profilleri
- Uygulama ikonu, sürükle-yasla düzeltmeleri, çökme düzeltmesi

### 1.0
- 15 yaslama pozisyonu, 6 global kısayol, kenara sürükle-yasla
- Düzen profilleri, menü çubuğu hızlı eylemleri, çoklu ekran desteği
- İngilizce ve Türkçe arayüz

## ☕ Destek

Panevo ücretsiz ve açık kaynak. İşine yarıyorsa [**bana bir kahve ısmarlayabilirsin**](https://buymeacoffee.com/bkrdmrcioglu) — projeyi ayakta tutar!

## 🤝 Katkıda Bulunma

Katkılar memnuniyetle karşılanır! Başlamadan önce [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına göz at.
Hata bildirimi ve özellik önerileri için [issue şablonlarını](https://github.com/bkrdmrcioglu/panevo/issues/new/choose) kullan.

## 📄 Lisans

[MIT](LICENSE) — © 2026 Bekir Demircioglu

---

macOS üretkenliği için ❤️ ile geliştirildi.
