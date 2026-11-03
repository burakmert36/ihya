import json, os
B = '/tmp/claude-0/-home-claude/c80d420a-8fe8-580b-b152-3f41d5b4ce41/scratchpad/'
ENGINE = open(B + 'engine/bitki.js').read()
DEFS = open(B + 'engine/defs.svg').read().strip()
OUT = B + 'mihrap/project/'

GLASS = """
body{margin:0}
a{color:inherit;text-decoration:none}
button{font-family:inherit;border:0;cursor:pointer}
*{box-sizing:border-box;-webkit-tap-highlight-color:transparent}
/* iOS 27 Liquid Glass — görünür cam: berrak gövde, koyu kenar çizgisi, parlak speküler üst ışık, alt kenarda kırılma parıltısı */
.g27,.g27k,.g27t{position:relative;isolation:isolate}
.g27{background:linear-gradient(180deg,rgba(255,255,255,.34),rgba(255,255,255,.12) 55%,rgba(255,255,255,.20));-webkit-backdrop-filter:blur(7px) saturate(210%) brightness(1.08);backdrop-filter:blur(7px) saturate(210%) brightness(1.08);border:.5px solid rgba(255,255,255,.75);box-shadow:inset 0 2px 1px -1px rgba(255,255,255,1),inset 0 -2px 3px -1px rgba(255,255,255,.55),inset 0 0 0 1px rgba(255,255,255,.22),inset 0 -12px 22px -14px rgba(120,200,255,.45),0 0 0 .75px rgba(8,28,40,.38),0 14px 34px rgba(8,30,20,.22)}
.g27k{background:linear-gradient(180deg,rgba(255,255,255,.20),rgba(255,255,255,.06) 55%,rgba(255,255,255,.12));-webkit-backdrop-filter:blur(8px) saturate(200%) brightness(1.1);backdrop-filter:blur(8px) saturate(200%) brightness(1.1);border:.5px solid rgba(255,255,255,.45);box-shadow:inset 0 2px 1px -1px rgba(255,255,255,.85),inset 0 -2px 3px -1px rgba(255,255,255,.28),inset 0 0 0 1px rgba(255,255,255,.10),inset 0 -12px 22px -14px rgba(140,220,255,.40),0 0 0 .75px rgba(0,0,0,.6),0 16px 36px rgba(0,0,0,.38)}
.g27t{color:#FFFFFF;background:linear-gradient(180deg,rgba(96,236,150,.96),rgba(20,158,82,.94));-webkit-backdrop-filter:blur(6px) saturate(190%);backdrop-filter:blur(6px) saturate(190%);border:.5px solid rgba(255,255,255,.8);box-shadow:inset 0 2px 1px -1px rgba(255,255,255,1),inset 0 -3px 5px -2px rgba(0,70,35,.35),inset 0 0 0 1px rgba(255,255,255,.18),0 0 0 .75px rgba(0,60,30,.5),0 12px 28px rgba(20,150,70,.42)}
.g27::before,.g27k::before,.g27t::before{content:"";position:absolute;inset:0;border-radius:inherit;pointer-events:none;z-index:-1;background:radial-gradient(130% 75% at 20% -5%,rgba(255,255,255,.62),rgba(255,255,255,0) 52%),radial-gradient(90% 60% at 100% 110%,rgba(255,255,255,.28),rgba(255,255,255,0) 60%)}
.g27k::before{background:radial-gradient(130% 75% at 20% -5%,rgba(255,255,255,.32),rgba(255,255,255,0) 52%),radial-gradient(90% 60% at 100% 110%,rgba(160,230,255,.18),rgba(255,255,255,0) 60%)}
.g27::after,.g27k::after,.g27t::after{content:"";position:absolute;left:12%;right:12%;top:1px;height:1px;border-radius:1px;background:linear-gradient(90deg,rgba(255,255,255,0),rgba(255,255,255,.95),rgba(255,255,255,0));pointer-events:none}
.bas{transition:transform .22s cubic-bezier(.3,1.7,.5,1)}
.bas:active{transform:scale(.93)}
@keyframes sal{0%,100%{transform:rotate(-1.4deg)}50%{transform:rotate(1.6deg)}}
.sal{animation:sal 6.4s ease-in-out infinite;transform-box:fill-box;transform-origin:50% 100%}
@keyframes yuk{0%{opacity:0;transform:translateY(16px) scale(.97)}100%{opacity:1;transform:none}}
.yuk{animation:yuk .45s cubic-bezier(.3,1.35,.5,1) both}
@keyframes isil{0%,100%{opacity:.55}50%{opacity:1}}
.isil{animation:isil 3.2s ease-in-out infinite}
@keyframes bulut{0%{transform:translateX(0)}100%{transform:translateX(24px)}}
.bulut{animation:bulut 16s ease-in-out infinite alternate}
@media (prefers-reduced-motion: reduce){.sal,.isil,.bulut,.yuk{animation:none}}
/* Kaydırma kuralı: yatay şerit yalnız yatay kayar (yön kilidi), dikey liste yalnız dikey; taşma üst kaba zincirlenmez */
html,body{overscroll-behavior:none}
.yatay{display:flex;overflow-x:auto;overflow-y:hidden;overscroll-behavior:contain;touch-action:pan-x;scrollbar-width:none;-webkit-overflow-scrolling:touch;scroll-snap-type:x proximity}
.yatay::-webkit-scrollbar{display:none}
.yatay>*{flex:none;scroll-snap-align:start}
.dikey{overflow-y:auto;overflow-x:hidden;overscroll-behavior:contain;touch-action:pan-y;scrollbar-width:none}
.dikey::-webkit-scrollbar{display:none}
"""

# Yatay şerit için fare tekerleği: dikey tekeri yataya çevirir, olayı üst kaba (tuval) iletmez
YATAY_JS = """
function yatayTeker(ev) { var el = ev && ev.currentTarget; if (!el) return; if (ev.stopPropagation) ev.stopPropagation(); if (Math.abs(ev.deltaY) > Math.abs(ev.deltaX)) el.scrollLeft += ev.deltaY; }
"""

def page(title, w, h, body, script, extra_css='', head=''):
    return ('<!doctype html>\n<html lang="tr">\n<head>\n<meta charset="utf-8">\n<title>' + title + '</title>\n<script src="./support.js"></script>\n</head>\n<body>\n<x-dc>\n<helmet>\n'
            '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;family=Newsreader:opsz,wght@6..72,500;6..72,600&amp;display=swap">\n' + head +
            '<style>' + GLASS + extra_css + '</style>\n</helmet>\n' + body + '\n</x-dc>\n'
            '<script type="text/x-dc" data-dc-script data-props=\'{"$preview":{"width":' + str(w) + ',"height":' + str(h) + '}}\'>\n'
            + ENGINE + '\n' + script + '\n</script>\n</body>\n</html>\n')

PATHS = '<sc-for list="{{SRC}}" as="s"><path d="{{s.d}}" fill="{{s.f}}" stroke="{{s.s}}" stroke-width="{{s.w}}" opacity="{{s.o}}" stroke-linecap="round" stroke-linejoin="round"></path></sc-for>'
def paths(src): return PATHS.replace('SRC', src)

# Ortak sekme çubuğu (İhya dili): 4 sekme + Odaklan düğmesi. Simgeler SVG, 24×24 kutuda ortalı.
IKON = {
    'bugun': '<circle cx="12" cy="12" r="4.2" fill="none" stroke="currentColor" stroke-width="1.9"></circle><path d="M12 2.6v2.3M12 19.1v2.3M2.6 12h2.3M19.1 12h2.3M5.4 5.4l1.6 1.6M17 17l1.6 1.6M5.4 18.6 7 17M17 7l1.6-1.6" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"></path>',
    'bahce': '<path d="M12 21.2v-8.4" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"></path><path d="M12 14.4C12 9.8 9 7.2 4 7.2c0 4.6 3 7.2 8 7.2Z" fill="currentColor"></path><path d="M12 11.6c0-4.8 3-7.8 8-7.8 0 4.8-3 7.8-8 7.8Z" fill="currentColor" opacity=".72"></path>',
    'kitap': '<path d="M3 5.6c3.2-1.1 6.2-.8 9 1.2 2.8-2 5.8-2.3 9-1.2v13.2c-3.2-1.1-6.2-.8-9 1.2-2.8-2-5.8-2.3-9-1.2Z" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linejoin="round"></path><path d="M12 6.8V20" fill="none" stroke="currentColor" stroke-width="1.9"></path>',
    'vakit': '<circle cx="12" cy="12" r="8.6" fill="none" stroke="currentColor" stroke-width="1.9"></circle><path d="M12 7.4V12l3.2 2.1" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"></path>',
}
SEKME = [('Bugün', 'IhyaBugun.dc.html', 'bugun'), ('Bahçe', 'IhyaBahce.dc.html', 'bahce'), ('Kitaplık', 'IhyaKitaplik.dc.html', 'kitap'), ('Vakit', 'VakitCetveli.dc.html', 'vakit')]
def tabbar(cur, koyu=False):
    cls = 'g27k' if koyu else 'g27'
    on_c, on_bg = ('#FFFFFF', 'rgba(255,255,255,.20)') if koyu else ('#0E6A33', 'rgba(255,255,255,.58)')
    off_c = 'rgba(236,242,255,.74)' if koyu else '#2E4A3A'
    items = ''
    for ad, href, ik in SEKME:
        on = ad == cur
        items += ('<a href="%s" aria-current="%s" class="bas" style="position: relative; height: 52px; border-radius: 26px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; font-size: 10.5px; line-height: 12px; font-weight: 700; color: %s; background: %s">'
                  '<svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true">%s</svg>%s</a>') % (href, 'page' if on else 'false', on_c if on else off_c, on_bg if on else 'transparent', IKON[ik], ad)
    return ('<nav aria-label="Sekmeler" class="%s" style="position: absolute; left: 16px; bottom: 30px; width: 278px; height: 64px; border-radius: 32px; display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); align-items: center; padding: 0 6px; z-index: 20">%s</nav>'
            '<a href="IhyaOdak.dc.html" class="g27t bas" aria-label="Odaklan, yeni oturum" style="position: absolute; right: 16px; bottom: 30px; width: 64px; height: 64px; border-radius: 32px; display: flex; align-items: center; justify-content: center; z-index: 20">'
            '<svg width="26" height="30" viewBox="0 0 26 30" aria-hidden="true" style="position: relative"><path d="M13 29V14" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round"></path><path d="M13 16C13 9 8 6 2 6C2 12 6 16 13 16Z" fill="#FFFFFF"></path><path d="M13 13C13 6 17 2 24 2C24 9 19 13 13 13Z" fill="#E6FFE9"></path></svg></a>') % (cls, items)
