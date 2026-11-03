#!/bin/bash
# Uygulamayı her ekran için '-ekran <ad>' bağımsız değişkeniyle açar ve ekran görüntüsü alır.
# Kullanım: ekranlar.sh <simülatör-udid> <çıktı-klasörü>
UDID="$1"; OUT="$2"; APPID=com.burakmert36.ihya
mkdir -p "$OUT"
cek() { # cek <ekran> <dosya> [bekleme] [görünüm]
  local ekran="$1" dosya="$2" bekle="${3:-13}" gorunum="${4:-light}"
  xcrun simctl ui "$UDID" appearance "$gorunum" || true
  xcrun simctl terminate "$UDID" "$APPID" 2>/dev/null || true
  xcrun simctl launch --terminate-running-process "$UDID" "$APPID" -ekranGoruntusu 1 -ekran "$ekran" > /dev/null
  sleep "$bekle"
  xcrun simctl io "$UDID" screenshot "$OUT/$dosya.png" > /dev/null 2>&1 && echo "✓ $dosya" || echo "✗ $dosya"
}
# ısınma: ilk açılış yavaş (Intel simülatör); ekran görüntüsünden önce bir kez aç-kapat
xcrun simctl launch "$UDID" "$APPID" -ekranGoruntusu 1 > /dev/null; sleep 25
cek bugun 01-bugun 16
cek odak 02-odak
cek odak-calisiyor 03-odak-calisiyor 14
cek odak-bitti 04-odak-bitti 14
cek bahce 05-bahce 15
cek istatistik 06-istatistik
cek koleksiyon 07-koleksiyon 15
cek sesler 08-sesler
cek kitaplik 09-kitaplik
cek hadis 10-hadis
cek hadis-koyu 11-hadis-koyu
cek dualar 12-dualar
cek dua-defteri 13-dua-defteri
cek esma 14-esma
cek kible 15-kible
cek dinigunler 16-dinigunler
cek kitaplar 17-kitaplar
cek zikir 18-zikir
cek zikir-istatistik 19-zikir-istatistik
cek vakitler 20-vakitler
cek ayarlar 21-ayarlar
cek okuma 22-okuma
cek bugun 23-bugun-koyu 15 dark
cek bahce 24-bahce-koyu 15 dark
xcrun simctl ui "$UDID" appearance light || true
