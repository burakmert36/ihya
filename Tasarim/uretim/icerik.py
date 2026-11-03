"""Uygulamanın içerik dosyalarını üretir ve kaynaklarına karşı doğrular.

Çıktı: Resources/Content/{dualar,esma,dinigunler,hadisler,hikmetler,vakitler}.json
Kullanım: python3 -I Tasarim/uretim/icerik.py <külliyat klasörü>
  külliyat klasörü: data/hadis/all_clean.json, data/raw/tur-diyanetisleri.json, data/raw/ara-quranuthmanihaf.json
  ve ext/dua/dua_ham.txt dosyalarını içerir (tasarım aşamasının kaynakları).
Her âyet meali Diyanet mealinde, her hadis metni Buhârî külliyatında birebir (boşluk ve noktalama hariç) aranır;
bulunamayan olursa betik hata verir ve dosya yazılmaz.
"""
import json
import re
import shutil
import sys
from pathlib import Path

KOK = Path(__file__).resolve().parents[2]
KAY = Path(sys.argv[1]) if len(sys.argv) > 1 else KOK / "Tasarim" / "kaynak"
HEDEF = KOK / "Resources" / "Content"
HEDEF.mkdir(parents=True, exist_ok=True)

BUHARI = {x["n"]: x for x in json.load(open(KAY / "data/hadis/all_clean.json", encoding="utf-8"))}
MEAL = {(v["chapter"], v["verse"]): v["text"] for v in json.load(open(KAY / "data/raw/tur-diyanetisleri.json", encoding="utf-8"))["quran"]}
ARAPCA = {(v["chapter"], v["verse"]): v["text"] for v in json.load(open(KAY / "data/raw/ara-quranuthmanihaf.json", encoding="utf-8"))["quran"]}
HATA = []


def norm(s: str) -> str:
    s = s.replace("İ", "i").replace("I", "ı").lower()
    return re.sub(r"[^a-zçğıöşüâîû]", "", s.replace("â", "a").replace("î", "i").replace("û", "u"))


def kuran(sure, ayetler, anlam, kelime=None):
    """anlam: Diyanet mealinden birebir alıntı; kelime: (ilk, son) Arapça kelime aralığı (tek âyette)."""
    tam = " ".join(MEAL[(sure, a)] for a in ayetler)
    if norm(anlam) not in norm(tam):
        HATA.append(f"Meal eşleşmedi: {sure}:{ayetler} → {anlam[:60]}")
    if kelime:
        w = ARAPCA[(sure, ayetler[0])].split()
        ar = " ".join(w[kelime[0]:kelime[1] + 1])
    else:
        ar = " ".join(ARAPCA[(sure, a)] for a in ayetler)
    return ar


def buhari(no, alinti):
    if norm(alinti) not in norm(BUHARI[no]["tr"]):
        HATA.append(f"Buhârî {no} metni eşleşmedi: {alinti[:60]}")


SURE = {2: "Bakara", 3: "Âl-i İmrân", 7: "A'râf", 12: "Yûsuf", 14: "İbrâhîm", 18: "Kehf", 20: "Tâhâ", 21: "Enbiyâ", 25: "Furkân",
        26: "Şuarâ", 27: "Neml", 28: "Kasas", 46: "Ahkâf", 59: "Haşr"}


def ayet_dua(id_, baslik, sure, ayetler, okunus, anlam, kelime=None, ek_kaynak="", not_=""):
    ar = kuran(sure, ayetler, anlam, kelime)
    aralik = f"{ayetler[0]}" if len(ayetler) == 1 else f"{ayetler[0]}-{ayetler[-1]}"
    kaynak = f"{SURE[sure]} {sure}:{aralik}" + (f" · {ek_kaynak}" if ek_kaynak else "")
    d = {"id": id_, "baslik": baslik, "arapca": ar, "okunus": okunus, "anlam": anlam.rstrip(".") + ".", "kaynak": kaynak}
    if not_:
        d["not"] = not_
    return d


def hadis_dua(id_, baslik, no, okunus, anlam, not_="", alinti=None):
    buhari(no, alinti or anlam)
    d = {"id": id_, "baslik": baslik, "okunus": okunus, "anlam": anlam, "kaynak": f"Buhârî, {no}"}
    if not_:
        d["not"] = not_
    return d


# ——— Konulu dualar (Kur'ân ve Sahîh-i Buhârî) ———
TEMALAR = [
    {"id": "iki-cihan", "ad": "Dünya ve âhiret iyiliği", "simge": "sun.horizon", "dualar": [
        ayet_dua("rabbena-atina", "Rabbenâ âtinâ", 2, [201],
                 "Rabbenâ âtinâ fi'd-dünyâ haseneten ve fi'l-âhireti haseneten ve kınâ azâbe'n-nâr.",
                 "Rabbimiz! Bize dünyada iyiyi, ahirette de iyiyi ver, bizi ateşin azabından koru", (3, 13),
                 ek_kaynak="Buhârî, 6389", not_="Enes b. Mâlik: Resûlullah'ın en çok yaptığı dua budur (Buhârî, 6389)."),
        ayet_dua("kehf-resed", "Katından rahmet", 18, [10],
                 "Rabbenâ âtinâ min ledünke rahmeten ve heyyi' lenâ min emrinâ reşedâ.",
                 "Rabbimiz! Katından bize rahmet ver ve işimizde doğruyu göster, bizi başarılı kıl", (6, 16)),
    ]},
    {"id": "aile", "ad": "Aile ve din huzuru", "simge": "house", "dualar": [
        ayet_dua("furkan-74", "Gözümüzün aydınlığı", 25, [74],
                 "Rabbenâ heb lenâ min ezvâcinâ ve zürriyyâtinâ kurrate a'yünin vec'alnâ li'l-müttekîne imâmâ.",
                 "Rabbimiz! Bize eşlerimizden ve çocuklarımızdan gözümüzün aydınlığı olacak insanlar ihsan et ve bizi, Allah'a karşı gelmekten sakınanlara önder yap", (2, 12)),
        ayet_dua("ibrahim-40", "Namazı ayakta tutanlardan", 14, [40, 41],
                 "Rabbi'c'alnî mukîme's-salâti ve min zürriyyetî, Rabbenâ ve tekabbel duâ. Rabbenağfir lî ve li-vâlideyye ve li'l-mü'minîne yevme yekûmü'l-hisâb.",
                 "Rabbim! Beni ve çocuklarımı namaz kılanlardan eyle. Rabbimiz! Duamı kabul buyur. Rabbimiz! Hesap görülecek günde, beni, anamı babamı ve inananları bağışla"),
        ayet_dua("zekeriyya", "Temiz bir nesil", 3, [38],
                 "Rabbi heb lî min ledünke zürriyyeten tayyibeh, inneke semîu'd-duâ.",
                 "Ya Rabbi! Bana kendi katından temiz bir soy bahşet, doğrusu Sen duayı işitirsin", (5, 14)),
    ]},
    {"id": "bagislanma", "ad": "Bağışlanma", "simge": "drop", "dualar": [
        {"id": "seyyidul-istigfar", "baslik": "Seyyidü'l-istiğfâr",
         "okunus": "Allâhümme ente rabbî, lâ ilâhe illâ ente, halaktenî ve ene abdük, ve ene alâ ahdike ve va'dike me'steta'tü, eûzü bike min şerri mâ sana'tü, ebûü leke bi-ni'metike aleyye, ve ebûü leke bi-zenbî, fağfir lî, fe-innehû lâ yağfiru'z-zünûbe illâ ente.",
         "anlam": "Allah'ım! Sen benim Rabbimsin. Senden başka ilah yoktur. Beni Sen yarattın, ben Senin kulunum. Gücüm yettiğince Sana verdiğim söz ve ahid üzereyim. Yaptıklarımın şerrinden Sana sığınırım. Bana verdiğin nimeti ikrar ederim, günahımı da itiraf ederim. Beni bağışla; çünkü günahları Senden başka bağışlayan yoktur.",
         "kaynak": "Buhârî, 6306", "not": "Resûlullah bu duaya “istiğfarların efendisi” dedi. İnanarak gündüz okuyup akşamdan önce ölen cennetliktir (Buhârî, 6306)."},
        hadis_dua("ebubekir-duasi", "Namazda okunacak dua", 834,
                  "Allâhümme innî zalemtü nefsî zulmen kesîran ve lâ yağfiru'z-zünûbe illâ ente, fağfir lî mağfiraten min indike verhamnî, inneke ente'l-Gafûru'r-Rahîm.",
                  "Allah'ım! Ben kendime çok fazla zulmettim. Günahları Senden başka bağışlayacak yoktur. Allah'ım, beni katından bir mağfiret ile bağışla ve bana merhametinle muamele buyur. Şüphesiz Sen bağışlayan (Gafûr) ve esirgeyensin (Rahîm).",
                  not_="Resûlullah bu duayı Hz. Ebû Bekir'e namazda okuması için öğretti.",
                  alinti="Allah'ım ben kendime çok fazla zulmettim. Günahları sen'den başka bağışlayacak yoktur. Allah'ım, beni katından bir mağfiret ile bağışla ve bana merhametinle muamele buyur. Şüphesiz sen bağışlayan (Ğafur) ve esirgeyensin (Rahîm)"),
        ayet_dua("adem-duasi", "Hz. Âdem ile Havvâ'nın duası", 7, [23],
                 "Rabbenâ zalemnâ enfüsenâ ve in lem tağfir lenâ ve terhamnâ le-nekûnenne mine'l-hâsirîn.",
                 "Rabbimiz! Kendimize yazık ettik; bizi bağışlamaz ve bize merhamet etmezsen biz kaybedenlerden oluruz", (1, 11)),
        hadis_dua("hatalarimi-bagisla", "Bütün hatalarım için", 6398,
                  "Rabbiğfir lî hatîetî ve cehlî ve isrâfî fî emrî küllihî ve mâ ente a'lemü bihî minnî. Allâhümmağfir lî hatâyâye ve amdî ve cehlî ve hezlî ve küllü zâlike indî. Allâhümmağfir lî mâ kaddemtü ve mâ ahhartü ve mâ esrartü ve mâ a'lentü, ente'l-mukaddimu ve ente'l-muahhiru ve ente alâ külli şey'in kadîr.",
                  "Rabbim! Her konuda hatalarımı, bilmediklerimi, israflarımı ve Senin benden daha iyi bildiğin şeyleri bağışla. Allah'ım! Yaptığım yanlışları, kasıtlı yaptıklarımı, bilmediklerimi ve şakalarımı bağışla. Ben bunların hepsini yapmışımdır. Allah'ım! Geçmişte yaptıklarımı ve gelecekte yapacaklarımı bağışla. Gizli ve açık kusurlarımı affet. Öne alan da Sensin, sona bırakan da Sensin ve Sen her şeye kadirsin.",
                  alinti="Rabbim! Her konuda hatalarımı, bilmediklerimi, israflarımı ve senin benden daha iyi bildiğin şeyleri bağışla. Allahım! Yaptığım yanlışları, kasıtlı yaptıklarımı, bilmediklerimi ve şakalarımı bağışla. Ben bunların hepsini yapmışımdır. Allahım! Geçmişte yaptıklarımı ve gelecekte yapacaklarımı bağışla. Gizli ve açık kusurlarımı affet. Öne alan da sensin sona bırakan da sensin ve sen her şeye kadirsin"),
        ayet_dua("hasr-10", "Bizden öncekiler için", 59, [10],
                 "Rabbenağfir lenâ ve li-ihvâninellezîne sebekûnâ bi'l-îmâni ve lâ tec'al fî kulûbinâ ğıllen lillezîne âmenû, Rabbenâ inneke raûfün rahîm.",
                 "Rabbimiz! Bizi ve bizden önce inanmış olan kardeşlerimizi bağışla; kalbimizde müminlere karşı kin bırakma; Rabbimiz! Şüphesiz Sen şefkatlisin, merhametlisin", (5, 23)),
    ]},
    {"id": "salih-amel", "ad": "Hayırda çoğalmak", "simge": "leaf", "dualar": [
        hadis_dua("tevhid-yuz", "Günde yüz defa", 6403,
                  "Lâ ilâhe illallâhü vahdehû lâ şerîke leh, lehü'l-mülkü ve lehü'l-hamdü ve hüve alâ külli şey'in kadîr.",
                  "Ortağı olmayan Allah'tan başka ilah yoktur. Mülk de O'nun, hamd de O'nundur. O her şeye kadirdir.",
                  not_="Gündüz yüz defa söyleyen, sanki on köleyi azad etmiş gibi olur. Ayrıca yüz iyilik sevabı yazılır, yüz kötülüğü silinir (Buhârî, 6403).",
                  alinti="Ortağı olmayan Allah'tan başka ilah yoktur mülk de onun ham d de onundur. O her şeye kadirdir"),
        hadis_dua("iki-hafif-soz", "Dilde hafif, mizanda ağır", 6406,
                  "Sübhânallâhi ve bi-hamdihî, sübhânallâhi'l-azîm.",
                  "Azîm olan Allah'ı tesbih ederim. Allah'ı noksan sıfatlardan tenzih edip O'na hamd ederim.",
                  not_="Söylenmesi kolay olan ama mizanda ağırlığı fazla olacak iki söz (Buhârî, 6406).",
                  alinti="Azim olan Allah'ı tesbih ederim. Allah'ı noksan sıfatlardan tenzih edip ona hamd ederim"),
        ayet_dua("suleyman-duasi", "Şükür ve salih amel", 27, [19],
                 "Rabbi evzi'nî en eşküre ni'metekelletî en'amte aleyye ve alâ vâlideyye ve en a'mele sâlihan terdâhü ve edhılnî bi-rahmetike fî ibâdike's-sâlihîn.",
                 "Rabbim! Bana ve ana babama verdiğin nimete şükürde, hoşnut olacağın işi yapmakta beni muvaffak kıl. Rahmetinle, beni iyi kullarının arasına koy", (6, 25)),
    ]},
    {"id": "hayirli", "ad": "Hakkımızda hayırlı olan", "simge": "signpost.right", "dualar": [
        hadis_dua("istihare", "İstihâre duası", 6382,
                  "Allâhümme innî estehîruke bi-ilmike ve estakdiruke bi-kudretike ve es'elüke min fadlike'l-azîm, fe-inneke takdiru ve lâ akdiru, ve ta'lemu ve lâ a'lemu, ve ente allâmü'l-ğuyûb. Allâhümme in künte ta'lemu enne hâze'l-emra hayrun lî fî dînî ve meâşî ve âkıbeti emrî fakdurhu lî, ve in künte ta'lemu enne hâze'l-emra şerrun lî fî dînî ve meâşî ve âkıbeti emrî fasrifhu annî vasrifnî anhu, vakdur liye'l-hayra haysü kâne, sümme ardınî bih.",
                  "Allah'ım! İlmine sığınıp hakkımda hayırlı olanı Senden diliyorum. Kudretine sığınıp Senden güç istiyorum. Senin yüce fazlından niyaz ediyorum. Çünkü Sen güçlüsün, ben değilim. Sen bilirsin, ben bilmem. Sen bütün gayblardan haberdarsın. Allah'ım! Eğer yapmak istediğim şey dinim, hayatım ve âhiretim için hayırlı ise onu benim için takdir et. Eğer dinim, hayatım ve âhiretim için kötü ise onu benden, beni de ondan uzak eyle. Hakkımda hayır neyse her zaman onu nasip eyle. Sonra da beni takdir ettiğinden razı et.",
                  not_="Bir işe karar vermeden önce iki rekât namaz kılınır, sonra bu dua okunur ve ihtiyaç söylenir (Buhârî, 6382).",
                  alinti="Allahım! İlmine sığınıp hakkımda hayırlı olanı senden diliyorum. Kudretine sığınıp senden güç istiyorum. Senin yüce fazlından niyaz ediyorum. Çünkü sen güçlüsün ben değilim. Sen bilirsin ben bilmem. Sen bütün gayblardan haberdarsın. Allahım! Eğer yapmak istediğim şey dinim hayatım ve ahretim için hayırlı ise onu benim için takdir et. Eğer dinim hayatı m ve ahretim için kötü ise onu benden beni de ondan uzak eyle. Hakkımda hayır neyse her zaman onu nasip eyle. Sonra da beni takdir ettiğinden razı et"),
        hadis_dua("hayirli-omur", "Hayırlı olduğu sürece", 5671,
                  "Allâhümme ahyinî mâ kâneti'l-hayâtü hayran lî, ve teveffenî izâ kâneti'l-vefâtü hayran lî.",
                  "Allah'ım, hayat benim için hayırlı olduğu sürece beni hayatta bırak ve eğer ölüm benim için hayırlı ise canımı al.",
                  not_="Sıkıntı anında ölümü temenni etmek yerine bu dua öğretildi (Buhârî, 5671).",
                  alinti="Allah'ım, hayat benim için hayırlı olduğu sürece beni hayattabırak ve eğer ölüm benim için hayırlı ise canımı al"),
        ayet_dua("musa-duasi", "İndireceğin hayra muhtacım", 28, [24],
                 "Rabbi innî limâ enzelte ileyye min hayrin fakîr.",
                 "Rabbim! Doğrusu bana indireceğin hayra muhtacım", (7, 14)),
        ayet_dua("ilmimi-artir", "İlmimi artır", 20, [114], "Rabbi zidnî ilmâ.", "Rabbim! ilmimi artır", (14, 17)),
    ]},
    {"id": "rizasi", "ad": "Razı olduğu kullardan olmak", "simge": "heart", "dualar": [
        ayet_dua("ahkaf-15", "Hoşnut olacağın iş", 46, [15],
                 "Rabbi evzi'nî en eşküre ni'metekelletî en'amte aleyye ve alâ vâlideyye ve en a'mele sâlihan terdâhü ve aslıh lî fî zürriyyetî, innî tübtü ileyke ve innî mine'l-müslimîn.",
                 "Rabbim! Bana ve anne babama verdiğin nimete şükretmemi ve benim hoşnut olacağın yararlı bir işi yapmamı sağla; bana verdiğin gibi soyuma da salah ver; doğrusu Sana yöneldim, ben, kendini Sana verenlerdenim", (23, 47)),
        ayet_dua("kalbi-egriltme", "Kalbimizi kaydırma", 3, [8],
                 "Rabbenâ lâ tüziğ kulûbenâ ba'de iz hedeytenâ ve heb lenâ min ledünke rahmeh, inneke ente'l-vehhâb.",
                 "Rabbimiz! Bizi doğru yola erdirdikten sonra kalblerimizi eğriltme, katından bize rahmet bağışla; şüphesiz Sen sonsuz bağışta bulunansın"),
        ayet_dua("yusuf-duasi", "Müslüman olarak al", 12, [101],
                 "Fâtıra's-semâvâti ve'l-ard, ente veliyyî fi'd-dünyâ ve'l-âhirah, teveffenî müslimen ve elhıknî bi's-sâlihîn.",
                 "Ey göklerin ve yerin yaradanı! Dünya ve ahirette işlerimi yoluna koyan sensin; benim canımı müslüman olarak al ve beni iyilere kat", (9, 21)),
    ]},
    {"id": "emniyet", "ad": "Korku ve sıkıntılardan emân", "simge": "shield", "dualar": [
        hadis_dua("keder-huzun", "Kederden ve hüzünden", 6369,
                  "Allâhümme innî eûzü bike mine'l-hemmi ve'l-hazeni, ve'l-aczi ve'l-keseli, ve'l-cübni ve'l-buhli, ve dala'i'd-deyni ve ğalebeti'r-ricâl.",
                  "Allah'ım! Kederden, hüzünden, düşkünlükten, tembellikten, korkaklıktan, cimrilikten, borç sıkıntısından ve güçlülerin tasallutundan Sana sığınırım.",
                  alinti="Allahım' kederden, hüzünden, düşkünlükten, tembellikten, korkaklıktan, cimrilikten, borç sıkıntısından ve güçlülerin tasallutundan sana sığınırım"),
        hadis_dua("sikinti-duasi", "Sıkıntı anında", 6345,
                  "Lâ ilâhe illallâhü'l-azîmü'l-halîm, lâ ilâhe illallâhü rabbü'l-arşi'l-azîm, lâ ilâhe illallâhü rabbü's-semâvâti ve rabbü'l-ardı ve rabbü'l-arşi'l-kerîm.",
                  "Azîm ve Halîm olan Allah'tan başka ilah yoktur. Göklerin, yerin ve yüce arşın Rabbi olan Allah'tan başka ilah yoktur.",
                  not_="Resûlullah sıkıntılı anlarında bu duayı okurdu (Buhârî, 6345).",
                  alinti="Azim ve halim olan Allah'tan başka ilah yoktur. Göklerin, yerin ve yüce arşın rabbi olan Allah'tan başka ilah yoktur"),
        ayet_dua("hasbunallah", "Allah bize yeter", 3, [173], "Hasbünallâhü ve ni'me'l-vekîl.",
                 "Allah bize yeter. O ne güzel Vekil'dir", (14, 17), ek_kaynak="Buhârî, 4563",
                 not_="Hz. İbrâhîm ateşe atıldığında, Resûlullah da “size karşı ordu toplandı” denildiğinde bunu söyledi (Buhârî, 4563)."),
        ayet_dua("yunus-duasi", "Hz. Yûnus'un duası", 21, [87],
                 "Lâ ilâhe illâ ente sübhâneke innî küntü mine'z-zâlimîn.",
                 "Senden başka tanrı yoktur, Sen münezzehsin, doğrusu ben haksızlık edenlerdenim", (15, 23)),
        hadis_dua("acizlik", "Acizlikten ve tembellikten", 6367,
                  "Allâhümme innî eûzü bike mine'l-aczi ve'l-keseli, ve'l-cübni ve'l-heremi, ve eûzü bike min azâbi'l-kabri, ve eûzü bike min fitneti'l-mahyâ ve'l-memât.",
                  "Allah'ım! Acziyet, tembellik, korkaklık, düşkünlük, kabir azabı, hayat ve ölüm fitnesinden Sana sığınırım.",
                  alinti="Allahım! Acziyet, tembellik, korkaklık, düşkünlük, kabir azabı, hayat ve ölüm fitnesinden sana sığınırım"),
    ]},
    {"id": "sifa", "ad": "Şifa", "simge": "cross.case", "dualar": [
        hadis_dua("sifa-duasi", "Hasta için dua", 5675,
                  "Ezhibi'l-be's, Rabbe'n-nâs, işfi ve ente'ş-Şâfî, lâ şifâe illâ şifâük, şifâen lâ yuğâdiru sekamâ.",
                  "Ey insanların Rabbi! Bu hastalığı gider, şifa ver, Şâfî (şifa veren) Sensin. Senin şifandan başka şifa yoktur. Geriye hiçbir hastalık bırakmayan bir şifa ver.",
                  not_="Resûlullah bir hastayı ziyaret ettiğinde böyle dua ederdi (Buhârî, 5675).",
                  alinti="Ey insanların Rabbi! Bu hastalığı gider, şifa ver, Şafi (şifa veren) sensin. Senin şifandan başka şifa yoktur. Geriye hiçbir hastalık bırakmayan bir şifa ver"),
        ayet_dua("eyyub-duasi", "Hz. Eyyûb'un duası", 21, [83],
                 "Ennî messeniye'd-durru ve ente erhamü'r-râhimîn.",
                 "Başıma bir bela geldi, (Sana sığındım), Sen merhametlilerin merhametlisisin", (4, 9)),
        ayet_dua("sifa-veren", "Bana O şifa verir", 26, [80], "Ve izâ meridtü fe-hüve yeşfîn.",
                 "Hasta olduğumda bana O şifa verir"),
    ]},
]

# 6306'nın Türkçe metni külliyatta kesik; anlamın doğruluğu İngilizce metinden sınanır.
buhari(6306, "İstiğfarların efendisi")
if "most superior way of asking for forgiveness" not in BUHARI[6306]["en"] or "Khalaqtani" not in BUHARI[6306]["en"]:
    HATA.append("Buhârî 6306 İngilizce metni beklenen ifadeleri içermiyor")
if "most frequent" not in BUHARI[6389]["en"] and "most" not in BUHARI[6389]["en"]:
    HATA.append("Buhârî 6389 notu doğrulanamadı")
buhari(4563, "hasbunallahu ve ni'me'l-vekil")

# ——— Dua Defterim (kullanıcının kendi derlemesi; asgari düzeltme) ———
ham = (KAY / "ext/dua/dua_ham.txt").read_text(encoding="utf-8")
vakia = [{"no": int(n), "okunus": t.strip()} for n, t in re.findall(r"(\d+)\.\s*([^0-9]+?)(?=\s*\d+\.|\s*$)", ham.split("BÖLÜM 4: VÂKIA SURESİ")[1].split("BÖLÜM 5")[0].split("Bismillahirrahmanirrahim", 1)[1])]
if [v["no"] for v in vakia] != list(range(1, 97)):
    HATA.append(f"Vâkıa okunuşu 96 âyet değil: {len(vakia)}")
hacet = ham.split("BÖLÜM 5: KAPSAMLI HACET DUASI")[1].strip()
hacet = hacet.split("\n", 1)[0].strip().rstrip("*").strip()
hacet = re.sub(r"^\(Bütün bu okunanların yüzü suyu hürmetine\)\s*", "", hacet)
ism_azam = re.search(r"1\. İsm-i Azam Duası\nOkunuşu: (.+?)\n2\. Salavat", ham, re.S).group(1).strip()
salavat = re.search(r"2\. Salavat-ı Şerife\nOkunuşu: (.+?)\n3\.", ham, re.S).group(1).strip()


def oge(baslik, okunus="", anlam="", not_="", tekrar=0):
    d = {"baslik": baslik}
    for k, v in (("okunus", okunus), ("anlam", anlam), ("not", not_)):
        if v:
            d[k] = v
    if tekrar:
        d["tekrar"] = tekrar
    return d


DEFTER = {
    "baslik": "Manevî Zırh, Rızık ve Hacet Duaları",
    "giris": [
        oge("Niyet", anlam="Allah'ım, rızan için ve şu hacetimin kabulü için okumaya niyet ettim."),
        oge("İstiğfar", okunus="Estağfirullah el-Azîm", tekrar=33),
        oge("Salavat", okunus="Allâhumme salli alâ seyyidinâ Muhammedin ve alâ âli seyyidinâ Muhammed", tekrar=3),
    ],
    "bolumler": [
        {"baslik": "Korunma ve Güven", "aciklama": "Her türlü sıkıntıdan kurtulmak, düşmana galip gelmek ve rızık genişliği için", "ogeler": [
            oge("Tevbe 51", "Kul len yusîbenâ illâ mâ keteballâhu lenâ, huve mevlânâ, ve alâllâhi felyetevekkelil mu'minûn.", "De ki: \"Allah'ın bizim için yazdığından başkası bize asla erişmez. O bizim sahibimizdir. Müminler yalnız Allah'a güvenip dayansınlar.\""),
            oge("Yûnus 107", "Ve in yemseskallâhu bidurrin fe lâ kâşife lehu illâ huve, ve in yuridke bi hayrin fe lâ râdde li fadlihi, yusîbu bihî men yeşâu min ibâdihi, ve huvel gafûrur rahîm.", "Eğer Allah sana bir zarar dokundurursa, onu O'ndan başka giderecek yoktur. Eğer sana bir hayır dilerse, O'nun lütfunu geri çevirecek kimse de yoktur. O, bunu kullarından dilediğine eriştirir. O çok bağışlayan, çok merhamet edendir."),
            oge("Hûd 6", "Ve mâ min dâbbetin fîl ardı illâ alâllâhi rızkuhâ ve ya'lemu mustekarrahâ ve mustevdeahâ, kullun fî kitâbin mubîn.", "Yeryüzünde rızkı Allah'a ait olmayan hiçbir canlı yoktur. O, onların karar kıldıkları yeri de, emaneten durdukları yeri de bilir. Bunların hepsi apaçık bir kitaptadır."),
            oge("Hûd 56", "İnnî tevekkeltu alâllâhi rabbî ve rabbikum, mâ min dâbbetin illâ huve âhızun bi nâsıyetihâ, inne rabbî alâ sırâtın mustekîm.", "\"Ben, benim de Rabbim, sizin de Rabbiniz olan Allah'a dayandım. Hiçbir canlı yoktur ki, Allah onu perçeminden yakalamış (kontrolü altına almış) olmasın. Şüphesiz Rabbim dosdoğru bir yol üzerindedir.\""),
            oge("Ankebût 60", "Ve keeyyin min dâbbetin lâ tahmilu rızkahâ allâhu yerzukuhâ ve iyyâkum ve huves semîul alîm.", "Nice canlılar vardır ki, rızıklarını (yanlarında) taşıyamazlar. Onları da sizi de Allah rızıklandırır. O, hakkıyla işitendir, hakkıyla bilendir."),
            oge("Fâtır 2", "Mâ yeftehillâhu lin nâsi min rahmetin fe lâ mumsike lehâ, ve mâ yumsik fe lâ mursile lehu min ba'dihî, ve huvel azîzul hakîm.", "Allah insanlar için rahmetinden neyi açarsa, artık onu tutacak (engelleyecek) yoktur. Neyi de tutarsa, artık onu gönderecek yoktur. O, mutlak güç sahibidir, hüküm ve hikmet sahibidir."),
            oge("Zümer 38", "Ve le in seeltehum men halakas semâvâti vel arda le yekûlunnallâhu, kul e fe raeytum mâ ted'ûne min dûnillâhi in erâdeniyallâhu bi durrin hel hunne kâşifâtu durrihi ev erâdenî bi rahmetin hel hunne mumsikâtu rahmetihi, kul hasbiyallâhu, aleyhi yetevekkelul mutevekkilûn.", "De ki: \"Allah bana yeter. Tevekkül edenler ancak O'na güvenip dayanırlar.\""),
        ]},
        {"baslik": "Yakarış ve İsm-i Azam", "aciklama": "En büyük isimlerle yapılan dualar ve Salavat-ı Şerife", "ogeler": [
            oge("İsm-i Azam Duası", ism_azam),
            oge("Salavat-ı Şerife", salavat),
            oge("Âl-i İmrân 26-27 (Mülk Duası)", "Kulillâhumme mâlikel mulki tû’til mulke men teşâu ve tenziul mulke mimmen teşâu ve tuizzu men teşâu ve tuzillu men teşâu, bi yedikel hayr, inneke alâ kulli şey’in kadîr. Tûlicul leyle fîn nehâri ve tûlicun nehâre fîl leyl, ve tuhricul hayye minel meyyiti ve tuhricul meyyite minel hayy, ve terzuku men teşâu bi gayri hisâb.", "De ki: \"Ey mülkün sahibi Allah'ım! Sen mülkü dilediğine verirsin, dilediğinden de çeker alırsın. Dilediğini aziz, dilediğini zelil edersin. Hayır senin elindedir. Şüphesiz sen her şeye hakkıyla gücü yetensin... Dilediğine de hesapsız rızık verirsin.\""),
        ]},
        {"baslik": "Ferahlık ve Ummadık Rızık", "aciklama": "Kalp ferahlığı, iş kolaylığı ve beklenmedik rızık kapısı için", "ogeler": [
            oge("İnşirah Sûresi", "Bismillahirrahmânirrahîm. Elem neşrah leke sadrak. Ve vada'nâ 'anke vizrak. Ellezî enkada zahrak. Ve refa'nâ leke zikrak. Feinne me'al'usri yusran. İnne me'al'usri yusrâ. Feizâ ferağte fensab. Ve ilâ rabbike ferğab.", "Senin göğsünü açıp genişletmedik mi? Belini büken yükünü üzerinden almadık mı? Elbette zorluğun yanında bir kolaylık vardır. Öyleyse (bir işi bitirip) boş kaldın mı, hemen başka bir işe koyul ve yalnız Rabbine yönel."),
            oge("Talâk 2-3", "Ve men yettekıllâhe yec'al lehu mahracâ. Ve yerzukhu min haysu lâ yahtesib. Ve men yetevekkel alâllâhi fehuve hasbuh. İnnallâhe bâliğu emrih. Kad cealallâhu likulli şey'in kadrâ.", "\"Kim Allah'a karşı gelmekten sakınırsa, Allah ona bir çıkış yolu açar. Ve onu hiç beklemediği, ummadığı yerden rızıklandırır. Kim Allah'a güvenirse O, ona yeter.\""),
            oge("En'âm 1-3", "Elhamdu lillâhillezî halakas semâvâti vel arda ve cealez zulumâti ven nûr, summellezîne keferû bi rabbihim ya’dilûn. Huvellezî halakakum min tînin summe kadâ ecelâ, ve ecelun musemmen indehu summe entum temterûn. Ve huvallâhu fîs semâvâti ve fîl ard, ya’lemu sirrakum ve cehrakum ve ya’lemu mâ teksibûn.", "Hamd, gökleri ve yeri yaratan, karanlıkları ve aydınlığı var eden Allah’a mahsustur. (Bunca delile rağmen) yine de inkar edenler, (başkalarını) Rablerine denk tutuyorlar. O, sizi bir çamurdan yaratan, sonra size bir ecel tayin edendir. (Kıyamet için de) O’nun katında belirli bir ecel vardır. Siz ise hâlâ şüphe ediyorsunuz. O, göklerde ve yerde (tek) Allah’tır. Gizlinizi, açığınızı bilir; (hayır ve şerden) ne kazanacağınızı da bilir."),
            oge("Haşr 22-24", "Eûzü billahis-semî'il alîmi mineşşeytânirracîm. Bismillâhirrahmânirrahîm. Huvallâhullezî lâ ilâhe illâ hu, âlimul gaybi veş şehâdeh, huver rahmânur rahîm. Huvallâhullezî lâ ilâhe illâ hu, el-melikul kuddûsus selâmul mu’minul muheyminul azîzul cebbârul mutekebbir, subhânallâhi ammâ yuşrikûn. Huvallâhul hâlikul bâriul musavviru lehul esmâul husnâ, yusebbihu lehu mâ fîs semâvâti vel ard ve huvel azîzul hakîm.", "O, kendisinden başka hiçbir ilah olmayan Allah’tır. Gaybı da (görünmeyeni), görünen âlemi de bilendir. O, Rahmân’dır, Rahîm’dir. O, kendisinden başka hiçbir ilah bulunmayan Allah’tır. O, mülkün gerçek sahibidir, kutsaldır (her türlü eksiklikten uzaktır), barış ve esenliğin kaynağıdır, güvenlik verendir, gözetip koruyandır, mutlak güç sahibidir, düzeltip ıslah edendir, büyüklükte eşsizdir. Allah, onların ortak koştuklarından uzaktır (münezzehtir). O; yaratan, yoktan var eden, şekil veren Allah’tır. Güzel isimler O’nundur. Göklerdeki ve yerdeki her şey O’nu tesbih eder. O, mutlak güç sahibidir, hüküm ve hikmet sahibidir.",
                not_="Başlangıçtaki “Eûzü billâhi's-semî'i'l-alîm” kalıbı Tirmizî'deki bir rivayette geçer; hadis âlimleri bu rivayetin senedini zayıf bulmuştur."),
            oge("Darlık ve çaresizlik anında", "Allah, Allahü Rabbî, lâ üşriku bihî şey'en.", "Allah, Allah Rabbimdir. O'na hiçbir şeyi ortak koşmam."),
        ]},
        {"baslik": "Vâkıa Sûresi", "aciklama": "Rızık ve zenginlik sûresi", "ayetler": vakia},
        {"baslik": "Kapsamlı Hacet Duası", "aciklama": "Bütün bu okunanların yüzü suyu hürmetine", "metin": hacet},
    ],
    "kapanis": oge("Kapanış", okunus="Allâhumme salli alâ seyyidinâ Muhammedin ve alâ âli seyyidinâ Muhammed",
                   anlam="Bütün okumalar bitince salavat ile kapat."),
}

# ——— Esmâ-i Hüsnâ (Tirmizî, Daavât 82 sıralaması; ilk isim Allah) ———
ESMA = [
    ("Allah", "الله", "Bütün güzel isimleri kendinde toplayan, ibadete lâyık tek varlık", "Zatının özel adıdır; diğer bütün isimler O'nun sıfatlarını anlatır."),
    ("er-Rahmân", "الرحمن", "Dünyada bütün yaratılmışlara merhamet eden", "Rahmeti mümin-kâfir ayırt etmeden bütün varlıkları kuşatır."),
    ("er-Rahîm", "الرحيم", "Âhirette müminlere sonsuz merhamet eden", "Rahmetinin özel tecellisi, iman edenlere âhirette ikram olarak görünür."),
    ("el-Melik", "الملك", "Mülkün gerçek sahibi, mutlak hükümdar", "Her şeyin sahibi ve yöneticisidir; hükmünde ortağı yoktur."),
    ("el-Kuddûs", "القدوس", "Her türlü eksiklikten uzak, tertemiz", "Hatadan, gafletten ve her kusurdan münezzehtir."),
    ("es-Selâm", "السلام", "Esenlik veren, selamete çıkaran", "Kullarını selamete erdirir; kendisi her türlü ayıptan salimdir."),
    ("el-Mü'min", "المؤمن", "Güven veren, emân veren", "Kalplere iman ve huzur verir; kullarını korkudan emin kılar."),
    ("el-Müheymin", "المهيمن", "Her şeyi gözetip koruyan", "Bütün varlıkları görüp gözetir; hiçbir şey O'nun denetiminin dışında değildir."),
    ("el-Azîz", "العزيز", "İzzet sahibi, mağlup edilemeyen", "Gücüne karşı konulamaz; hiçbir şey O'na galip gelemez."),
    ("el-Cebbâr", "الجبار", "Dilediğini yaptıran, kırıkları onaran", "İradesini her şeye geçirir; kullarının eksiğini tamamlar, gönüllerini onarır."),
    ("el-Mütekebbir", "المتكبر", "Büyüklükte eşi olmayan", "Azamet ve kibriyâ yalnız O'na yakışır."),
    ("el-Hâlık", "الخالق", "Yaratan, her şeyi ölçüyle takdir eden", "Varlıkları yoktan var eder ve her birinin ölçüsünü belirler."),
    ("el-Bâri'", "البارئ", "Her şeyi kusursuz ve uyum içinde yaratan", "Yarattıklarını birbirinden farklı ve ahenkli biçimde var eder."),
    ("el-Musavvir", "المصور", "Her varlığa ayrı bir şekil veren", "Her canlıya kendine has bir suret ve özellik verir."),
    ("el-Gaffâr", "الغفار", "Günahları çokça bağışlayan", "Tövbe eden kulunun günahlarını tekrar tekrar örter ve bağışlar."),
    ("el-Kahhâr", "القهار", "Her şeye galip gelen", "Hiçbir güç O'nun iradesine karşı duramaz."),
    ("el-Vehhâb", "الوهاب", "Karşılıksız bağışlayan", "İkramını bir karşılık beklemeden, durmadan bağışlar."),
    ("er-Rezzâk", "الرزاق", "Bütün canlıların rızkını veren", "Maddî ve manevî her rızkı yaratan ve ulaştıran O'dur."),
    ("el-Fettâh", "الفتاح", "Kapıları açan, hak ile hükmeden", "Darlıkları açar, hayır kapılarını açar ve kulları arasında hak ile hükmeder."),
    ("el-Alîm", "العليم", "Her şeyi hakkıyla bilen", "Gizli açık, geçmiş gelecek her şeyi bilir."),
    ("el-Kâbız", "القابض", "Dilediğine darlık veren, tutan", "Rızkı ve ruhları hikmetiyle tutar, daraltır."),
    ("el-Bâsıt", "الباسط", "Dilediğine bolluk veren, açan", "Rızkı ve rahmeti dilediğine genişletir."),
    ("el-Hâfıd", "الخافض", "Dilediğini alçaltan", "Haddini aşanları hikmetiyle alçaltır."),
    ("er-Râfi'", "الرافع", "Dilediğini yükselten", "Kullarını iman, ilim ve takvâ ile yükseltir."),
    ("el-Muiz", "المعز", "İzzet veren, şereflendiren", "Dilediğine şeref ve onur verir."),
    ("el-Müzil", "المذل", "Dilediğini zillete düşüren", "Dilediğini hikmetiyle değersiz kılar."),
    ("es-Semî'", "السميع", "Her şeyi işiten", "Gizli açık her sesi, her duayı işitir."),
    ("el-Basîr", "البصير", "Her şeyi gören", "Hiçbir şey O'nun görmesinden gizli kalmaz."),
    ("el-Hakem", "الحكم", "Mutlak hüküm sahibi", "Kulları arasında adaletle hükmeder, hakkı yerine koyar."),
    ("el-Adl", "العدل", "Mutlak adalet sahibi", "Hiç kimseye zulmetmez; her şeyi yerli yerince yapar."),
    ("el-Latîf", "اللطيف", "Lütfu bol, en ince işleri bilen", "Kullarına fark ettirmeden iyilik eder, en gizli incelikleri bilir."),
    ("el-Habîr", "الخبير", "Her şeyden haberdar olan", "Her şeyin iç yüzünü bilir."),
    ("el-Halîm", "الحليم", "Yumuşak davranan, cezada acele etmeyen", "Kullarına mühlet verir, hemen cezalandırmaz."),
    ("el-Azîm", "العظيم", "Pek büyük, pek yüce", "Zatında ve sıfatlarında sonsuz büyüklük sahibidir."),
    ("el-Gafûr", "الغفور", "Günahları bağışlayan", "Kusurları örter; mağfireti geniştir."),
    ("eş-Şekûr", "الشكور", "Az amele çok sevap veren", "Kulunun küçük iyiliğini bile karşılıksız bırakmaz, kat kat mükâfat verir."),
    ("el-Aliyy", "العلي", "Pek yüce", "Her şeyin üstündedir; yüceliği sınırsızdır."),
    ("el-Kebîr", "الكبير", "Pek büyük", "Büyüklüğü akılların kavrayışının ötesindedir."),
    ("el-Hafîz", "الحفيظ", "Her şeyi koruyan", "Varlıkları korur ve kulların amellerini muhafaza eder."),
    ("el-Mukît", "المقيت", "Her canlının azığını veren", "Bedenlere gıdayı, ruhlara manevî azığı verir."),
    ("el-Hasîb", "الحسيب", "Hesaba çeken, kuluna yeten", "Her şeyin hesabını bilir; O'na güvenene yeter."),
    ("el-Celîl", "الجليل", "Celâl ve azamet sahibi", "Yücelik sıfatlarının tamamına sahiptir."),
    ("el-Kerîm", "الكريم", "Cömertliği sonsuz olan", "İstenmeden verir, verdiğini başa kakmaz."),
    ("er-Rakîb", "الرقيب", "Her an gözeten", "Kullarının her hâlini gözetir."),
    ("el-Mücîb", "المجيب", "Duaları kabul eden", "Kendisine yönelenin duasına icabet eder."),
    ("el-Vâsi'", "الواسع", "İlmi ve rahmeti her şeyi kuşatan", "Rahmeti, ilmi ve ikramı geniştir."),
    ("el-Hakîm", "الحكيم", "Her işi hikmetli olan", "Hiçbir işi boş ve gayesiz değildir."),
    ("el-Vedûd", "الودود", "Kullarını seven, sevilmeye lâyık olan", "İyi kullarını sever ve onları sevdirir."),
    ("el-Mecîd", "المجيد", "Şanı yüce, şerefi sonsuz", "Şerefi ve ikramı büyüktür."),
    ("el-Bâis", "الباعث", "Ölüleri dirilten", "Kıyamet günü bütün insanları yeniden diriltir."),
    ("eş-Şehîd", "الشهيد", "Her şeye şahit olan", "Hiçbir şey O'nun huzurundan gizli değildir."),
    ("el-Hakk", "الحق", "Varlığı gerçek ve değişmez olan", "Kendisi hak, sözü hak, vaadi haktır."),
    ("el-Vekîl", "الوكيل", "Kendisine güvenilen, işleri yoluna koyan", "O'na dayanan, başka hiçbir şeye muhtaç olmaz."),
    ("el-Kaviyy", "القوي", "Pek güçlü", "Kudreti sonsuzdur, yorgunluk bilmez."),
    ("el-Metîn", "المتين", "Çok sağlam, sarsılmaz", "Gücü hiç azalmaz; hiçbir şey O'nu zorlayamaz."),
    ("el-Veliyy", "الولي", "Dost ve yardımcı olan", "İnananların dostudur; onları karanlıklardan aydınlığa çıkarır."),
    ("el-Hamîd", "الحميد", "Övülmeye lâyık olan", "Bütün övgüler O'na aittir."),
    ("el-Muhsî", "المحصي", "Her şeyi tek tek sayan", "Varlıkların sayısını ve kulların amellerini bilir."),
    ("el-Mübdi'", "المبدئ", "İlk defa yaratan", "Varlıkları örneksiz olarak başlatır."),
    ("el-Muîd", "المعيد", "Yeniden yaratan", "Ölümden sonra tekrar hayata döndürür."),
    ("el-Muhyî", "المحيي", "Hayat veren, dirilten", "Ölü toprağı ve ölü kalpleri diriltir."),
    ("el-Mümît", "المميت", "Ölümü yaratan", "Ölümü yaratan ve takdir eden O'dur."),
    ("el-Hayy", "الحي", "Ezelî ve ebedî diri olan", "Hayatı kendindendir; ölüm O'na yol bulamaz."),
    ("el-Kayyûm", "القيوم", "Her şeyi ayakta tutan", "Varlıklar O'nunla ayakta durur; O ise hiçbir şeye muhtaç değildir."),
    ("el-Vâcid", "الواجد", "Dilediğini dilediği an bulan", "İstediği her şey katında hazırdır; hiçbir şeye muhtaç değildir."),
    ("el-Mâcid", "الماجد", "Şanı yüce, cömert", "Kerem ve şerefi büyüktür."),
    ("el-Vâhid", "الواحد", "Tek olan", "Zatında, sıfatlarında ve işlerinde ortağı yoktur."),
    ("es-Samed", "الصمد", "Hiçbir şeye muhtaç olmayan, her şeyin O'na muhtaç olduğu", "Bütün varlıklar O'na yönelir; O hiçbir şeye ihtiyaç duymaz."),
    ("el-Kâdir", "القادر", "Her şeye gücü yeten", "Kudretinin yetmediği hiçbir şey yoktur."),
    ("el-Muktedir", "المقتدر", "Mutlak kudret sahibi", "Bütün güçler O'nun kudreti altındadır."),
    ("el-Mukaddim", "المقدم", "Dilediğini öne alan", "Hikmetine göre dilediğini öne geçirir."),
    ("el-Muahhir", "المؤخر", "Dilediğini geriye bırakan", "Hikmetine göre dilediğini sona bırakır."),
    ("el-Evvel", "الأول", "Başlangıcı olmayan", "Her şeyden öncedir."),
    ("el-Âhir", "الآخر", "Sonu olmayan", "Her şey yok olsa da O bâkîdir."),
    ("ez-Zâhir", "الظاهر", "Varlığı apaçık olan", "Varlığı eserleriyle apaçık görünür."),
    ("el-Bâtın", "الباطن", "Zatı gizli olan", "Akılların kavrayamayacağı kadar yücedir; her şeyin iç yüzünü bilir."),
    ("el-Vâlî", "الوالي", "Her şeyi yöneten", "Bütün işlerin idaresi O'nun elindedir."),
    ("el-Müteâlî", "المتعالي", "Son derece yüce", "Yaratılmışlara benzemekten uzaktır."),
    ("el-Berr", "البر", "İyiliği bol olan", "Kullarına iyilik eder; ihsanı her şeyi kuşatır."),
    ("et-Tevvâb", "التواب", "Tövbeleri kabul eden", "Kullarını tövbeye muvaffak kılar ve tövbelerini kabul eder."),
    ("el-Müntekim", "المنتقم", "Zalimlerin cezasını veren", "Haddi aşanları adaletiyle cezalandırır."),
    ("el-Afüvv", "العفو", "Affı çok olan", "Günahları siler, izini bile bırakmaz."),
    ("er-Raûf", "الرؤوف", "Çok şefkatli", "Kullarına karşı şefkati sonsuzdur."),
    ("Mâlikü'l-mülk", "مالك الملك", "Mülkün ebedî sahibi", "Mülkü dilediğine verir, dilediğinden alır."),
    ("Zü'l-celâli ve'l-ikrâm", "ذو الجلال والإكرام", "Celâl ve ikram sahibi", "Azameti ve cömertliği sonsuzdur."),
    ("el-Muksit", "المقسط", "Adaletle hükmeden", "Her işi adalet ve denge üzeredir."),
    ("el-Câmi'", "الجامع", "Bir araya getiren", "Kıyamet günü bütün insanları toplar; zıtları bir arada tutar."),
    ("el-Ganiyy", "الغني", "Hiçbir şeye muhtaç olmayan", "Her şeyden müstağnidir."),
    ("el-Muğnî", "المغني", "Zengin kılan", "Dilediğini muhtaç olmaktan kurtarır."),
    ("el-Mâni'", "المانع", "Engelleyen, koruyan", "Dilediği şeye engel olur; kullarını zarardan korur."),
    ("ed-Dârr", "الضار", "Zararı da hikmetiyle yaratan", "Hayır ve şer O'nun takdiriyledir; sıkıntıyı da hikmetle verir."),
    ("en-Nâfi'", "النافع", "Fayda veren", "Her türlü faydayı yaratır."),
    ("en-Nûr", "النور", "Nur veren, aydınlatan", "Gökleri, yeri ve kalpleri aydınlatır."),
    ("el-Hâdî", "الهادي", "Doğru yola ileten", "Hidayet O'nun elindedir."),
    ("el-Bedî'", "البديع", "Örneksiz yaratan", "Benzeri olmayan güzellikte yaratır."),
    ("el-Bâkî", "الباقي", "Varlığının sonu olmayan", "Her şey fânidir, O bâkîdir."),
    ("el-Vâris", "الوارث", "Her şeyin asıl sahibi olarak kalan", "Her şey yok olduktan sonra mülk yine O'na kalır."),
    ("er-Reşîd", "الرشيد", "Doğru yolu gösteren", "Bütün işleri en doğru şekilde yönetir."),
    ("es-Sabûr", "الصبور", "Çok sabırlı", "Cezayı hemen vermez, mühlet tanır."),
]
if len(ESMA) != 99 or len({e[0] for e in ESMA}) != 99:
    HATA.append(f"Esmâ sayısı 99 değil: {len(ESMA)}")

# ——— Dinî günler (Diyanet takvimi; 2026 sonu ve 2027) ———
GUNLER = [
    ("2026-12-10", "Üç Ayların Başlangıcı", "gun", "Recep, Şaban ve Ramazan aylarından oluşan mübarek zaman başlar."),
    ("2026-12-10", "Regaib Kandili", "kandil", "Recep ayının ilk cuma gecesi. Akşam namazından sonra kandil gecesidir."),
    ("2027-01-04", "Miraç Kandili", "kandil", "Resûlullah'ın Mi'rac'a yükselişinin yıl dönümü gecesi."),
    ("2027-01-22", "Berat Kandili", "kandil", "Şaban ayının on beşinci gecesi."),
    ("2027-02-07", "İlk Teravih", "gun", "Ramazan'ın ilk gecesi; ilk teravih namazı kılınır."),
    ("2027-02-08", "Ramazan Başlangıcı", "gun", "İlk oruç."),
    ("2027-03-05", "Kadir Gecesi", "kandil", "Bin aydan daha hayırlı gece (Kadr 97:3)."),
    ("2027-03-08", "Ramazan Bayramı Arefesi", "arefe", ""),
    ("2027-03-09", "Ramazan Bayramı 1. Gün", "bayram", ""),
    ("2027-03-10", "Ramazan Bayramı 2. Gün", "bayram", ""),
    ("2027-03-11", "Ramazan Bayramı 3. Gün", "bayram", ""),
    ("2027-05-15", "Kurban Bayramı Arefesi", "arefe", ""),
    ("2027-05-16", "Kurban Bayramı 1. Gün", "bayram", ""),
    ("2027-05-17", "Kurban Bayramı 2. Gün", "bayram", ""),
    ("2027-05-18", "Kurban Bayramı 3. Gün", "bayram", ""),
    ("2027-05-19", "Kurban Bayramı 4. Gün", "bayram", ""),
    ("2027-06-06", "Hicrî Yılbaşı (1449)", "gun", "Muharrem ayının ilk günü."),
    ("2027-06-15", "Aşure Günü", "gun", "Muharrem ayının onuncu günü."),
    ("2027-08-13", "Mevlid Kandili", "kandil", "Resûlullah'ın doğumunun yıl dönümü gecesi."),
    ("2027-11-29", "Üç Ayların Başlangıcı", "gun", ""),
    ("2027-12-02", "Regaib Kandili", "kandil", ""),
    ("2027-12-24", "Miraç Kandili", "kandil", ""),
]
DINI = {"kaynak": "Diyanet İşleri Başkanlığı dinî günler takvimi (basında yayımlanan 2026-2027 duyuruları)",
        "gunler": [{"tarih": t, "ad": a, "tur": k, "aciklama": d} for t, a, k, d in GUNLER]}

if HATA:
    print("\n".join(HATA))
    sys.exit(1)

yaz = lambda ad, veri: (HEDEF / ad).write_text(json.dumps(veri, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
yaz("dualar.json", {"temalar": TEMALAR, "defter": DEFTER})
yaz("esma.json", [{"no": i + 1, "ad": a, "arapca": ar, "anlam": an, "aciklama": ac} for i, (a, ar, an, ac) in enumerate(ESMA)])
yaz("dinigunler.json", DINI)
VERI = KOK / "Tasarim" / "veri"
shutil.copyfile(VERI / "buhari_nihai.json", HEDEF / "hadisler.json")
shutil.copyfile(VERI / "hikmetler.json", HEDEF / "hikmetler.json")
shutil.copyfile(VERI / "vakitler_bursa.json", HEDEF / "vakitler.json")
print("Tamam:", sum(len(t["dualar"]) for t in TEMALAR), "konulu dua ·", len(DEFTER["bolumler"]), "defter bölümü ·", len(ESMA), "isim ·", len(GUNLER), "dinî gün")
