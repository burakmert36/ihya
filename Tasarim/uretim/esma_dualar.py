"""Esmâ-i Hüsnâ'nın her ismine özel dualar ve âyetler üretir; her metni kaynağına karşı doğrular.

Çıktı: Resources/Content/esma_dualar.json  → {"dualar": {id: dua}, "isimler": {"1": [id, ...], ...}}
Kullanım: python3 -I Tasarim/uretim/esma_dualar.py <külliyat klasörü>
  külliyat klasörü: data/raw/{ara-quranuthmanihaf,tur-diyanetisleri,tur-latinalphabet,ara-bukhari}.json
  ve data/hadis/all_clean.json (Türkçe Buhârî) dosyalarını içerir.

Kaynak sırası: önce Sahîh-i Buhârî'deki dualar, sonra Kur'an'daki peygamber ve mü'min duaları,
sonra ismin geçtiği âyetler (A'râf 7:180: “O'na o isimlerle dua edin”).
Doğrulama:
  · Âyetlerin Arapçası Mushaf külliyatından kelime kelime alınır; meal Diyanet mealinde birebir aranır;
    okunuş, Latin harfli okunuşla iskelet benzerliğine bakılarak yanlış âyet/aralık hatasına karşı denetlenir.
  · Hadislerin Arapçası Buhârî Arapça külliyatından harekesiyle kesilir (yazılan baş ve son kalıp bulunmazsa hata);
    Türkçe alıntı Buhârî Türkçe külliyatında aranır.
Bulunamayan olursa betik hata verir ve dosya yazılmaz.
"""
import difflib
import json
import re
import sys
from pathlib import Path

KOK = Path(__file__).resolve().parents[2]
KAY = Path(sys.argv[1]) if len(sys.argv) > 1 else KOK / "Tasarim" / "kaynak"
HEDEF = KOK / "Resources" / "Content"
HATA = []


def yukle(ad):
    return {(v["chapter"], v["verse"]): v["text"] for v in json.load(open(KAY / "data/raw" / ad, encoding="utf-8"))["quran"]}


ARAPCA, MEAL, LATIN = yukle("ara-quranuthmanihaf.json"), yukle("tur-diyanetisleri.json"), yukle("tur-latinalphabet.json")
BUHARI_AR = {h["hadithnumber"]: h["text"] for h in json.load(open(KAY / "data/raw/ara-bukhari.json", encoding="utf-8"))["hadiths"]}
BUHARI_TR = {x["n"]: x["tr"] for x in json.load(open(KAY / "data/hadis/all_clean.json", encoding="utf-8"))}
SWIFT = (KOK / "App/Kuran/KuranDeposu.swift").read_text(encoding="utf-8")
SURE = re.findall(r'"([^"]+)"', SWIFT.split("static let adlar = [")[1].split("]")[0])
assert len(SURE) == 114


def norm(s: str) -> str:
    s = s.replace("İ", "i").replace("I", "ı").lower()
    return re.sub(r"[^a-zçğıöşü]", "", s.replace("â", "a").replace("î", "i").replace("û", "u"))


# ——— Arapça: harekesiz eşleştirip harekeli metni kesmek ———
HAREKE = re.compile(r"[ً-ٰٟۖ-ۭـ‎‏]")
ESLE = {"أ": "ا", "إ": "ا", "آ": "ا", "ٱ": "ا", "ى": "ي", "ة": "ه", "ؤ": "و", "ئ": "ي"}


def harita(s):
    out, idx, bos = [], [], True
    for i, c in enumerate(s):
        if HAREKE.match(c):
            continue
        c = ESLE.get(c, c)
        if "ء" <= c <= "ي":
            out.append(c), idx.append(i)
            bos = False
        elif not bos:
            out.append(" "), idx.append(i)
            bos = True
    return "".join(out), idx


def sade(s):
    return harita(s)[0].strip()


def kes(no, bas, son, sondan=False):
    t = BUHARI_AR.get(no, "")
    v, idx = harita(t)
    b = v.find(sade(bas))
    e = (v.rfind if sondan else v.find)(sade(son), b) if b >= 0 else -1
    if b < 0 or e < 0:
        HATA.append(f"Buhârî {no} Arapça bulunamadı: {bas} … {son}")
        return ""
    e += len(sade(son)) - 1
    j = idx[e] + 1
    while j < len(t) and HAREKE.match(t[j]):
        j += 1
    return t[idx[b]:j]


def iskelet(s):
    """Okunuşun ünsüz iskeleti: ünlüler, işaretler ve ikizlenmeler atılır."""
    s = norm(s).translate(str.maketrans("çğşıöü", "cgsiou"))
    s = re.sub(r"[aeiou]", "", s.replace("dh", "z").replace("th", "s"))
    return re.sub(r"(.)\1+", r"\1", s)


def okunus_denetle(etiket, okunus, sure, ayetler):
    ben, kaynak = iskelet(okunus), iskelet(" ".join(LATIN[(sure, a)] for a in ayetler))
    m = difflib.SequenceMatcher(None, ben, kaynak, autojunk=False)
    oran = sum(b.size for b in m.get_matching_blocks()) / max(1, len(ben))
    ORANLAR.append((oran, etiket))
    if oran < 0.82:
        HATA.append(f"Okunuş Latin metne benzemiyor ({oran:.2f}): {etiket}")


DUALAR = {}
ORANLAR = []


def ekle(id_, d):
    d["arapca"] = d["arapca"].replace("۞", "").strip("\u200e\u200f ،")
    if id_ in DUALAR:
        HATA.append(f"Tekrarlı kimlik: {id_}")
    DUALAR[id_] = {k: v for k, v in d.items() if v}


def ayet(id_, baslik, tur, sure, ayetler, okunus, anlam, kelime=None, not_="", buhari=None):
    """kelime: (ilk, son) Arapça kelime sırası (tek âyette, son dahil; son None ise âyet sonu)."""
    tam = " ".join(MEAL[(sure, a)] for a in ayetler)
    if norm(anlam) not in norm(tam):
        HATA.append(f"Meal eşleşmedi: {sure}:{ayetler} → {anlam[:60]}")
    if kelime:
        w = ARAPCA[(sure, ayetler[0])].split()
        ar = " ".join(w[kelime[0]:None if kelime[1] is None else kelime[1] + 1])
    else:
        ar = " ".join(ARAPCA[(sure, a)] for a in ayetler)
    okunus_denetle(id_, okunus, sure, ayetler)
    aralik = f"{ayetler[0]}" if len(ayetler) == 1 else f"{ayetler[0]}-{ayetler[-1]}"
    kaynak = f"{SURE[sure - 1]} {sure}:{aralik}"
    if buhari:
        no, alinti = buhari
        if norm(alinti) not in norm(BUHARI_TR[no]):
            HATA.append(f"Buhârî {no} Türkçe alıntı eşleşmedi: {alinti[:60]}")
        kaynak += f" · Buhârî, {no}"
    ekle(id_, {"baslik": baslik, "tur": tur, "arapca": ar, "okunus": okunus, "anlam": anlam.rstrip(".") + ".", "kaynak": kaynak, "not": not_})


def hadis(id_, baslik, tur, no, arapca, okunus, anlam, alinti=None, not_=""):
    """arapca: (baş kalıbı, son kalıbı[, sondan]) — metin külliyattan harekesiyle kesilir."""
    ar = kes(no, *arapca)
    if alinti is not False and norm(alinti or anlam) not in norm(BUHARI_TR[no]):
        HATA.append(f"Buhârî {no} Türkçe alıntı eşleşmedi: {(alinti or anlam)[:60]}")
    ekle(id_, {"baslik": baslik, "tur": tur, "arapca": ar, "okunus": okunus, "anlam": anlam, "kaynak": f"Buhârî, {no}", "not": not_})


PD, KD, AY, HD, KU = "Hz. Peygamber'in duası", "Kur'an'dan dua", "Âyet", "Hadis", "Hadis-i kudsî"

# ——— Sahîh-i Buhârî ———
hadis("h-6403", "Günde yüz defa", PD, 6403, ("لا اله الا الله", "قدير"),
      "Lâ ilâhe illallâhü vahdehû lâ şerîke leh, lehü'l-mülkü ve lehü'l-hamdü ve hüve alâ külli şey'in kadîr.",
      "Ortağı olmayan Allah'tan başka ilah yoktur. Mülk de O'nun, hamd de O'nundur. O her şeye kadirdir.",
      alinti="Ortağı olmayan Allah'tan başka ilah yoktur mülk de onun",
      not_="Gündüz yüz defa söyleyen on köle azat etmiş gibi olur; yüz iyilik yazılır, yüz kötülüğü silinir.")
hadis("h-7392", "Doksan dokuz isim", HD, 7392, ("ان لله تسعه وتسعين", "دخل الجنه"),
      "İnne lillâhi tis'aten ve tis'îne ismen, mieten illâ vâhidâ, men ahsâhâ dehale'l-cenneh.",
      "Allah'ın yüzden bir eksik, doksan dokuz ismi vardır. Bu isimleri her kim sayarsa cennete girer.",
      alinti="doksandokuz ismi vardır. Bu isimleri her kim sayarsa cennete girer",
      not_="Buhârî hadisin ardından “ahsâ” (saymak) kelimesini “ezberlemek” diye açıklar.")
hadis("h-6406", "Rahmân'a sevimli iki söz", PD, 6406, ("كلمتان خفيفتان", "وبحمده"),
      "Kelimetâni hafîfetâni ale'l-lisân, sakîletâni fi'l-mîzân, habîbetâni ile'r-Rahmân: Sübhânallâhi'l-azîm, sübhânallâhi ve bi-hamdih.",
      "Dilde hafif, mizanda ağır, Rahmân'a sevimli iki söz: Azîm olan Allah'ı tesbih ederim. Allah'ı noksan sıfatlardan tenzih edip O'na hamd ederim.",
      alinti="Azim olan Allah'ı tesbih ederim. Allah'ı noksan sıfatlardan tenzih edip ona hamd ederim")
hadis("h-834", "Hz. Ebû Bekir'e öğretilen dua", PD, 834, ("اللهم اني ظلمت نفسي", "الغفور الرحيم"),
      "Allâhümme innî zalemtü nefsî zulmen kesîran ve lâ yağfiru'z-zünûbe illâ ente, fağfir lî mağfiraten min indike verhamnî, inneke ente'l-Ğafûru'r-Rahîm.",
      "Allah'ım! Ben kendime çok zulmettim. Günahları Senden başka bağışlayacak yoktur. Beni katından bir mağfiretle bağışla ve bana merhamet et. Şüphesiz Sen Ğafûr'sun, Rahîm'sin.",
      alinti="Allah'ım ben kendime çok fazla zulmettim. Günahları sen'den başka bağışlayacak yoktur",
      not_="Resûlullah bu duayı Hz. Ebû Bekir'e namazda okuması için öğretti.")
hadis("h-5999", "Anneden daha merhametli", HD, 5999, ("الله ارحم بعباده", "بولدها"),
      "Allâhü erhamü bi-ibâdihî min hâzihî bi-veledihâ.",
      "Allah'ın kullarına olan merhameti, bu kadının çocuğuna olan merhametinden fazladır.",
      alinti="Allah'ın kullarına olan merhameti bu kadının çocuğuna olan merhametinden fazladır",
      not_="Resûlullah bunu, esirler arasında yavrusunu bağrına basan bir anneyi gösterirken söyledi.")
hadis("h-831", "Tahiyyât", PD, 831, ("التحيات لله", "الصالحين"),
      "Et-tahiyyâtü lillâhi ve's-salavâtü ve't-tayyibât, es-selâmü aleyke eyyühe'n-nebiyyü ve rahmetullâhi ve berakâtüh, es-selâmü aleynâ ve alâ ibâdillâhi's-sâlihîn.",
      "Bütün tahiyyeler, dualar ve güzel sözler Allah içindir. Ey Peygamber! Selâm, Allah'ın rahmeti ve bereketleri senin üzerine olsun. Selâm bizim üzerimize ve Allah'ın salih kulları üzerine olsun.",
      alinti="Şüphesiz Selâm olan sadece Allah'tır",
      not_="Resûlullah “Şüphesiz Selâm olan Allah'tır” buyurup namazda bunu okumayı öğretti.")
hadis("h-7383", "İzzetine sığınma", PD, 7383, ("اعوذ بعزتك", "يموتون"),
      "E'ûzü bi-izzetike'llezî lâ ilâhe illâ ente, ellezî lâ yemûtü ve'l-cinnü ve'l-insü yemûtûn.",
      "Allah'ım! Senin izzetine sığınırım. Senden başka ilah yoktur. Sen ölümsüz olansın; cinler ve insanlar ise ölürler.",
      alinti="senin izzetine sığınırım")
hadis("h-6306", "Seyyidü'l-istiğfâr", PD, 6306, ("اللهم انت ربي", "فانه لا يغفر الذنوب الا انت"),
      "Allâhümme ente Rabbî, lâ ilâhe illâ ente, halaktenî ve ene abdük, ve ene alâ ahdike ve va'dike me'steta'tü, eûzü bike min şerri mâ sana'tü, ebûü leke bi-ni'metike aleyye, ve ebûü leke bi-zenbî, fağfir lî, fe-innehû lâ yağfiru'z-zünûbe illâ ente.",
      "Allah'ım! Sen benim Rabbimsin. Senden başka ilah yoktur. Beni Sen yarattın, ben Senin kulunum. Gücüm yettiğince Sana verdiğim söz ve ahid üzereyim. Yaptıklarımın şerrinden Sana sığınırım. Bana verdiğin nimeti ikrar ederim, günahımı da itiraf ederim. Beni bağışla; çünkü günahları Senden başka bağışlayan yoktur.",
      alinti="Seyyidu'l-istiğfar = İstiğfarların efendisi",
      not_="İnanarak gündüz okuyup akşamdan önce ölen cennetliktir; gece okuyup sabahtan önce ölen de öyle.")
hadis("h-6382", "İstihâre duasından", PD, 6382, ("اللهم اني استخيرك", "علام الغيوب"),
      "Allâhümme innî estehîruke bi-ilmike ve estakdiruke bi-kudretike ve es'elüke min fadlike'l-azîm, fe-inneke takdiru ve lâ akdiru, ve ta'lemu ve lâ a'lemu, ve ente allâmü'l-ğuyûb.",
      "Allah'ım! İlmine sığınıp hakkımda hayırlı olanı Senden diliyorum. Kudretine sığınıp Senden güç istiyorum. Senin yüce fazlından niyaz ediyorum. Çünkü Sen güçlüsün, ben değilim. Sen bilirsin, ben bilmem. Sen bütün gayblardan haberdarsın.",
      alinti="İlmine sığınıp hakkımda hayırlı olanı senden diliyorum. Kudretine sığınıp senden güç istiyorum",
      not_="Bir işe karar vermeden önce iki rekât namaz kılınıp bu dua okunur.")
hadis("h-7411", "Terazi O'nun elindedir", HD, 7411, ("عرشه على الماء", "يخفض ويرفع"),
      "Arşuhû ale'l-mâ', ve bi-yedihi'l-uhra'l-mîzânü yahfidu ve yerfe'.",
      "Arşı su üzerindedir. Diğer elinde adalet terazisi vardır; onu alçaltır, yükseltir.",
      alinti="onun diğer elinde adalet terazisi vardır ki onun kefesini alçaltır, yükseltir",
      not_="Hâfıd (alçaltan) ve Râfi' (yükselten) isimleri bu “alçaltır, yükseltir” fiillerindendir.")
hadis("h-6384", "İşiten ve görene dua", HD, 6384, ("فانكم لا تدعون اصم", "سميعا بصيرا"),
      "Fe-inneküm lâ ted'ûne esamme ve lâ ğâiben, ve lâkin ted'ûne semî'an basîrâ.",
      "Sağır ya da gaibe dua etmiyorsunuz. İşiten ve gören Allah'a dua ediyorsunuz.",
      alinti="Sağır ya da gaibe dua etmiyorsunuz. Gören ve işiten Allah'a dua ediyorsunuz",
      not_="Resûlullah yüksek sesle tekbir getiren ashabına bunu söyledi.")
hadis("h-kerb", "Sıkıntı anında", PD, 6346, ("لا اله الا الله العظيم", "العرش الكريم"),
      "Lâ ilâhe illallâhü'l-Azîmü'l-Halîm, lâ ilâhe illallâhü Rabbü'l-arşi'l-azîm, lâ ilâhe illallâhü Rabbü's-semâvâti ve Rabbü'l-ardı ve Rabbü'l-arşi'l-kerîm.",
      "Azîm ve Halîm olan Allah'tan başka ilah yoktur. Yüce arşın Rabbi olan Allah'tan başka ilah yoktur. Göklerin Rabbi, yerin Rabbi ve kerîm arşın Rabbi olan Allah'tan başka ilah yoktur.",
      alinti="Azim ve halim olan Allah'tan başka ilah yoktur, Yüce arşın rabbi olan Allah'tan başka ilah yoktur",
      not_="Resûlullah sıkıntı ve keder anında böyle dua ederdi.")
hadis("h-1154", "Gece uyanınca", PD, 1154, ("لا اله الا الله وحده", "ولا قوه الا بالله"),
      "Lâ ilâhe illallâhü vahdehû lâ şerîke leh, lehü'l-mülkü ve lehü'l-hamd, ve hüve alâ külli şey'in kadîr. El-hamdü lillâh, ve sübhânallâh, ve lâ ilâhe illallâh, vallâhü ekber, ve lâ havle ve lâ kuvvete illâ billâh.",
      "Allah'tan başka ilah yoktur; tektir, ortağı yoktur. Mülk O'nun, hamd O'nundur; O her şeye kadirdir. Hamd Allah'adır, Allah'ı tesbih ederim, Allah'tan başka ilah yoktur, Allah en büyüktür; güç ve kuvvet ancak Allah'tandır.",
      alinti="Yahut dua ederse, onun duasına icabet edilir",
      not_="Gece uyanıp bunu söyleyen, sonra bağışlanma diler ya da dua ederse duası kabul edilir.")
hadis("h-6320", "Yatarken", PD, 6320, ("باسمك رب وضعت جنبي", "عبادك الصالحين"),
      "Bismike Rabbî veda'tü cenbî ve bike erfe'uh, in emsekte nefsî ferhamhâ, ve in erseltehâ fahfazhâ bi-mâ tahfazu bihî ibâdeke's-sâlihîn.",
      "Rabbim! Senin isminle yatağıma yattım, yine Seninle kalkacağım. Eğer canımı alırsan ona merhamet et. Eğer bırakırsan, salih kullarını koruduğun gibi onu koru.",
      alinti="Eğer gece canımı alırsan bana merhamet et. Eğer yaşamamı irade edersen beni salih kulların gibi koru")
hadis("h-1145", "Gecenin son üçte biri", HD, 1145, ("ينزل ربنا", "فاغفر له"),
      "Yenzilü Rabbünâ tebâreke ve teâlâ külle leyletin ile's-semâi'd-dünyâ hîne yebkâ sülüsü'l-leyli'l-âhir, yekûlü: Men yed'ûnî fe-estecîbe leh, men yes'elünî fe-u'tiyeh, men yestağfirunî fe-ağfira leh.",
      "Yüce Rabbimiz her gece, gecenin son üçte biri kaldığında en yakın semaya inerek şöyle der: Bana dua eden yok mu, ona icabet edeyim. İsteyen yok mu, ona vereyim. Bağışlanma isteyen yok mu, onu bağışlayayım.",
      alinti="gecenin son üçte biri kaldığında en yakın semaya inerek şöyle der: Bana dua eden yok mu ona icabet edeyim")
hadis("h-1120", "Teheccüd duasından", PD, 1120, ("اللهم لك الحمد انت قيم", "وقولك حق"),
      "Allâhümme leke'l-hamdü ente kayyimü's-semâvâti ve'l-ardı ve men fîhinne, ve leke'l-hamdü leke mülkü's-semâvâti ve'l-ardı ve men fîhinne, ve leke'l-hamdü ente nûru's-semâvâti ve'l-ard, ve leke'l-hamdü ente'l-hakku ve va'düke'l-hakku ve likâüke hakkun ve kavlüke hakk.",
      "Allah'ım! Hamd Sana mahsustur; göklerin, yerin ve içindekilerin ayakta tutanı (kayyimi) Sensin. Hamd Sana mahsustur; göklerin, yerin ve içindekilerin mülkü Senindir. Hamd Sana mahsustur; göklerin ve yerin nuru Sensin. Hamd Sana mahsustur; Sen Hak'sın, vaadin haktır, Sana kavuşmak haktır, sözün haktır.",
      alinti="leke'l-hamdu ente kayyimu's-semâvâti vel-ardı",
      not_="Resûlullah gece teheccüde kalkınca böyle dua ederdi.")
hadis("h-6398", "Bütün hatalarım için", PD, 6398, ("رب اغفر لي خطيئتي", "قدير"),
      "Rabbiğfir lî hatîetî ve cehlî ve isrâfî fî emrî küllih, ve mâ ente a'lemü bihî minnî. Allâhümmağfir lî hatâyâye ve amdî ve cehlî ve hezlî, ve küllü zâlike indî. Allâhümmağfir lî mâ kaddemtü ve mâ ahhartü ve mâ esrartü ve mâ a'lentü, ente'l-Mukaddimu ve ente'l-Muahhiru ve ente alâ külli şey'in kadîr.",
      "Rabbim! Her konuda hatalarımı, bilmediklerimi, israflarımı ve Senin benden daha iyi bildiğin şeyleri bağışla. Allah'ım! Yaptığım yanlışları, kasıtlı yaptıklarımı, bilmediklerimi ve şakalarımı bağışla; ben bunların hepsini yapmışımdır. Allah'ım! Geçmişte yaptıklarımı ve gelecekte yapacaklarımı, gizli ve açık kusurlarımı bağışla. Öne alan da Sensin, sona bırakan da Sensin ve Sen her şeye kadirsin.",
      alinti="Öne alan da sensin sona bırakan da sensin ve sen her şeye kadirsin")
hadis("h-3370", "Salavât", PD, 3370, ("اللهم صل على محمد", "انك حميد مجيد", True),
      "Allâhümme salli alâ Muhammedin ve alâ âli Muhammed, kemâ salleyte alâ İbrâhîme ve alâ âli İbrâhîm, inneke Hamîdün Mecîd. Allâhümme bârik alâ Muhammedin ve alâ âli Muhammed, kemâ bârekte alâ İbrâhîme ve alâ âli İbrâhîm, inneke Hamîdün Mecîd.",
      "Allah'ım! İbrâhim'e ve İbrâhim'in ailesine salât ettiğin gibi Muhammed'e ve Muhammed'in ailesine de salât et; şüphesiz Sen Hamîd'sin, Mecîd'sin. Allah'ım! İbrâhim'e ve İbrâhim'in ailesine bereket verdiğin gibi Muhammed'e ve Muhammed'in ailesine de bereket ver; şüphesiz Sen Hamîd'sin, Mecîd'sin.",
      alinti="Çünkü sen Hamidsin, Mecidsin",
      not_="Ashab “Sana nasıl salavat getirelim?” diye sorunca Resûlullah bunu öğretti.")
hadis("h-844", "Namazların ardından", PD, 844, ("لا اله الا الله وحده", "منك الجد"),
      "Lâ ilâhe illallâhü vahdehû lâ şerîke leh, lehü'l-mülkü ve lehü'l-hamd, ve hüve alâ külli şey'in kadîr. Allâhümme lâ mâni'a limâ a'tayte ve lâ mu'tıye limâ mena'te ve lâ yenfe'u ze'l-ceddi minke'l-cedd.",
      "Tek olan Allah'tan başka ilah yoktur, O'nun ortağı yoktur. Mülk O'nundur, övgü O'nadır. O'nun her şeye gücü yeter. Allah'ım! Senin verdiğine engel olacak hiçbir şey yoktur. Senin engel olduğunu da verebilecek yoktur. Senin yanında zenginin zenginliği fayda vermez.",
      alinti="Allah'ım, Senin verdiğine engel olacak hiçbir şey yoktur. Senin engel olduğunu da verebilecek yoktur. Senin yanında zenginin zenginliği fayda vermez",
      not_="Resûlullah her farz namazın ardından böyle derdi.")
hadis("h-6316", "Nur duası", PD, 6316, ("اللهم اجعل في قلبي نورا", "واجعل لي نورا"),
      "Allâhümme'c'al fî kalbî nûran, ve fî basarî nûran, ve fî sem'î nûran, ve an yemînî nûran, ve an yesârî nûran, ve fevkî nûran, ve tahtî nûran, ve emâmî nûran, ve halfî nûran, vec'al lî nûrâ.",
      "Allah'ım! Kalbime, gözüme, kulağıma, sağıma, soluma, üstüme, altıma, önüme, arkama, hâsılı bana nur bahşet.",
      alinti="Kalbime, gözüme, kulağıma, sağıma, soluma, üstüme, altıma, önüme, arkama hasılı bana nur bahşet",
      not_="Resûlullah gece namazından sonra böyle dua ederdi.")
hadis("h-uyku", "Uyumadan önce", PD, 6324, ("باسمك اللهم اموت", "واحيا"),
      "Bismike'llâhümme emûtü ve ahyâ.",
      "Allah'ım! Senin adınla ölür ve dirilirim.",
      alinti="Senin adınla ölür ve dirilirim")
hadis("h-uyanis", "Uyanınca", PD, 6324, ("الحمد لله الذي احيانا", "النشور"),
      "El-hamdü lillâhillezî ahyânâ ba'de mâ emâtenâ ve ileyhi'n-nüşûr.",
      "Bizi öldürdükten sonra tekrar dirilten ve en sonunda mezarlarımızdan bizi çıkaracak olan Allah'a hamdolsun.",
      not_="Uyku küçük ölüm, uyanış küçük diriliştir; Bâis (dirilten) isminin her sabahki hatırlatıcısı.")
hadis("h-4974", "Ben Ehad'im, Samed'im", KU, 4974, ("وانا الاحد الصمد", "كفا احد"),
      "Ve ene'l-Ehadü's-Samed, lem elid ve lem ûled, ve lem yekün lî küf'en ehad.",
      "Ben, tek ve Samed'im. Ne doğdum, ne de çocuğum oldu. Benim hiçbir dengim yoktur.",
      alinti="Ben, tek ve samedim. Ne doğdum, ne de çocuğum oldu. Benim hiçbir dengim yoktur")
hadis("h-4968", "Rükû ve secdede", PD, 4968, ("سبحانك اللهم", "اغفر لي"),
      "Sübhânekellâhümme Rabbenâ ve bi-hamdik, Allâhümmağfir lî.",
      "Allah'ım! Rabbimiz! Seni hamdinle tesbih ederim. Allah'ım! Beni bağışla.",
      alinti="subhaneke Rabbena vebihamdike",
      not_="Hz. Âişe: Resûlullah Nasr sûresindeki emri yerine getirerek rükû ve secdelerinde bunu çok söylerdi.")
hadis("h-6309", "Tevbeye sevinen Rab", HD, 6309, ("الله افرح بتوبه عبده", "فلاه"),
      "Allâhü efrahu bi-tevbeti abdihî min ehadiküm sekata alâ ba'îrihî ve kad edallehû fî ardı felâh.",
      "Allah, kulunun tevbesine, çölde kaybettiği devesini tesadüfen bulan bir adamın sevincinden daha fazla sevinir.",
      alinti="kulunun tevbesine, çölde kaybettiği devesini tesadüfen bulan bir adamın")
hadis("h-7378", "Allah'tan sabırlısı yoktur", HD, 7378, ("ما احد اصبر", "ويرزقهم"),
      "Mâ ehadün asbaru alâ ezen semi'ahû minallâh, yed'ûne lehü'l-veled, sümme yu'âfîhim ve yerzukuhum.",
      "Duyduğu eziyet verici söze karşı Allah'tan daha sabırlı kimse yoktur. İnsanlar O'na çocuk isnat ederler; O ise yine onlara afiyet ve rızık verir.",
      alinti="Allah'tan çok sabırlı değildir",
      not_="Sabûr ismi, Allah'ın cezayı hemen vermeyip mühlet tanımasını anlatır.")

# ——— Kur'an ———
ayet("fatiha-2-3", "Fâtiha'dan", KD, 1, [2, 3], "El-hamdü lillâhi Rabbi'l-âlemîn. Er-Rahmâni'r-Rahîm.",
     "Hamd, Alemlerin Rabbi Allah'a mahsustur. O Rahman ve Rahim'dir")
ayet("fatiha-6", "Fâtiha'dan", KD, 1, [6], "İhdine's-sırâta'l-müstakîm.", "Bizi doğru yola eriştir")
ayet("isra-110", "İster Allah deyin, ister Rahmân", AY, 17, [110],
     "Kulid'ullâhe evid'u'r-Rahmân, eyyen mâ ted'û fe-lehü'l-esmâü'l-hüsnâ.",
     "De ki: İster Allah deyin, ister Rahman deyin, hangisini derseniz deyin, en güzel isimler O'nundur", (0, 12))
ayet("taha-14", "Ben Allah'ım", AY, 20, [14], "İnnenî enallâhü lâ ilâhe illâ ene fa'büdnî ve ekımi's-salâte li-zikrî.",
     "Şüphesiz Ben Allah'ım, Benden başka tanrı yoktur; Bana kulluk et; Beni anmak için namaz kıl")
ayet("muminun-118", "Merhamet edenlerin en hayırlısı", KD, 23, [118], "Rabbiğfir verham ve ente hayru'r-râhimîn.",
     "Rabbim! Bağışla, merhamet et, Sen merhamet edenlerin en hayırlısısın", (1, 6))
ayet("araf-151", "Hz. Mûsâ'nın duası", KD, 7, [151], "Rabbiğfir lî ve li-ahî ve edhılnâ fî rahmetike ve ente erhamu'r-râhimîn.",
     "Rabbim! Beni ve kardeşimi bağışla, bize acı, Sen merhametlilerin merhametlisisin", (1, 10))
ayet("bakara-127", "Hz. İbrâhim ve İsmâil'in duası", KD, 2, [127], "Rabbenâ tekabbel minnâ, inneke ente's-Semî'u'l-Alîm.",
     "Rabbimiz! Yaptığımızı kabul buyur. Şüphesiz ki, Sen hem işitir hem bilirsin", (7, 13))
ayet("bakara-128", "Hz. İbrâhim ve İsmâil'in duası", KD, 2, [128],
     "Rabbenâ vec'alnâ müslimeyni leke ve min zürriyyetinâ ümmeten müslimeten lek, ve erinâ menâsikenâ ve tüb aleynâ, inneke ente't-Tevvâbu'r-Rahîm.",
     "Rabbimiz! İkimizi Sana teslim olanlardan kıl, soyumuzdan da Sana teslim olanlardan bir ümmet yetiştir. Bize ibadet yollarımızı göster, tevbemizi kabul buyur, çünkü tevbeleri daima kabul eden, merhametli olan ancak Sensin")
ayet("bakara-129", "Hz. İbrâhim ve İsmâil'in duası", KD, 2, [129],
     "Rabbenâ veb'as fîhim rasûlen minhüm yetlû aleyhim âyâtike ve yü'allimühümü'l-kitâbe ve'l-hikmete ve yüzekkîhim, inneke ente'l-Azîzü'l-Hakîm.",
     "Rabbimiz! İçlerinden onlara Senin ayetlerini okuyan, Kitabı ve hikmeti öğreten, onları her kötülükten arıtan bir peygamber gönder. Doğrusu güçlü ve Hakim olan ancak Sensin")
ayet("mumtehine-5", "Hz. İbrâhim ve beraberindekilerin duası", KD, 60, [5],
     "Rabbenâ lâ tec'alnâ fitneten lillezîne keferû vağfir lenâ Rabbenâ, inneke ente'l-Azîzü'l-Hakîm.",
     "Rabbimiz! Bizi, inkar edenlerle deneme; bizi bağışla, doğrusu Sen, güçlü olan, Hakim olansın")
ayet("maide-118", "Hz. Îsâ'nın sözü", AY, 5, [118],
     "İn tu'azzibhüm fe-innehüm ibâdük, ve in tağfir lehüm fe-inneke ente'l-Azîzü'l-Hakîm.",
     "Onlara azabedersen, doğrusu onlar Senin kullarındır; onları bağışlarsan, Güçlü olan, Hakim olan şüphesiz ancak Sensin")
ayet("aliimran-8", "Kalplerimizi kaydırma", KD, 3, [8],
     "Rabbenâ lâ tüziğ kulûbenâ ba'de iz hedeytenâ ve heb lenâ min ledünke rahmeh, inneke ente'l-Vehhâb.",
     "Rabbimiz! Bizi doğru yola erdirdikten sonra kalblerimizi eğriltme, katından bize rahmet bağışla; şüphesiz Sen sonsuz bağışta bulunansın")
ayet("aliimran-9", "Toplayacak olan Sensin", KD, 3, [9],
     "Rabbenâ inneke câmi'u'n-nâsi li-yevmin lâ raybe fîh, innallâhe lâ yuhlifü'l-mî'âd.",
     "Rabbimiz! Doğrusu geleceği şüphe götürmeyen günde, insanları toplayacak olan Sensin. Şüphesiz ki Allah verdiği sözden caymaz")
ayet("sad-35", "Hz. Süleyman'ın duası", KD, 38, [35],
     "Rabbiğfir lî ve heb lî mülken lâ yenbeğî li-ehadin min ba'dî, inneke ente'l-Vehhâb.",
     "Rabbim! Beni bağışla, bana benden sonra kimsenin ulaşamayacağı bir hükümranlık ver; Sen şüphesiz, daima bağışta bulunansın", (1, 15))
ayet("aliimran-26", "Mülkün sahibi Allah'ım", KD, 3, [26],
     "Allâhümme mâlike'l-mülki tü'ti'l-mülke men teşâü ve tenzi'u'l-mülke mimmen teşâ', ve tu'izzü men teşâü ve tüzillü men teşâ', bi-yedike'l-hayr, inneke alâ külli şey'in kadîr.",
     "Mülkün sahibi olan Allah'ım! Mülkü dilediğine verirsin; dilediğinden çekip alırsın; dilediğini aziz kılar, dilediğini alçaltırsın; iyilik elindedir. Doğrusu Sen, her şeye Kadir'sin", (1, 24),
     not_="Muizz (aziz kılan) ve Müzill (alçaltan) isimleri bu âyetteki fiillerdendir.")
ayet("araf-89", "Hz. Şuayb'ın duası", KD, 7, [89],
     "Rabbeneftah beynenâ ve beyne kavminâ bi'l-hakkı ve ente hayru'l-fâtihîn.",
     "Rabbimiz! Bizimle milletimiz arasında hak ile Sen hüküm ver, Sen hükmedenlerin en hayırlısısın", (33, 41))
ayet("araf-155", "Hz. Mûsâ'nın duası", KD, 7, [155],
     "Ente veliyyünâ fağfir lenâ verhamnâ ve ente hayru'l-ğâfirîn.",
     "bizim dostumuz Sensin; bizi bağışla, bize merhamet et. Sen bağışlayanların en iyisisin", (34, 41))
ayet("yusuf-101", "Hz. Yûsuf'un duası", KD, 12, [101],
     "Fâtıra's-semâvâti ve'l-ard, ente veliyyî fi'd-dünyâ ve'l-âhirah, teveffenî müslimen ve elhıknî bi's-sâlihîn.",
     "Ey göklerin ve yerin yaradanı! Dünya ve ahirette işlerimi yoluna koyan sensin; benim canımı müslüman olarak al ve beni iyilere kat", (9, 21))
ayet("bakara-286", "Bakara'nın son duası", KD, 2, [286],
     "Rabbenâ lâ tüâhıznâ in nesînâ ev ahta'nâ, Rabbenâ ve lâ tahmil aleynâ ısran kemâ hameltehû alellezîne min kablinâ, Rabbenâ ve lâ tühammilnâ mâ lâ tâkate lenâ bih, va'fü annâ vağfir lenâ verhamnâ, ente mevlânâ fensurnâ ale'l-kavmi'l-kâfirîn.",
     "Rabbimiz! Eğer unutacak veya yanılacak olursak bizi sorumlu tutma. Rabbimiz bizden öncekilere yüklediğin gibi, bize de ağır yük yükleme. Rabbimiz! Bize gücümüzün yetmeyeceği şeyi taşıtma, bizi affet, bizi bağışla, bize acı. Sen Mevlamızsın, kafirlere karşı bize yardım et", (12, None),
     not_="Bakara'nın son iki âyetini bir gecede okuyana bu iki âyet yeter.",
     buhari=(5009, "Her kim bir gecede Bakara suresinin sonundaki iki ayeti okursa, bu iki ayet ona yeter"))
ayet("enbiya-89", "Hz. Zekeriyyâ'nın duası", KD, 21, [89], "Rabbi lâ tezernî ferden ve ente hayru'l-vârisîn.",
     "Rabbim! Beni tek başıma bırakma, Sen varislerin en hayırlısısın", (4, 11))
ayet("hasr-10", "Bizden öncekiler için", KD, 59, [10],
     "Rabbenağfir lenâ ve li-ihvâninellezîne sebekûnâ bi'l-îmân, ve lâ tec'al fî kulûbinâ ğıllen lillezîne âmenû, Rabbenâ inneke Raûfün Rahîm.",
     "Rabbimiz! Bizi ve bizden önce inanmış olan kardeşlerimizi bağışla; kalbimizde müminlere karşı kin bırakma; Rabbimiz! Şüphesiz Sen şefkatlisin, merhametlisin", (5, 23))
ayet("fatir-34", "Cennet ehlinin hamdi", AY, 35, [34], "El-hamdü lillâhillezî ezhebe anne'l-hazen, inne Rabbenâ le-Ğafûrun Şekûr.",
     "Bizden üzüntüyü gideren Allah'a hamdolsun. Doğrusu Rabbimiz bağışlayandır, şükrün karşılığını verendir", (1, 10))
ayet("tur-28", "Cennet ehlinin sözü", AY, 52, [28], "İnnâ künnâ min kablü ned'ûh, innehû hüve'l-Berru'r-Rahîm.",
     "doğrusu bundan önce de O'na yalvarıyorduk; şüphesiz O, iyilik yapandır, acıyandır")
ayet("mumin-44", "İşimi Allah'a bırakıyorum", AY, 40, [44], "Ve üfevvidu emrî ilallâh, innallâhe basîrun bi'l-ibâd.",
     "Ben işimi Allah'a bırakıyorum. Doğrusu Allah, kulları görür", (4, 11),
     not_="Firavun ailesinden iman eden adamın sözü.")
ayet("maide-117", "Hz. Îsâ'nın sözü", AY, 5, [117], "Fe-lemmâ teveffeytenî künte ente'r-Rakîbe aleyhim, ve ente alâ külli şey'in Şehîd.",
     "beni aralarından aldığında onları Sen gözlüyordun. Sen her şeye şahidsin", (19, 29))
ayet("yusuf-64", "Hz. Ya'kûb'un tevekkülü", AY, 12, [64], "Fallâhü hayrun hâfizâ, ve hüve erhamu'r-râhimîn.",
     "Allah en iyi koruyandır, O merhametlilerin merhametlisidir", (11, 17))
ayet("hud-57", "Hz. Hûd'un sözü", AY, 11, [57], "İnne Rabbî alâ külli şey'in hafîz.",
     "Doğrusu Rabbim herşeyi koruyandır", (15, 20))
ayet("neml-40", "Hz. Süleyman'ın şükrü", AY, 27, [40],
     "Hâzâ min fadli Rabbî li-yeblüvenî e-eşküru em ekfür, ve men şekera fe-innemâ yeşküru li-nefsih, ve men kefera fe-inne Rabbî Ğaniyyün Kerîm.",
     "Bu, şükür mü edeceğim yoksa nankörlük mü edeceğim diye beni sınayan Rabbimin lütfundandır. Şükreden ancak kendisi için şükretmiş olur; fakat nankörlük eden bilsin ki Rabbim müstağnidir, kerem sahibidir", (19, 37))
ayet("furkan-31", "Yol gösterici olarak Rabbin yeter", AY, 25, [31], "Ve kefâ bi-Rabbike hâdiyen ve nasîrâ.",
     "Doğruyu gösterici ve yardımcı olarak, Rabbin yeter", (8, 13))
ayet("siir-78-82", "Hz. İbrâhim'in Rabbini anışı", AY, 26, [78, 79, 80, 81, 82],
     "Ellezî halakanî fe-hüve yehdîn. Vellezî hüve yut'imunî ve yeskîn. Ve izâ maridtü fe-hüve yeşfîn. Vellezî yümîtünî sümme yuhyîn. Vellezî atme'u en yağfira lî hatîetî yevme'd-dîn.",
     "Beni yaratan da, doğru yola eriştiren de O'dur. Beni yediren de, içiren de O'dur. Hasta olduğumda bana O şifa verir. Beni öldürecek, sonra da diriltecek O'dur. Ahiret gününde yanılmalarımı bana bağışlamasını umduğum O'dur")
ayet("mumin-65", "O'na yalvarın", AY, 40, [65],
     "Hüve'l-Hayyu lâ ilâhe illâ hüve fed'ûhü muhlisîne lehü'd-dîn, el-hamdü lillâhi Rabbi'l-âlemîn.",
     "O diridir, O'ndan başka tanrı yoktur. Dini yalnız O'na has kılarak O'na yalvarın. Övgü, Alemlerin Rabbi Allah içindir")
ayet("ayetel-kursi", "Âyetü'l-Kürsî", AY, 2, [255],
     "Allâhü lâ ilâhe illâ hüve'l-Hayyu'l-Kayyûm, lâ te'huzühû sinetün ve lâ nevm, lehû mâ fi's-semâvâti ve mâ fi'l-ard, men zellezî yeşfeu indehû illâ bi-iznih, ya'lemü mâ beyne eydîhim ve mâ halfehüm, ve lâ yuhîtûne bi-şey'in min ilmihî illâ bi-mâ şâ', vesia kürsiyyühü's-semâvâti ve'l-ard, ve lâ yeûdühû hıfzuhümâ, ve hüve'l-Aliyyü'l-Azîm.",
     "Allah, O'ndan başka tanrı olmayan, kendisini uyuklama ve uyku tutmayan, diri, her an yaratıklarını gözetip durandır. Göklerde olan ve yerde olan ancak O'nundur. O'nun izni olmadan katında şefaat edecek kimdir? Onların işlediklerini ve işleyeceklerini bilir, dilediğinden başka ilminden hiçbir şeyi kavrayamazlar. Hükümranlığı gökleri ve yeri kaplamıştır, onların gözetilmesi O'na ağır gelmez. O yücedir, büyüktür",
     not_="Yatağa girerken okuyan sabaha kadar korunur.",
     buhari=(5010, "Yatağına girdiğin vakit, ayete'l-kürsi'yi oku"))
ayet("aliimran-2", "Hayy ve Kayyûm", AY, 3, [2], "Allâhü lâ ilâhe illâ hüve'l-Hayyu'l-Kayyûm.",
     "Allah, Ondan başka tanrı olmayan, diri, her an yaratıklarını gözetip durandır")
ayet("ihlas", "İhlâs sûresi", AY, 112, [1, 2, 3, 4],
     "Kul hüvallâhü ehad. Allâhü's-samed. Lem yelid ve lem yûled. Ve lem yekün lehû küfüven ehad.",
     "De ki: O Allah bir tektir. Allah her şeyden müstağni ve her şey O'na muhtaçtır. O doğurmamış ve doğmamıştır. Hiçbir şey O'na denk değildir",
     not_="Resûlullah bu sûrenin Kur'an'ın üçte birine denk olduğunu söyledi.",
     buhari=(5013, "bu sure Kur'an'ın üçte birine denktir"))
ayet("bakara-163", "Tek Tanrı", AY, 2, [163], "Ve ilâhüküm ilâhün vâhid, lâ ilâhe illâ hüve'r-Rahmânü'r-Rahîm.",
     "Tanrınız bir tek Tanrıdır. O, merhamet eden, merhametli olandan başka Tanrı yoktur")
ayet("rad-16", "Her şeyin yaratıcısı", AY, 13, [16], "Kulillâhü hâliku külli şey'in ve hüve'l-Vâhidü'l-Kahhâr.",
     "De ki: Her şeyi yaratan Allah'tır. O, her şeye üstün gelen tek Tanrı'dır", (39, 46))
ayet("yusuf-39", "Hz. Yûsuf'un zindan arkadaşlarına sözü", AY, 12, [39],
     "Yâ sâhibeyi's-sicni e-erbâbün müteferrikûne hayrun emillâhü'l-Vâhidü'l-Kahhâr.",
     "Ey mahpus arkadaşlarım! Ayrı ayrı bir sürü uydurma rabler mi daha iyidir, yoksa her şeyden üstün tek Allah mı")
ayet("hasr-22-24", "Haşr'ın son âyetleri", AY, 59, [22, 23, 24],
     "Hüvallâhüllezî lâ ilâhe illâ hû, âlimü'l-ğaybi ve'ş-şehâdeh, hüve'r-Rahmânü'r-Rahîm. Hüvallâhüllezî lâ ilâhe illâ hû, el-Melikü'l-Kuddûsü's-Selâmü'l-Mü'minü'l-Müheyminü'l-Azîzü'l-Cebbârü'l-Mütekebbir, sübhânallâhi ammâ yüşrikûn. Hüvallâhü'l-Hâliku'l-Bâriü'l-Musavviru lehü'l-esmâü'l-hüsnâ, yüsebbihu lehû mâ fi's-semâvâti ve'l-ard, ve hüve'l-Azîzü'l-Hakîm.",
     "O, görüleni de görülmeyeni de bilen, kendisinden başka tanrı olmayan Allah'tır. O, acıyıcı olandır, acıyandır. O, kendisinden başka tanrı olmayan, hükümran, çok kutsal; esenlik veren, güvenlik veren, görüp gözeten, güçlü, buyruğunu herşeye geçiren, ulu olan, Allah'tır. Allah onların koştukları eşlerden (ortaklardan) münezzehtir. O, vareden, güzel yaratan, yarattıklarına şekil veren, en güzel adlar kendisinin olan Allah'tır. Göklerde ve yerde olanlar O'nu tesbih ederler. O güçlüdür, Hakim'dir")
ayet("hadid-2-3", "Evvel ve Âhir O'dur", AY, 57, [2, 3],
     "Lehû mülkü's-semâvâti ve'l-ard, yuhyî ve yümît, ve hüve alâ külli şey'in kadîr. Hüve'l-Evvelü ve'l-Âhiru ve'z-Zâhiru ve'l-Bâtın, ve hüve bi-külli şey'in alîm.",
     "Göklerin ve yerin hükümranlığı O'nundur; diriltir, öldürür. O, her şeye Kadir'dir. O her şeyden öncedir; kendisinden sonraya hiçbir şeyin kalmayacağı son'dur; varlığı aşikardır; gerçek mahiyeti insan için gizlidir. O her şeyi bilir")
ayet("rahman-26-27", "Bâki olan yalnız O", AY, 55, [26, 27], "Küllü men aleyhâ fân. Ve yebkâ vechü Rabbike zü'l-celâli ve'l-ikrâm.",
     "Yeryüzünde bulunan her şey fanidir. Ancak, yüce ve cömert olan Rabbinin varlığı bakidir",
     not_="Celîl ismi, âyetteki “celâl” (ululuk) kelimesiyle aynı köktendir.")
ayet("rahman-78", "Rahmân sûresinin sonu", AY, 55, [78], "Tebârakesmü Rabbike zi'l-celâli ve'l-ikrâm.",
     "Büyük ve pek cömert olan Rabbinin adı ne yücedir")
ayet("zariyat-58", "Rızık veren O'dur", AY, 51, [58], "İnnallâhe hüve'r-Rezzâku zü'l-kuvveti'l-Metîn.",
     "Şüphesiz rızıklandıran da, güç ve kuvvet sahibi olan da Allah'tır")
ayet("maide-114", "Hz. Îsâ'nın duası", KD, 5, [114],
     "Allâhümme Rabbenâ enzil aleynâ mâideten mine's-semâi tekûnü lenâ îden li-evvelinâ ve âhirinâ ve âyeten mink, verzuknâ ve ente hayru'r-râzıkîn.",
     "Allahım! Rabbimiz! Bize ve bizden sonra geleceklere bayram ve Sen'den bir delil olarak gökten bir sofra indir, bizi rızıklandır, Sen rızık verenlerin en hayırlısısın", (4, 22))
ayet("kureys-3-4", "Doyuran ve güven veren", AY, 106, [3, 4], "Felya'büdû Rabbe hâze'l-beyt. Ellezî at'amehüm min cû'in ve âmenehüm min havf.",
     "kendilerini açken doyuran ve korku içindeyken güven veren bu Ev'in (Kabe'nin) Rabbine kulluk etsinler",
     not_="Mü'min ismi, âyetteki “âmenehüm” (güven verdi) fiiliyle aynı köktendir.")
ayet("sebe-26", "Fettâh ve Alîm", AY, 34, [26], "Kul yecma'u beynenâ Rabbünâ sümme yeftehu beynenâ bi'l-hakk, ve hüve'l-Fettâhu'l-Alîm.",
     "De ki: Rabbimiz sonunda hepimizi toplar, sonra aramızda adaletle hükmeder. Adaletle hükmeden, bilen ancak O'dur")
ayet("fatir-2", "Açtığı rahmeti kimse tutamaz", AY, 35, [2],
     "Mâ yeftehillâhü li'n-nâsi min rahmetin fe-lâ mümsike lehâ, ve mâ yümsik fe-lâ mürsile lehû min ba'dih, ve hüve'l-Azîzü'l-Hakîm.",
     "Allah'ın insanlara verdiği rahmeti önleyebilecek yoktur. O'nun önlediğini de ardından salıverecek yoktur. O, güçlü'dür, Hakim'dir")
ayet("buruc-13-15", "Başlatan ve tekrar eden", AY, 85, [13, 14, 15], "İnnehû hüve yübdiu ve yuîd. Ve hüve'l-Ğafûru'l-Vedûd. Zü'l-arşi'l-mecîd.",
     "Önce yaratıp sonra bunu tekrar eden O'dur. Yüce arşın sahibi, çok seven, bağışlayan O'dur")
ayet("rum-27", "Yaratmayı tekrar eden", AY, 30, [27],
     "Ve hüvellezî yebdeü'l-halka sümme yuîdühû ve hüve ehvenü aleyh, ve lehü'l-meselü'l-a'lâ fi's-semâvâti ve'l-ard, ve hüve'l-Azîzü'l-Hakîm.",
     "Önce yaratan, ölümünden sonra tekrar dirilten O'dur. Bu, O'nun için daha kolaydır. Göklerde ve yerde olan en üstün sıfatlar O'nundur. O, güçlüdür, Hakim'dir")
ayet("rad-9", "Kebîr ve Müteâl", AY, 13, [9], "Âlimü'l-ğaybi ve'ş-şehâdeti'l-Kebîru'l-Müte'âl.",
     "Görüleni de görülmeyeni de bilen, yücelerin yücesi büyük Allah")
ayet("rad-11", "Bir millet kendini değiştirmedikçe", AY, 13, [11],
     "İnnallâhe lâ yuğayyiru mâ bi-kavmin hattâ yuğayyirû mâ bi-enfüsihim, ve izâ erâdallâhü bi-kavmin sûen fe-lâ meradde leh, ve mâ lehüm min dûnihî min vâl.",
     "Bir millet kendini bozmadıkça Allah onların durumunu değiştirmez. Allah bir milletin fenalığını dileyince artık onun önüne geçilmez. Onlar için Allah'tan başka hamide bulunmaz", (11, 35),
     not_="Vâlî ismi âyetin sonundaki “vâl” (işleri üstlenen, koruyan) kelimesidir.")
ayet("sura-19", "Kullarına lütufkâr", AY, 42, [19], "Allâhü latîfün bi-ibâdihî yerzuku men yeşâ', ve hüve'l-Kaviyyü'l-Azîz.",
     "Allah, kullarına lütufta bulunandır. Dilediğini rızıklandırır. Kuvvetli olan da güçlü olan da O'dur")
ayet("sura-11", "O'nun benzeri yoktur", AY, 42, [11], "Leyse ke-mislihî şey', ve hüve's-Semî'u'l-Basîr.",
     "O'nun benzeri hiçbir şey yoktur. O, işitendir, görendir", (15, 20))
ayet("bakara-117", "Gökleri ve yeri yoktan var eden", AY, 2, [117],
     "Bedî'u's-semâvâti ve'l-ard, ve izâ kadâ emran fe-innemâ yekûlü lehû kün fe-yekûn.",
     "Gökleri ve yeri yoktan var eden Allah'tır. O, bir işin olmasını dilerse, ona ancak \"ol\" der ve olur")
ayet("nur-35", "Göklerin ve yerin nuru", AY, 24, [35], "Allâhü nûru's-semâvâti ve'l-ard.",
     "Allah göklerin ve yerin Nur'udur", (0, 3))
ayet("tahrim-8", "Mü'minlerin âhiretteki duası", KD, 66, [8],
     "Rabbenâ etmim lenâ nûranâ vağfir lenâ, inneke alâ külli şey'in kadîr.",
     "Rabbimiz! Işığımızı tamamla, bizi bağışla, doğrusu Sen herşeye Kadir'sin", (34, 44))
ayet("bakara-245", "Daraltan ve genişleten", AY, 2, [245], "Vallâhü yakbizu ve yebsutu ve ileyhi turce'ûn.",
     "Allah hem darlaştırır, hem bollaştırır; O'na döneceksiniz", (13, 17),
     not_="Kâbız ve Bâsıt isimleri âyetteki “yakbizu” ve “yebsutu” fiillerindendir.")
ayet("bakara-186", "Ben yakınım", AY, 2, [186],
     "Ve izâ seeleke ibâdî annî fe-innî karîb, ücîbü da'vete'd-dâ'i izâ de'ân, fe'l-yestecîbû lî ve'l-yü'minû bî leallehüm yerşüdûn.",
     "Kullarım sana Beni sorarlarsa, bilsinler ki Ben, şüphesiz onlara yakınım. Benden isteyenin, dua ettiğinde duasını kabul ederim. Artık onlar da davetimi kabul edip Bana inansınlar ki doğru yolda yürüyenlerden olsunlar")
ayet("hud-61", "Hz. Sâlih'in sözü", AY, 11, [61], "Festağfirûhü sümme tûbû ileyh, inne Rabbî karîbün mücîb.",
     "Öyleyse O'ndan mağfiret dileyin, sonra da O'na tevbe edin. Doğrusu Rabbim size yakın ve duaları kabul edendir", (20, 27))
ayet("hud-90", "Hz. Şuayb'ın sözü", AY, 11, [90], "Vestağfirû Rabbeküm sümme tûbû ileyh, inne Rabbî rahîmün vedûd.",
     "Rabbinizden mağfiret dileyin; O'na tevbe edin; doğrusu Rabbim merhamet eder ve çok sever")
ayet("hud-73", "Meleklerin Hz. İbrâhim'in ailesine sözü", AY, 11, [73],
     "Kâlû e-ta'cebîne min emrillâh, rahmetullâhi ve berakâtühû aleyküm ehle'l-beyt, innehû hamîdün mecîd.",
     "Ey evin hanımı! Allah'ın rahmeti ve bereketleri üzerinize olmuşken, nasıl Allah'ın işine şaşarsın? O, övülmeye layıktır, yücelerin yücesidir",
     not_="Mâcid ismi, Mecîd ile aynı kökten, şanı yüce demektir.")
ayet("yusuf-100", "Hz. Yûsuf'un sözü", AY, 12, [100], "İnne Rabbî latîfün limâ yeşâ', innehû hüve'l-Alîmü'l-Hakîm.",
     "Doğrusu Rabbim dilediğine lütufkardır, O şüphesiz bilendir, Hakim'dir", (39, 47))
ayet("enam-103", "Gözler O'nu idrak edemez", AY, 6, [103], "Lâ tüdrikühü'l-ebsâru ve hüve yüdrikü'l-ebsâr, ve hüve'l-Latîfü'l-Habîr.",
     "Gözler O'nu görmez, O bütün gözleri görür. O Latif'tir, haberdardır")
ayet("bakara-32", "Meleklerin sözü", KD, 2, [32], "Sübhâneke lâ ilme lenâ illâ mâ allemtenâ, inneke ente'l-Alîmü'l-Hakîm.",
     "Sen münezzehsin, öğrettiğinden başka bizim bir bilgimiz yoktur. Şüphesiz Sen hem bilensin, hem Hakim'sin", (1, 11))
ayet("mumin-7", "Arşı taşıyan meleklerin duası", KD, 40, [7],
     "Rabbenâ vesi'te külle şey'in rahmeten ve ilmen fağfir lillezîne tâbû vetteba'û sebîleke ve kıhim azâbe'l-cahîm.",
     "Rabbimiz! İlmin ve rahmetin herşeyi içine almıştır. Tevbe edip Senin yoluna uyanları bağışla; onları cehennemin azabından koru", (13, 27))
ayet("zumer-46", "Hükmü veren Sensin", KD, 39, [46],
     "Allâhümme fâtıra's-semâvâti ve'l-ard, âlime'l-ğaybi ve'ş-şehâdeh, ente tahkümü beyne ibâdike fî mâ kânû fîhi yahtelifûn.",
     "Ey göklerin, yerin yaratanı, görülmeyeni ve görüleni bilen Allah'ım! Kullarının ayrılığa düştükleri şeyler hakkında aralarında Sen hükmedeceksin", (1, 16))
ayet("enam-115", "Doğruluk ve adaletle", AY, 6, [115],
     "Ve temmet kelimetü Rabbike sıdkan ve adlâ, lâ mübeddile li-kelimâtih, ve hüve's-Semî'u'l-Alîm.",
     "Rabbinin sözü, doğruluk ve adaletle tamamlandı. O'nun sözlerini değiştirebilecek yoktur. O, işitir ve bilir")
ayet("aliimran-18", "Adaleti ayakta tutan", AY, 3, [18],
     "Şehidallâhü ennehû lâ ilâhe illâ hüve ve'l-melâiketü ve ülü'l-ilmi kâimen bi'l-kıst, lâ ilâhe illâ hüve'l-Azîzü'l-Hakîm.",
     "Allah, melekler ve adaleti yerine getiren ilim sahibleri, O'ndan başka tanrı olmadığına şahidlik etmişlerdir. O'ndan başka tanrı yoktur, O güçlüdür, Hakim'dir",
     not_="Muksit ismi, âyetteki “kıst” (adalet) kelimesiyle aynı köktendir.")
ayet("enbiya-83", "Hz. Eyyûb'un duası", KD, 21, [83], "Ennî messeniye'd-durru ve ente erhamu'r-râhimîn.",
     "Başıma bir bela geldi, (Sana sığındım), Sen merhametlilerin merhametlisisin", (4, 9),
     not_="Dârr ismi, âyetteki “durr” (sıkıntı) ile aynı köktendir; sıkıntıyı veren de kaldıran da O'dur.")
ayet("yunus-107", "Zararı ancak O giderir", AY, 10, [107],
     "Ve in yemseskellâhü bi-durrin fe-lâ kâşife lehû illâ hû, ve in yüridke bi-hayrin fe-lâ râdde li-fadlih, yusîbü bihî men yeşâü min ibâdih, ve hüve'l-Ğafûru'r-Rahîm.",
     "Allah sana bir sıkıntı verirse, onu O'ndan başkası gideremez. Sana bir iyilik dilerse O'nun nimetini engelleyecek yoktur. O'nu kullarından dilediğine verir. O, bağışlayandır, merhametlidir")
ayet("aliimran-173", "Allah bize yeter", KD, 3, [173], "Hasbünallâhü ve ni'me'l-vekîl.",
     "Allah bize yeter. O ne güzel Vekil'dir", (14, 17),
     not_="Hz. İbrâhim ateşe atılırken, Hz. Muhammed de düşman ordusu haberi gelince bunu söyledi.",
     buhari=(4563, "hasbunallahu ve ni'me'l-vekil"))
ayet("tevbe-129", "Allah bana yeter", KD, 9, [129], "Hasbiyallâhü lâ ilâhe illâ hû, aleyhi tevekkeltü ve hüve Rabbü'l-arşi'l-azîm.",
     "Allah bana yeter; O'ndan başka tanrı yoktur, yalnız O'na güveniyorum; O büyük arşın Rabbidir", (3, 14))
ayet("kamer-55", "Muktedir hükümdarın katında", AY, 54, [55], "Fî mak'adi sıdkın inde melîkin muktedir.",
     "güçlü hükümdarın katında, yüksek bir derecede")
ayet("kehf-45", "Her şeye gücü yeten", AY, 18, [45], "Ve kânallâhü alâ külli şey'in muktedirâ.",
     "Allah her şeyin üstünde bir kudrete sahip olandır", (18, 23))
ayet("nisa-85", "Her şeyin karşılığını veren", AY, 4, [85], "Ve kânallâhü alâ külli şey'in mukîtâ.",
     "Allah, her şeyin karşılığını verir", (16, 22))
ayet("ahzab-39", "Hesap gören olarak Allah yeter", AY, 33, [39],
     "Ellezîne yübelliğûne risâlâtillâhi ve yahşevnehû ve lâ yahşevne ehaden illallâh, ve kefâ billâhi hasîbâ.",
     "Allah'ın göndermiş olduklarını tebliğ edenler, Allah'tan korkarlar ve O'ndan başka kimseden korkmazlar. Allah hesap gören olarak yeter")
ayet("hac-7", "Kabirdekileri diriltecek", AY, 22, [7], "Ve enne's-sâate âtiyetün lâ raybe fîhâ, ve ennallâhe yeb'asü men fi'l-kubûr.",
     "şüphe götürmeyen kıyamet saatinin geleceğini, Allah'ın kabirlerde olanı dirilteceğini",
     not_="Bâis ismi, âyetteki “yeb'asü” (diriltir) fiiliyle aynı köktendir.")
ayet("cin-28", "Her şeyi bir bir saymış", AY, 72, [28], "Ve ehâta bi-mâ ledeyhim ve ahsâ külle şey'in adedâ.",
     "onların yaptıklarını ilmiyle kuşatır ve herşeyi bir bir sayar", (6, 12),
     not_="Muhsî ismi, âyetteki “ahsâ” (saydı) fiiliyle aynı köktendir.")
ayet("duha-6-8", "Seni bulup da", AY, 93, [6, 7, 8], "E-lem yecidke yetîmen fe-âvâ. Ve vecedeke dâllen fe-hedâ. Ve vecedeke âilen fe-ağnâ.",
     "Seni öksüz bulup da barındırmadı mı? Seni şaşırmış bulup, doğru yola eriştirmedi mi? Seni fakir bulup zenginleştirmedi mi",
     not_="Vâcid ismi “vecede” (buldu), Muğnî ismi “ağnâ” (zenginleştirdi) fiilleriyle aynı köktendir.")
ayet("necm-48", "Zengin eden O'dur", AY, 53, [48], "Ve ennehû hüve ağnâ ve aknâ.", "Doğrusu zengin eden de varlıklı kılan da O'dur")
ayet("kasas-24", "Hz. Mûsâ'nın duası", KD, 28, [24], "Rabbi innî limâ enzelte ileyye min hayrin fakîr.",
     "Rabbim! Doğrusu bana indireceğin hayra muhtacım", (7, 14))
ayet("fatir-15", "Siz Allah'a muhtaçsınız", AY, 35, [15], "Yâ eyyühe'n-nâsü entümü'l-fükarâü ilallâh, vallâhü hüve'l-Ğaniyyü'l-Hamîd.",
     "Ey insanlar! Siz Allah'a muhtaçsınız, Allah ise müstağnidir, övülmeğe layık olandır")
ayet("nas-1-3", "Nâs sûresinden", KD, 114, [1, 2, 3], "Kul e'ûzü bi-Rabbi'n-nâs. Meliki'n-nâs. İlâhi'n-nâs.",
     "insanların Tanrısı, insanların Hükümranı ve insanların Rabbi olan Allah'a sığınırım",
     not_="Resûlullah her gece yatarken İhlâs, Felak ve Nâs'ı okuyup avuçlarına üflerdi.",
     buhari=(5017, "kul euzu bi Rabbi'n-nas (Nas suresini) okurdu"))
ayet("taha-114", "Rabbim, ilmimi artır", KD, 20, [114],
     "Fe-teâlallâhü'l-Melikü'l-Hakk, ve lâ ta'cel bi'l-kur'âni min kabli en yukdâ ileyke vahyüh, ve kul Rabbi zidnî ilmâ.",
     "Gerçek hükümdar olan Allah Yüce'dir. Kuran sana vahyedilirken, vahy bitmezden önce, unutmamak için, tekrarda acele edip durma, \"Rabbim! ilmimi artır\" de")
ayet("muminun-116", "Kerîm arşın Rabbi", AY, 23, [116], "Fe-teâlallâhü'l-Melikü'l-Hakk, lâ ilâhe illâ hû, Rabbü'l-arşi'l-kerîm.",
     "Gerçek hükümdar olan Allah yücedir. O'ndan başka tanrı yoktur. O, yüce arşın Rabbidir")
ayet("hac-62", "Hak O'dur", AY, 22, [62],
     "Zâlike bi-ennallâhe hüve'l-hakku ve enne mâ yed'ûne min dûnihî hüve'l-bâtılu ve ennallâhe hüve'l-Aliyyü'l-Kebîr.",
     "Keza Hak yalnız Allah'tır; O'nu bırakıp taptıkları sadece batıldır. Doğrusu Allah yücedir büyüktür")
ayet("cuma-1", "Kuddûs olan Allah'ı tesbih", AY, 62, [1],
     "Yüsebbihu lillâhi mâ fi's-semâvâti ve mâ fi'l-ardı'l-Meliki'l-Kuddûsi'l-Azîzi'l-Hakîm.",
     "Göklerde olanlar ve yerde bulunanlar, hükümran, çok kutsal, güçlü ve Hakim olan Allah'ı tesbih ederler")
ayet("enbiya-87", "Hz. Yûnus'un duası", KD, 21, [87], "Lâ ilâhe illâ ente sübhâneke innî küntü mine'z-zâlimîn.",
     "Senden başka tanrı yoktur, Sen münezzehsin, doğrusu ben haksızlık edenlerdenim", (15, 23),
     not_="Kuddûs, her eksiklikten münezzeh demektir; “sübhâneke” bu tenzihin ifadesidir.")
ayet("aliimran-6", "Rahimlerde şekil veren", AY, 3, [6], "Hüvellezî yusavvirukum fi'l-erhâmi keyfe yeşâ', lâ ilâhe illâ hüve'l-Azîzü'l-Hakîm.",
     "Ana rahminde sizi dilediği gibi şekillendiren O'dur. O'ndan başka tanrı yoktur, güçlüdür, Hakim'dir")
ayet("casiye-37", "Büyüklük O'nundur", AY, 45, [37], "Ve lehü'l-kibriyâü fi's-semâvâti ve'l-ard, ve hüve'l-Azîzü'l-Hakîm.",
     "Göklerde ve yerde azamet O'nundur, O, güçlüdür, Hakim'dir")
ayet("bakara-54", "Yaratanınıza tevbe edin", AY, 2, [54], "Fe-tûbû ilâ bâriiküm.", "Yaratanınıza tevbe edin", (10, 12))
ayet("mucadele-11", "Derecelerle yükseltir", AY, 58, [11], "Yerfe'illâhüllezîne âmenû minküm vellezîne ûtü'l-ilme derecât.",
     "Allah, içinizden inanmış olanları ve kendilerine ilim verilenleri derecelerle yükseltsin", (17, 25))
ayet("fatir-10", "İzzet bütünüyle Allah'ındır", AY, 35, [10],
     "Men kâne yürîdü'l-izzete fe-lillâhi'l-izzetü cemî'â, ileyhi yas'adü'l-kelimü't-tayyibü ve'l-amelü's-sâlihu yerfe'uh.",
     "Kudret isteyen kimse bilsin ki, kudret, bütünüyle Allah'ındır. Güzel sözler O'na yükselir, o sözleri de yararlı iş yükseltir", (0, 13))
ayet("zumer-37", "İntikam sahibi", AY, 39, [37], "Ve men yehdillâhü fe-mâ lehû min mudill, e-leysallâhü bi-azîzin zi'ntikâm.",
     "Allah'ın doğru yola eriştirdiğini de saptıracak yoktur. Allah, güçlü olan, öç alabilen değil midir")
ayet("ibrahim-47", "Sözünden caymaz", AY, 14, [47], "Fe-lâ tahsebennallâhe muhlife va'dihî rusuleh, innallâhe azîzün zü'ntikâm.",
     "sakın Allah'ın peygamberlerine verdiği sözden cayacağını sanma; doğrusu Allah güçlüdür, öç alandır",
     not_="Müntekim, zulmün karşılığını adaletle veren demektir.")
ayet("nasr-3", "Nasr sûresinden", AY, 110, [3], "Fe-sebbih bi-hamdi Rabbike vestağfirh, innehû kâne tevvâbâ.",
     "Rabbini överek tesbih et; O'ndan bağışlama dile, çünkü O, tevbeleri daima kabul edendir")
ayet("bakara-37", "Hz. Âdem'in tevbesi", AY, 2, [37], "Fe-telakkâ Âdemü min Rabbihî kelimâtin fe-tâbe aleyh, innehû hüve't-Tevvâbü'r-Rahîm.",
     "Adem, Rabbi'nden emirler aldı; onları yerine getirdi. Rabb'i de bunun üzerine tevbesini kabul etti. Şüphesiz o tevbeleri daima kabul edendir, merhametli olandır")
ayet("kehf-10", "Ashâb-ı Kehf'in duası", KD, 18, [10], "Rabbenâ âtinâ min ledünke rahmeten ve heyyi' lenâ min emrinâ reşedâ.",
     "Rabbimiz! Katından bize rahmet ver ve işimizde doğruyu göster, bizi başarılı kıl", (6, 16),
     not_="Reşîd ismi, duadaki “reşed” (doğruya ulaştırma) kelimesiyle aynı köktendir.")
ayet("kehf-24", "Doğruya daha yakın olana", KD, 18, [24], "Asâ en yehdiyeni Rabbî li-akrabe min hâzâ raşedâ.",
     "Umulur ki, Rabbim beni doğruya daha yakın olana eriştirir", (9, 17))
ayet("bakara-250", "Bize sabır ver", KD, 2, [250], "Rabbenâ efriğ aleynâ sabran ve sebbit akdâmenâ vensurnâ ale'l-kavmi'l-kâfirîn.",
     "Rabbimiz! Bize sabır ver, sebatımızı artır, inkar eden millete karşı bize yardım et", (5, 15))
ayet("araf-126", "İman eden sihirbazların duası", KD, 7, [126], "Rabbenâ efriğ aleynâ sabran ve teveffenâ müslimîn.",
     "Rabbimiz! Bize sabır ver ve canımızı müslim olarak al", (10, 16))
ayet("vakia-74", "Azîm Rabbini tesbih et", AY, 56, [74], "Fe-sebbih bismi Rabbike'l-azîm.", "Öyleyse çok büyük Rabbinin adını tesbih et")
ayet("ala-1", "Yüce Rabbini tesbih et", AY, 87, [1], "Sebbihisme Rabbike'l-a'lâ.", "Yüce Rabbinin adını tesbih et")
ayet("fussilet-53", "Rabbinin şahit olması yetmez mi", AY, 41, [53],
     "Senürîhim âyâtinâ fi'l-âfâkı ve fî enfüsihim hattâ yetebeyyene lehüm ennehü'l-hakk, e-ve lem yekfi bi-Rabbike ennehû alâ külli şey'in şehîd.",
     "Onun hak olduğu meydana çıkıncaya kadar varlığımızın belgelerini onlara hem dış dünyada ve hem de kendi içlerinde göstereceğiz. Rabbinin her şeye şahit olması yetmez mi")
ayet("tegabun-17", "Şekûr ve Halîm", AY, 64, [17],
     "İn tukridullâhe kardan hasenen yudâ'ifhü leküm ve yağfir leküm, vallâhü şekûrun halîm.",
     "Eğer Allah'a güzel bir ödünç takdiminde bulunursanız, onu sizin için kat kat yapar ve sizi bağışlar; Allah, şükrün karşılığını verendir; Halim'dir")
ayet("nisa-149", "Affeden ve gücü yeten", AY, 4, [149],
     "İn tübdû hayran ev tuhfûhü ev ta'fû an sûin fe-innallâhe kâne afüvven kadîrâ.",
     "Bir iyiliği açığa vurur veya gizler yahut bir kötülüğü affederseniz, bilin ki Allah da Affeden'dir, Güçlü Olan'dır")
ayet("kasas-60", "Allah katındaki daha kalıcıdır", AY, 28, [60], "Ve mâ indallâhi hayrun ve ebkâ.",
     "Allah katında olan daha iyi ve devamlıdır", (8, 12))
ayet("nuh-10", "Hz. Nûh'un sözü", AY, 71, [10], "Fe-kultüstağfirû Rabbeküm innehû kâne ğaffârâ.",
     "Rabbinizden bağışlanma dileyin; doğrusu O, çok bağışlayandır")
ayet("taha-82", "Ben çok bağışlayanım", AY, 20, [82], "Ve innî le-ğaffârun limen tâbe ve âmene ve amile sâlihan sümmehtedâ.",
     "Doğrusu Ben, tevbe edeni, inanıp yararlı iş işleyerek doğru yola gireni bağışlarım")

# ——— İsimlere göre sıra (önce Buhârî duaları, sonra Kur'an duaları, sonra âyetler) ———
HASR = "hasr-22-24"
ISIMLER = {
    1: ["h-6403", "taha-14", "isra-110", "h-7392"], 2: ["fatiha-2-3", "h-6406", "isra-110", HASR],
    3: ["h-834", "h-5999", "muminun-118", "araf-151"], 4: ["aliimran-26", "nas-1-3", "taha-114", HASR],
    5: ["h-4968", "enbiya-87", "bakara-32", "cuma-1", HASR], 6: ["h-831", HASR], 7: ["kureys-3-4", HASR], 8: [HASR],
    9: ["h-7383", "mumtehine-5", "bakara-129", HASR], 10: [HASR], 11: ["casiye-37", HASR],
    12: ["h-6306", "siir-78-82", "rad-16", HASR], 13: ["bakara-54", HASR], 14: ["aliimran-6", HASR],
    15: ["araf-155", "nuh-10", "taha-82"], 16: ["yusuf-39", "rad-16"], 17: ["aliimran-8", "sad-35"],
    18: ["h-7378", "maide-114", "zariyat-58", "kureys-3-4"], 19: ["araf-89", "sebe-26", "fatir-2"],
    20: ["h-6382", "bakara-127", "taha-114", "bakara-32"], 21: ["bakara-245"], 22: ["bakara-245"],
    23: ["h-7411", "aliimran-26"], 24: ["h-7411", "mucadele-11", "fatir-10"], 25: ["aliimran-26", "fatir-10"], 26: ["aliimran-26"],
    27: ["h-6384", "bakara-127", "sura-11"], 28: ["h-6384", "mumin-44", "sura-11"], 29: ["zumer-46", "araf-89"],
    30: ["enam-115", "h-7411"], 31: ["yusuf-100", "sura-19", "enam-103"], 32: ["enam-103"],
    33: ["h-kerb", "tegabun-17"], 34: ["h-kerb", "h-6406", "ayetel-kursi", "tevbe-129", "vakia-74"],
    35: ["h-834", "h-6306", "fatir-34"], 36: ["fatir-34", "tegabun-17"], 37: ["ayetel-kursi", "ala-1", "hac-62"],
    38: ["h-1154", "rad-9", "hac-62"], 39: ["h-6320", "yusuf-64", "hud-57"], 40: ["nisa-85"], 41: ["ahzab-39"],
    42: ["rahman-26-27", "rahman-78"], 43: ["h-kerb", "neml-40", "muminun-116"], 44: ["maide-117"],
    45: ["h-1145", "bakara-186", "hud-61"], 46: ["mumin-7"], 47: ["mumtehine-5", "bakara-32", "maide-118"],
    48: ["hud-90", "buruc-13-15"], 49: ["h-3370", "hud-73", "buruc-13-15"], 50: ["h-uyanis", "hac-7"],
    51: ["maide-117", "aliimran-18", "fussilet-53"], 52: ["h-1120", "taha-114", "hac-62"],
    53: ["aliimran-173", "tevbe-129"], 54: ["h-1154", "sura-19", "zariyat-58"], 55: ["zariyat-58"],
    56: ["yusuf-101", "araf-155", "bakara-286"], 57: ["h-3370", "fatir-15", "hud-73"], 58: ["cin-28", "h-7392"],
    59: ["buruc-13-15", "rum-27"], 60: ["buruc-13-15", "rum-27"], 61: ["h-uyanis", "h-uyku", "siir-78-82", "hadid-2-3"],
    62: ["h-uyku", "siir-78-82", "hadid-2-3"], 63: ["h-7383", "mumin-65", "ayetel-kursi"],
    64: ["h-1120", "ayetel-kursi", "aliimran-2"], 65: ["duha-6-8"], 66: ["h-3370", "hud-73"],
    67: ["ihlas", "h-4974", "rad-16", "bakara-163"], 68: ["ihlas", "h-4974"],
    69: ["h-6403", "tahrim-8", "aliimran-26", "nisa-149"], 70: ["kamer-55", "kehf-45"], 71: ["h-6398"], 72: ["h-6398"],
    73: ["hadid-2-3"], 74: ["hadid-2-3"], 75: ["hadid-2-3"], 76: ["hadid-2-3"], 77: ["rad-11"],
    78: ["rad-9", "taha-114", "muminun-116"], 79: ["tur-28"], 80: ["h-4968", "h-6309", "bakara-128", "nasr-3", "bakara-37"],
    81: ["ibrahim-47", "zumer-37"], 82: ["bakara-286", "nisa-149"], 83: ["hasr-10"], 84: ["aliimran-26"],
    85: ["rahman-26-27", "rahman-78"], 86: ["aliimran-18"], 87: ["aliimran-9", "sebe-26"],
    88: ["fatir-15", "kasas-24", "neml-40"], 89: ["kasas-24", "duha-6-8", "necm-48"], 90: ["h-844", "fatir-2"],
    91: ["enbiya-83", "yunus-107"], 92: ["h-844", "yunus-107"], 93: ["h-6316", "h-1120", "nur-35", "tahrim-8"],
    94: ["fatiha-6", "aliimran-8", "furkan-31", "kehf-24"], 95: ["bakara-117", "yusuf-101", "zumer-46"],
    96: ["rahman-26-27", "kasas-60"], 97: ["enbiya-89"], 98: ["kehf-10", "kehf-24", "bakara-186"],
    99: ["h-7378", "bakara-250", "araf-126"],
}
if sorted(ISIMLER) != list(range(1, 100)):
    HATA.append("İsim listesi 1…99 değil")
for no, ids in ISIMLER.items():
    for i in ids:
        if i not in DUALAR:
            HATA.append(f"{no}. isim: bilinmeyen dua {i}")
kullanilmayan = set(DUALAR) - {i for ids in ISIMLER.values() for i in ids}
if kullanilmayan:
    HATA.append(f"Hiçbir isme bağlanmamış: {sorted(kullanilmayan)}")

if HATA:
    print("\n".join(HATA))
    sys.exit(1)

(HEDEF / "esma_dualar.json").write_text(json.dumps({"dualar": DUALAR, "isimler": {str(k): v for k, v in ISIMLER.items()}},
                                                   ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
print("Tamam:", len(DUALAR), "dua/âyet ·", sum(1 for d in DUALAR.values() if d["kaynak"].startswith("Buhârî")), "Buhârî ·",
      sum(len(v) for v in ISIMLER.values()), "bağlantı")
