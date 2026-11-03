# İhya

Kişisel iPhone uygulaması: süreyle büyüyen odak bahçesi, Diyanet vakitleri, Sahîh-i Buhârî hadisleri, dualar, Esmâ-ül Hüsnâ, kıble, zikir, odak sesleri ve PDF kitaplık.

## Telefona kurulum

1. SideStore'da **Kaynak ekle**.
2. `https://github.com/burakmert36/ihya/releases/latest/download/sidestore.json`
3. İhya'yı kur. Yeni sürümler aynı kaynaktan gelir.

## Nasıl derlenir

Mac gerekmez. `main` dalına gönderilen her değişiklik GitHub Actions'ta derlenir:

- **IPA derle**: imzasız IPA ve `sidestore.json` sürüm olarak yayımlanır; günlük `build-logs` dalında.
- **Simülatör ekran görüntüleri**: iPhone 17 simülatöründe her ekranın görüntüsü `test-logs` dalına yazılır.

## Klasörler

- `App/` · Swift kaynakları (SwiftUI, iOS 26)
- `Resources/` · sesler, efektler, içerik (JSON), bitki motoru (`Plants/bitki.js`), yazı tipleri, simge
- `Tasarim/` · tasarım aşaması: bitki motoru kaynağı, veri, üretim betikleri, testler
- `ISBOLUMU.md` · iş bölümü ve durum

## Bağlantılar

- Şartname: https://claude.ai/artifact/TCWCsstU47HhLm8mH8ak6F
- Tasarım: https://claude.ai/artifact/NRmdaXj1FjQ3XorUqpFFPU
- Kaynaklar ve lisanslar: [Tasarim/CREDITS.md](Tasarim/CREDITS.md)
