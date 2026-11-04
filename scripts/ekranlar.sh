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
cek odak 02-odak 15
cek odak-calisiyor 03-odak-calisiyor 15
cek odak-bitti 04-odak-bitti 15
cek bahce 05-bahce 16
cek istatistik 06-istatistik
cek koleksiyon 07-koleksiyon 15
cek sesler 08-sesler
cek kitaplik 09-kitaplik
cek hadis 10-hadis
cek hadisler 11-hadisler
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
cek favoriler 22-favoriler
cek tema-gece 23-tema-gece 15
cek tema-fildisi-kitaplik 24-tema-fildisi 15
cek tema-lacivert-vakitler 25-tema-lacivert 15
cek tema-zumrut-bahce 26-tema-zumrut 16
# ses sınaması: uygulama sınamayı bitirince kendini kapatır
xcrun simctl terminate "$UDID" "$APPID" 2>/dev/null || true
xcrun simctl launch --console-pty --terminate-running-process "$UDID" "$APPID" -ekranGoruntusu 1 -ekran bugun -sesSinama 1 > logs/ses.txt 2>&1 &
SP=$!
sleep 40
xcrun simctl terminate "$UDID" "$APPID" 2>/dev/null || true
kill $SP 2>/dev/null || true
grep "SES" logs/ses.txt | head -40 || echo "ses.txt boş"
