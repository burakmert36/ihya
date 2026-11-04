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
| A3 | Uygulama ekranları ve servisleri (aşağıdaki liste) | Bitti (sürüm 1.0.4+) |
| A4 | Ekran görüntüleriyle denetim, düzeltmeler, performans ve pil | Sürüyor |
| A4b | Tasarıma sadık arayüz: sahne zeminleri, Liquid Glass, beş tema, yeni alt çubuk, ses motoru ve bildirim düzeltmeleri | Sürüyor (1.1) |
| A5 | Sürüm yayını ve kısa kullanım notu | Sırada |

## 1.3 eklenenler

- Kur'an: Kâbe imamlarından (Südeys, Muaykılî, Devserî, Cühenî, Şüreym, Ali Câbir) âyet âyet takipli tilavet; okunan âyet vurgulanır, ekranda tutulur; tekrar, hız, sûreyi indirme. Kayıtlar EveryAyah arşivinden dinlerken iner (depoya girmez).
- Mealde kelime araması, "36:12" ile âyete gitme, âyet kaydetme.
- Beyaz, pembe, kahverengi gürültü (cihazda üretilir). Kilit ekranından çal/durdur, önceki/sonraki âyet; kulaklık çıkınca durur.
- Yedek: her gün telefondaki Yedekler klasörüne ve seçilen iCloud Drive klasörüne; dışa aktarma ve onaylı geri yükleme.
- Seri: gün sınırı imsak, 7 günde bir rahmet yağmuru (en çok 2), 48 saatte 2 dikimle telafi, kilometre taşları. Seri hatırlatması ve Cuma özeti.
- Kaza defteri, Esmâ'dan zikre geçiş, PDF ve Kur'an'ı odakla okuma, okuma temaları (Gündüz/Sepya/Gece/Siyah/Kendiliğinden), sıcak ışık, satır arası, ekranın açık kalması.
- Diyanet ülke/şehir/ilçe seçimi.
- Widget'lar (seri, namaz vakti), Odak Canlı Etkinliği (Dynamic Island), Denetim Merkezi düğmeleri.
- Birim testleri (Tests/) CI'da simülatörde çalışır; sonuç test-logs dalında testler.txt.

## Arayüz düzeni (1.1)

- Alt çubuk: Bugün · Bahçe · Kitaplık · Vakit; yanında yeşil yuvarlak Odak düğmesi (Odak tam ekran açılır).
- Zikir, Kitaplık'ta ve Bugün'deki kısayolda. Ayarlar, Bugün başlığındaki dişliden.
- Her ekran kendi sahnesinde: Bugün gökyüzü, Odak yeşil, Bahçe ada, Kitaplık camgöbeği, Vakit gün batımı, Hadis çivit, Sesler gece mavisi, Zikir lacivert.
- Temalar: İhya (sahneli, varsayılan), Gece, Fildişi, Lacivert, Zümrüt.
- Ses motoru: altı sabit yuva, motor başlamadan bağlanır; CI'da `-sesSinama 1` ile sınanır (`logs/ses.txt`).

## A3 · Ekranlar

| Bölüm | İçerik |
|---|---|
| Bugün | "İhya" başlığı, sıradaki vakit ve sayaç, beş vakit namaz takibi (ses, ışıltı, titreşim), bugünkü odak, günün hadisi ve sözü, kısayollar |
| Odak | Tür seçimi, 10–120 dk, konu (ad, renk, açıklama), oturum adı; büyüyen bitki, evre çubuğu; kilitlemek serbest, uygulamadan çıkınca kuruma; tamamlanma kutlaması |
| Bahçe | Gün/hafta/ay/yıl bahçesi, özet, grafikler, konu dağılımı, seri |
| Koleksiyon | 54 tür, tohumla kilit açma (dikmek ücretsiz), kilit açılınca kutlama |
| Sesler | 15 doğa sesi; her ses için ayrı düzey ve yakınlık-uzaklık; karışım kaydetme (en çok 6 ses), hepsini kıs, "Odak süresince", "Sonda sesi yavaşça azalt", alt şerit |
| Zikir | Dönen tesbih (hız dokunuşa göre), sonsuz sayaç, 33×3 tesbihat, titreşim ve ses ayarı, kaydetme, istatistik |
| Kitaplık | Hadisler (punto, koyu okuma, kaydetme), sözler, dualar, Dua Defterim (istiğfar ve salavat sayaçlı), Esmâ, kıble, dinî günler, PDF kitaplar, kaydedilenler |
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
- ruflo: daha sonra (kredi tüketimi yüzünden şimdilik kurulmadı).
