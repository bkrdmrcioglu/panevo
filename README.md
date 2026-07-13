# Panevo

**macOS için modern, yerel pencere yöneticisi.**

Panevo, pencerelerinizi klavye kısayolları, menü çubuğu veya sürükle-bırak ile saniyeler içinde düzenlemenizi sağlayan hafif bir macOS uygulamasıdır. Swift + SwiftUI + AppKit ile tamamen yerel olarak geliştirilmiştir; hiçbir harici bağımlılık içermez.

![Platform](https://img.shields.io/badge/platform-macOS%2015%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange)
![Sürüm](https://img.shields.io/badge/s%C3%BCr%C3%BCm-1.0-green)

---

## ✨ Özellikler

### 🪟 Pencere Yaslama (15 pozisyon)
- Sol / Sağ / Üst / Alt yarı
- Dört çeyrek (Sol Üst, Sağ Üst, Sol Alt, Sağ Alt)
- Üçte birler ve üçte ikiler
- Büyüt (tam ekran boyutu) ve Ortala

### ⌨️ Sistem Genelinde Klavye Kısayolları
Her uygulamada çalışır. Varsayılanlar:

| Kısayol | İşlev |
|---|---|
| ⌃⌥ ← | Sol Yarı |
| ⌃⌥ → | Sağ Yarı |
| ⌃⌥ ↑ | Üst Yarı |
| ⌃⌥ ↓ | Alt Yarı |
| ⌃⌥ ↩ | Büyüt |
| ⌃⌥ C | Ortala |

Kısayollar uygulama içinden **yeniden atanabilir** (Kısayollar → Değiştir → yeni kombinasyonu bas). Çakışan kısayollar otomatik tespit edilir.

### 📐 Düzen Profilleri
- **Mevcut Düzeni Kaydet**: Açık tüm pencerelerin konum ve boyutunu tek tıkla yakalar
- **Uygula**: Kaydedilen düzeni aynen geri yükler
- Profiller kalıcıdır — uygulama yeniden açıldığında durur

### 🖱️ Sürükle-Yasla
Bir pencereyi ekran kenarına sürükleyin: mavi önizleme belirir, bıraktığınızda pencere o yarıya oturur.

### 🖥️ Çoklu Ekran Desteği
Bağlı ekranlar otomatik algılanır; pencereler ekranlar arasında taşınabilir.

### 📍 Menü Çubuğu
Hızlı yaslama eylemleri (Sol/Sağ/Üst/Alt Yarı, Büyüt, Ortala), sonraki ekrana taşıma ve ana pencereye erişim menü çubuğundan bir tık uzakta.

### ⚙️ Ayarlar
- **Girişte Başlat** (Launch at Login)
- **Yaslama animasyonu**: Anında / Çevik / Akıcı / Esnek
- **Önizleme katmanı** aç/kapa
- Tüm ayarlar kalıcı olarak saklanır

### 🌍 Dil Desteği
- 🇹🇷 Türkçe
- 🇬🇧 İngilizce

Arayüz, sistem diline göre otomatik seçilir.

---

## 📋 Gereksinimler

- macOS 15 (Sequoia) veya üzeri
- Xcode 16+ (kaynak koddan derlemek için)

## 🔨 Kurulum ve Derleme

```bash
git clone https://github.com/bkrdmrcioglu/panevo.git
cd panevo
open Panevo.xcodeproj
```

Xcode'da **Panevo** şemasını seçip `⌘R` ile çalıştırın; ya da terminalden:

```bash
xcodebuild build -project Panevo.xcodeproj -scheme Panevo -configuration Release
```

## 🚀 İlk Çalıştırma

1. Panevo'yu başlatın
2. **Erişilebilirlik izni** isteğini onaylayın (Sistem Ayarları → Gizlilik ve Güvenlik → Erişilebilirlik → Panevo'yu açın)
3. Herhangi bir uygulamada `⌃⌥ →` deneyin — pencere sağ yarıya yaslanacaktır

> **Not:** Erişilebilirlik izni, Panevo'nun diğer uygulamaların pencerelerini taşıyıp boyutlandırabilmesi için gereklidir. Bu, tüm pencere yöneticilerinin (Rectangle, Magnet vb.) ortak gereksinimidir. Panevo ağa bağlanmaz ve hiçbir veri toplamaz.

## 🏗️ Mimari

```
Panevo/
├── App.swift                  # Giriş noktası + AppDelegate
├── ContentView.swift          # Ana arayüz (SwiftUI)
├── Models/                    # Veri yapıları (WindowPosition, LayoutProfile, KeyboardShortcut…)
├── Services/                  # İş mantığı
│   ├── WindowManager          # Yaslama orkestrasyonu
│   ├── AccessibilityManager   # macOS Erişilebilirlik API sarmalayıcısı
│   ├── HotKeyManager          # Global kısayollar (Carbon)
│   ├── DisplayManager         # Çoklu ekran takibi
│   ├── LayoutProfileManager   # Düzen kaydet/geri yükle
│   ├── SettingsManager        # UserDefaults kalıcılığı
│   └── StatusBarManager       # Menü çubuğu
├── ViewModels/                # MVVM koordinasyonu
├── Views/                     # Yardımcı pencereler (overlay, tercihler)
├── Utilities/                 # Uzantılar ve yardımcılar
├── en.lproj / tr.lproj        # Yerelleştirme
└── Assets.xcassets
```

**Desenler:** MVVM, bağımlılık enjeksiyonu, servis katmanı. **Bağımlılık:** Yok — yalnızca Apple çerçeveleri (SwiftUI, AppKit, Carbon, Combine, ServiceManagement).

## 🔒 Gizlilik

- ❌ Ağ bağlantısı yok
- ❌ Veri toplama yok
- ✅ Tüm ayarlar yalnızca yerel olarak saklanır

## 📝 Sürüm Geçmişi

### 1.0 — 2026
İlk sürüm:
- 15 pozisyonlu pencere yaslama
- 6 varsayılan global kısayol + uygulama içi yeniden atama ve çakışma tespiti
- Düzen profilleri (kaydet / uygula / sil, kalıcı)
- Sürükle-yasla + görsel önizleme katmanı
- Menü çubuğu hızlı eylemleri
- Çoklu ekran desteği
- 4 animasyon stili
- Girişte başlatma
- Türkçe ve İngilizce arayüz

## 🤝 Katkıda Bulunma

Katkılar memnuniyetle karşılanır! Başlamadan önce [CONTRIBUTING.md](CONTRIBUTING.md) dosyasına göz at.
Hata bildirimi ve özellik önerileri için [issue şablonlarını](https://github.com/bkrdmrcioglu/panevo/issues/new/choose) kullan.

## 📄 Lisans

[MIT](LICENSE) — © 2026 Bekir Demircioglu

---

macOS üretkenliği için ❤️ ile geliştirildi.
