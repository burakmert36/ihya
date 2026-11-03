# İhya · proje kuralları

Kişisel, yalnız sahibinin iPhone'unda çalışan İslami odak ve ibadet uygulaması.
Şartname: https://claude.ai/artifact/TCWCsstU47HhLm8mH8ak6F · Tasarım tuvali: https://claude.ai/artifact/NRmdaXj1FjQ3XorUqpFFPU

## Çalışma kuralları

- Kullanıcıyla Türkçe konuş. Yanıtlar sade, kısa cümleli (basitleştirilmiş teknik dil).
- Kullanıcı kodla uğraşmak istemez: kararları sen ver, yalnız geri alınamaz ya da zevke bağlı konularda sor.
- Hadisler yalnız Sahîh-i Buhârî'den; her yeni hadis/söz/âyet kaynağına karşı doğrulanır (`Tasarim/testler/dogrula.py`).
- Emoji simge olarak kullanılmaz; simgeler SF Symbols ya da aynı çizgi kalınlığında özel çizim.
- Yatay şeritler yalnız yatay kayar; dikey jest ekranı oynatmaz.

## Araçlar

- Proje kapsamında eklentiler `.claude/settings.json` içinde. Caveman varsayılan olarak kapalı başlar (`.caveman.json`).
- Graphify: her önemli değişiklikten sonra `graphify update .` ile kod haritasını yenile; sorularda önce `graphify query` kullan. `graphify-out/` depoya girmez.
- Testler: `Tasarim/testler/` tasarım aşamasında kaynak külliyatlarla (Buhârî, Diyanet meali) çalıştı; A0 aşamasında bu külliyatlar `Tasarim/kaynak/` altına alınıp testler depoya uyarlanacak. Swift tarafında aynı kontroller `IhyaCoreTests` içinde.

## Klasörler

- `Tasarim/` · tasarım aşamasının çıktıları: bitki motoru (`motor/bitki.js`), veri (`veri/`), ses döngüleri (`ses/`), üretim betikleri (`uretim/`), testler (`testler/`).
- Swift uygulaması (A0 aşamasında eklenecek): `project.yml`, `App/`, `Widgets/`, `Packages/` (IhyaCore, IhyaPlants, IhyaPrayer, IhyaAudio, IhyaContent, IhyaUI).

## Commit

- Mesajlar Türkçe; uygulama derlemesini tetiklemeyecek değişikliklerde `[skip ci]`.
