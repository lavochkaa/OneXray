# MIRA VPN

iOS VPN client based on [Xray-core](https://github.com/XTLS/Xray-core), built for [TrollStore](https://github.com/opa334/TrollStore) installation. Fork of [OneXray](https://github.com/OneXray/OneXray).

## Requirements

- iOS 15.0+
- TrollStore 2.x (for unsigned installation)

## Install

Download `OneXray-unsigned.tipa` from [Releases](../../releases/latest) and open with TrollStore.

## Build

Builds run automatically via GitHub Actions on every push — download the artifact from the Actions tab.

**Manual build:**

```bash
# 1. Clone patched Xray-core (adds sessionIdFormat field to xhttp)
git clone --branch xhttp-session-id-format https://github.com/XXcipherX/Xray-core.git ../Xray-core

# 2. Clone and build libXray (CGo mode — NOT gomobile)
git clone https://github.com/lavochkaa/libXray.git
cd libXray && python3 build/main.py apple go local && cd ..
cp -r libXray/LibXray.xcframework swift/All/LibXray.xcframework

# 3. Flutter build
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release --no-codesign

# 4. Sign with ldid (required for TrollStore Network Extension permissions)
ldid -Sios/Runner/Runner.entitlements build/ios/iphoneos/Runner.app/Runner
ldid -Sios/tunnel/tunnel.entitlements build/ios/iphoneos/Runner.app/PlugIns/tunnel.appex/tunnel

# 5. Package as .tipa
mkdir Payload && cp -r build/ios/iphoneos/Runner.app Payload/
zip -r OneXray-unsigned.tipa Payload/
```

## Key patches vs upstream

| Area | Change |
|------|--------|
| **xhttp CDN** | `sessionIdFormat: random-hex` on all xhttp outbounds — prevents CDN WAF from blocking UUID-shaped session IDs |
| **TrollStore NE** | `ldid` entitlement embedding so the Network Extension gets VPN permissions without a developer account |
| **App Group fallback** | Documents directory fallback when App Group container is unavailable (TrollStore) |
| **providerConfiguration** | `xrayJson` always embedded so the tunnel extension can start even when the shared container is inaccessible |
| **Subscription seeding** | Default MIRA subscription auto-imported on first launch |

## Architecture

```
lib/          Flutter/Dart app
ios/          iOS Xcode project (Runner + tunnel extension)
swift/
  App/        Swift app-side code (VPN manager, pigeon host API)
  Tunnel/     Network Extension (PacketTunnelProvider)
  All/        Shared Swift code + LibXray.xcframework
```

The tunnel extension runs in a separate sandboxed process. Data flow:
- **Pigeon** — Flutter ↔ Swift IPC (generated bindings in `lib/core/pigeon/`)
- **providerConfiguration** — app embeds `xrayJson` + `request` so the NE can start on demand
- **handleAppMessage XPC** — app sends dat files + start signal to the tunnel after it connects
