"""En yeni iOS çalışma zamanında iPhone 17 simülatörünü seçer (yoksa oluşturur). Çıktı: '<udid> <ad>'."""
import json
import subprocess


def j(*a):
    return json.loads(subprocess.check_output(["xcrun", "simctl", "list", "-j", *a]))


runtimes = [r for r in j("runtimes", "available")["runtimes"] if "iOS" in r["name"]]
runtimes.sort(key=lambda r: [int(x) for x in r["version"].split(".")])
rt = runtimes[-1]
devs = j("devices", "available")["devices"].get(rt["identifier"], [])
pick = next((d for d in devs if d["name"] == "iPhone 17"), None)
if pick is None:
    t = next((t for t in j("devicetypes")["devicetypes"] if t["name"] == "iPhone 17"), None)
    if t is not None:
        udid = subprocess.check_output(["xcrun", "simctl", "create", "iPhone 17", t["identifier"], rt["identifier"]]).decode().strip()
        pick = {"udid": udid, "name": "iPhone 17"}
if pick is None:
    pick = [d for d in devs if d["name"].startswith("iPhone")][-1]
print(pick["udid"], (pick["name"] + "_" + rt["name"]).replace(" ", "_"))
