"""SideStore/AltStore kaynak dosyası (sidestore.json) üretir.

Kullanım: python3 make_source.py <ipa yolu> <sürüm> <sahip/depo>
"""
import json
import os
import sys
from datetime import datetime, timezone

ipa, version, repo = sys.argv[1], sys.argv[2], sys.argv[3]
owner = repo.split("/")[0]
size = os.path.getsize(ipa)
url = f"https://github.com/{repo}/releases/download/v{version}/Ihya.ipa"
icon = f"https://raw.githubusercontent.com/{repo}/main/Resources/Assets.xcassets/AppIcon.appiconset/icon.png"
date = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
desc = ("Odaklandıkça büyüyen bahçe, Diyanet vakitleri, Sahîh-i Buhârî hadisleri, dualar, "
        "zikir, odak sesleri ve kitaplık. Kişisel kullanım içindir.")

source = {
    "name": "İhya",
    "identifier": f"io.github.{owner.lower()}.ihya",
    "subtitle": "Kişisel İslami odak ve ibadet uygulaması",
    "iconURL": icon,
    "apps": [
        {
            "name": "İhya",
            "bundleIdentifier": "com.burakmert36.ihya",
            "developerName": owner,
            "subtitle": "Odaklandıkça büyüyen bahçe",
            "localizedDescription": desc,
            "iconURL": icon,
            "tintColor": "1BA552",
            "version": version,
            "versionDate": date,
            "downloadURL": url,
            "size": size,
            "versions": [
                {"version": version, "date": date, "downloadURL": url, "size": size, "minOSVersion": "26.0"}
            ],
            "appPermissions": {
                "entitlements": [],
                "privacy": {
                    "NSLocationWhenInUseUsageDescription": "Kıble yönünü bulunduğun yere göre doğru göstermek için."
                },
            },
        }
    ],
    "news": [],
}
print(json.dumps(source, ensure_ascii=False, indent=2))
