#!/bin/bash
# (Yeniden deneme: GitHub Mac makineleri iş almıyor.)
# Uygulamayı her ekran için '-ekran <ad>' bağımsız değişkeniyle açar ve ekran görüntüsü alır.
# Sonda ses motorunu sınar (konsol çıktısı logs/ses.txt).
# Kullanım: ekranlar.sh <simülatör-udid> <çıktı-klasörü>
UDID="$1"; OUT="$2"; APPID=com.burakmert36.ihya
mkdir -p "$OUT" logs
cek() { # cek <ekran> <dosya> [bekleme]
  local ekran="$1" dosya="$2" bekle="${3:-13}"
  xcrun simctl terminate "$UDID" "$APPID" 2>/dev/null || true
  xcrun simctl launch --terminate-running-process "$UDID" "$APPID" -ekranGoruntusu 1 -ekran "$ekran" > /dev/null
  sleep "$bekle"
  xcrun simctl io "$UDID" screenshot "$OUT/$dosya.png" > /dev/null 2>&1 && echo "✓ $dosya" || echo "✗ $dosya"
}
xcrun simctl ui "$UDID" appearance light || true
# ısınma: ilk açılış yavaş (Intel simülatör); ekran görüntüsünden önce bir kez aç-kapat
xcrun simctl launch "$UDID" "$APPID" -ekranGoruntusu 1 > /dev/null; sleep 25
cek bugun 01-bugun 16
cek kuran 02-kuran 30
cek kuran-oku 03-kuran-oku 18
cek odak 04-odak 15
cek odak-calisiyor 05-odak-calisiyor 15
cek odak-bitti 06-odak-bitti 15
cek bahce 07-takip-bahce 16
cek takip-namaz 08-takip-namaz
cek takip-zikir 09-takip-zikir
cek istatistik 10-istatistik
cek koleksiyon 11-koleksiyon 15
cek sesler 12-sesler
cek kitaplik 13-kitaplik
cek hadis 14-hadis
cek dualar 15-dualar
cek dua-defteri 16-dua-defteri
cek esma 17-esma
cek kible 18-kible
cek zikir 19-zikir
cek vakitler 20-vakitler
cek ayarlar 21-ayarlar
cek tema-gece 22-tema-gece 15
cek tema-fildisi-kitaplik 23-tema-fildisi 15
cek tema-okyanus-kuran 24-tema-okyanus 18
cek tema-mor-bahce 25-tema-mor 16
cek tema-gunbatimi-takip-namaz 26-tema-gunbatimi 15
# ses sınaması: uygulama sınamayı bitirince kendini kapatır
xcrun simctl terminate "$UDID" "$APPID" 2>/dev/null || true
xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$APPID" -ekranGoruntusu 1 -ekran bugun -sesSinama 1 > logs/ses.txt 2>&1 &
SP=$!
sleep 40
xcrun simctl terminate "$UDID" "$APPID" 2>/dev/null || true
kill $SP 2>/dev/null || true
grep "SES" logs/ses.txt | head -40 || echo "ses.txt boş"
