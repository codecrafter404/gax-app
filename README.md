# [G]ate [A]cces X
the app for the [firmware](https://github.com/codecrafter404/gax).

# What is this project about
I've got an automatic garden gate, which can be triggered using a bulky remote. Since we're moving towards a smartphone controllable world, the gate has to follow. An "normal" Wifi-Controlled solution won't do the job, because no one has wifi around thier gate, right?😅

# Prerequisits
- ESP32 (only tested with the Xtensa architecture)
- breadboard (or sth. similar for wireing your gate and led)
- Android Phone
- PC (to build) with installed Rust toolchain

# Setup
- build the firmware and flash it to the firmware as described [here](https://github.com/codecrafter404/gax?tab=readme-ov-file#how-to-build)
- Download and install the APK from the [Github Releases]()
- Scan the QR-Code obtained while flashing the firmware -> have fun 🤗

# Vison (TODO's)
- [x] you scan a QR-Code with all the reqired information
- [x] you can simply open the gate by the press of a button
- [x] alternatively, you can press a button in your QuickAccess-Bar to open the gate
- [x] in order to prevent spamming, the app will force its users to confirm thier identity when opening the gate, using biometrics or something similar
- [x] you can see metadata about the device
    - [x] Power-On-Hours
    - [x] Access-Log (scince powered on)
- [X] Docoumentation📘
