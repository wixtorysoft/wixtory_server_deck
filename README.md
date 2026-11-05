# ServerDeck — SSH Terminal & Remote SFTP Explorer

Bir Flutter projesi olarak geliştirilen **ServerDeck**, kendi Linux / Unix sunucularınıza SSH üzerinden doğrudan bağlanmanızı, tam interaktif VT100/xterm terminali kullanabilmenizi ve SFTP protokolüyle dosya sisteminin içinde gezinebilmenizi (dosya/klasör listeleme, metin dosyalarını görüntüleme, klasör oluşturma/silme vb.) sağlar.

---

## 🚀 Özellikler

### 1. 🖥️ SSH Terminal (xterm + dartssh2)
- **Gerçek Zamanlı PTY Oturumu:** VT100 / xterm ANSI renkleri, imleç hareketleri ve terminal boyutu yeniden boyutlandırma (`onResize`) desteği.
- **Sanal Klavye Yardımcı Çubuğu (Accessory Bar):** Mobil cihazlarda yazması zor olan `ESC`, `TAB`, `^C` (Ctrl+C), `^D`, `^Z`, `^L`, yön tuşları (`▲`, `▼`, `◄`, `►`), `|`, `~`, `/`, `-`, `_`, `&`, `>` gibi tuşlar için tek dokunuşluk çubuk.
- **Font Büyütme/Küçültme (A- / A+):** Terminal yazı boyutunu dinamik olarak ayarlama.
- **Hızlı Komutlar (Quick Snippets):** `top`, `df -h`, `free -h`, `docker ps`, `uptime`, `listening ports (ss/netstat)`, `uname -a`, `systemctl --failed` gibi sunucu teşhis komutlarını tek tıkla çalıştırma.

### 2. 📂 SFTP Dosya Tarayıcısı (Sunucunun İçini Gezme)
- **Etkileşimli Breadcrumb:** `/` > `var` > `log` > `nginx` şeklinde dizin ağacında tek tıkla geriye veya istenen klasöre atlama.
- **Doğrudan Yol Girişi (Jump to Path):** İstediğiniz dizine (`/var/www`, `/etc/nginx`, `/home`) doğrudan gitme.
- **Dosya Tipi İkonları:** Shell scriptleri, konfigürasyon dosyaları, loglar, arşivler, resimler ve klasörler için akıllı renklendirme ve ikonlar.
- **Dahili Dosya Görüntüleyici (File Viewer):** `.conf`, `.env`, `.log`, `.sh`, `.json`, `.yaml`, `.txt` gibi dosyaları indirmeye gerek kalmadan uygulama içinden okuma ve kopyalama.
- **Klasörden Terminale Geçiş:** Herhangi bir klasöre sağ tıklayıp / menüden "Open in Terminal" diyerek anında terminal sekmesine geçip o dizine `cd <path>` yapabilme.
- **Klasör Oluşturma & Silme:** Yeni klasör açma (`mkdir`) ve güvenli silme.

### 3. 🔐 Sunucu Yönetimi & Güvenlik
- **Çoklu Sunucu Kaydı:** İstediğiniz kadar sunucu profili ekleme, düzenleme ve silme.
- **Kimlik Doğrulama:**
  - Şifre (Password)
  - SSH Private Key (OpenSSH / PEM formatında RSA / ED25519) + opsiyonel Passphrase.
- **Yerel Güvenli Kayıt:** Profil bilgileri `SharedPreferences` üzerinde cihazda saklanır.

### 4. 🎨 Tasarım & UX
- Derin kromatik dark void teması (`#080B12`, `#0E1524`, `#10B981` Cyber Emerald & `#06B6D4` Cyan Aqua).
- Buzlu cam efektli layered Glassmorphism kartları.
- Google Fonts `Plus Jakarta Sans` ve terminal için `JetBrains Mono`.

---

## 📁 Proje Dizin Yapısı

```
server_deck/
├── lib/
│   ├── models/
│   │   ├── server_profile.dart        # Sunucu bağlantı profili modeli (Host, Port, User, Auth vb.)
│   │   └── remote_file_item.dart      # SFTP dosya ve dizin veri modeli
│   ├── services/
│   │   ├── ssh_service.dart           # SSH Client, PTY Shell akışları ve SFTP işlemleri
│   │   └── storage_service.dart       # Profil kaydetme/yükleme servisi
│   ├── theme/
│   │   ├── app_colors.dart            # Renk paleti ve tasarım belirteçleri
│   │   └── app_theme.dart             # ThemeData ve font tanımları
│   ├── widgets/
│   │   ├── glass_card.dart            # Buzlu cam (glassmorphic) container
│   │   ├── terminal_accessory_bar.dart# ESC, TAB, Ctrl tuşları sunan sanal klavye çubuğu
│   │   ├── quick_command_sheet.dart   # Hızlı sistem teşhis komutları menüsü
│   │   ├── file_viewer_sheet.dart     # Uzak dosya metin okuyucusu
│   │   └── server_form_dialog.dart    # Sunucu ekleme / düzenleme modalı
│   ├── screens/
│   │   ├── server_list_screen.dart    # Ana ekran: Kayıtlı sunucular ve yeni sunucu ekleme
│   │   ├── server_dashboard_screen.dart# Aktif oturum: Terminal ve SFTP sekmeli kontrol paneli
│   │   ├── terminal_view_tab.dart     # Etkileşimli xterm terminal ekranı
│   │   └── sftp_explorer_tab.dart     # Uzak dosya yöneticisi ekranı
│   └── main.dart                      # Uygulama başlangıç noktası
└── pubspec.yaml
```

---

## 🛠️ Nasıl Çalıştırılır?

Projeyi kendi cihazınızda veya simülatörünüzde çalıştırmak için:

```bash
cd server_deck
flutter run
```
