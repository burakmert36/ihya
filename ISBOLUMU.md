# İhya · İş bölümü

Bu dosya işin nerede olduğunu gösterir. Her aşama bitince güncellenir.

## Kurulum (telefona)

1. SideStore'da **Kaynak ekle**.
2. Adres: `https://github.com/burakmert36/ihya/releases/latest/download/sidestore.json`
3. İhya'yı kur. Yeni sürüm çıkınca SideStore günceller.

## Aşamalar

| Aşama | İş | Durum |
|---|---|---|
| A0 | Proje iskeleti, GitHub derleme hattı (IPA + simülatör ekran görüntüleri), uygulama simgesi | Bitti |
| A1 | İçerik: 314 Buhârî hadisi, 129 söz, 28 konulu dua, Dua Defterim, 99 isim, dinî günler 2026–2027 | Bitti |
| A2 | Bitki motoru v2: 27 çiçek, 27 ağaç, evreler, fiyatlar; uygulamada JavaScriptCore ile çizim | Bitti |
| A3 | Uygulama ekranları ve servisleri (aşağıdaki liste) | Sürüyor |
| A4 | Ekran görüntüleriyle denetim, düzeltmeler, performans ve pil | Sırada |
| A5 | Sürüm yayını ve kısa kullanım notu | Sırada |

## A3 · Ekranlar

| Bölüm | İçerik |
|---|---|
| Bugün | "İhya" başlığı, sıradaki vakit ve sayaç, beş vakit namaz takibi (ses, ışıltı, titreşim), bugünkü odak, günün hadisi ve sözü, kısayollar |
| Odak | Tür seçimi, 10–120 dk, konu (ad, renk, açıklama), oturum adı; büyüyen bitki, evre çubuğu; kilitlemek serbest, uygulamadan çıkınca kuruma; tamamlanma kutlaması |
| Bahçe | Gün/hafta/ay/yıl bahçesi, özet, grafikler, konu dağılımı, seri |
| Koleksiyon | 54 tür, tohumla kilit açma (dikmek ücretsiz), kilit açılınca kutlama |
| Sesler | 15 doğa sesi, karışım kaydetme (en çok 6 ses), hepsini kıs, "Odak süresince", "Sonda sesi yavaşça azalt", alt şerit |
| Zikir | Dönen tesbih (hız dokunuşa göre), sonsuz sayaç, 33×3 tesbihat, titreşim ve ses ayarı, kaydetme, istatistik |
| Kitaplık | Hadisler (punto, koyu okuma, kaydetme), sözler, dualar, Dua Defterim, Esmâ, kıble, dinî günler, PDF kitaplar, kaydedilenler |
| Vakitler | Bugün, otuz günlük takvim |
| Ayarlar | Vakit yeri, bildirimler, ezan ve bildirim sesi, odak, sesler, tesbih, görünüm, kaynaklar |

## Kararlar

- Tohum yalnız tür kilidi açar; dikmek ücretsiz. Tohum = 0,05 × dakika^1,3 (yuvarlanır).
- Başlangıçta açık türler: Karahindiba, Papatya, Çam, Kavak.
- Kitaplar telifli olduğu için depoya konmaz; uygulamada "PDF ekle" ile telefona eklenir.
- Ezan kaydı için lisansı açık bir kaynak bulunamadı. Makamlı ezan ve tek müezzin için kullanıcı kendi kaydını ekler; ilk 29 saniyesi bildirim sesi olur. Kısa bildirim tonları uygulamada üretildi.
- Şadırvan sesi kaldırıldı.
- Hadisler yalnız Sahîh-i Buhârî; her metin külliyata karşı sınandı (`Tasarim/uretim/icerik.py`).

## Bekleyenler

- Tefsir: kullanıcının kararı bekleniyor.
- Ana ekran araç takımı (widget) ve Canlı Etkinlik: A5'ten sonra.
- ruflo: daha sonra (kredi tüketimi yüzünden şimdilik kurulmadı).
