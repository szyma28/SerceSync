# SerceSync Mobile

Flutter client for carers and nurses.

It covers login, mandatory handover acknowledgement, priorities, residents, resident detail, `My Shift`, medication rounds, and offline-capable text note / incident capture with queued sync.

## Run

### iOS simulator

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

If `API_BASE_URL` is omitted, iOS defaults to `http://localhost:3000`.

### Android emulator

```bash
flutter emulators --launch Medium_Phone_API_34
flutter run -d Medium_Phone_API_34
```

If `API_BASE_URL` is omitted, Android defaults to `http://10.0.2.2:3000`, which is the Android emulator route back to the Mac host running the local API.

For a real Android device, pass a LAN-reachable API URL explicitly:

```bash
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<mac-lan-ip>:3000
```

Useful checks:

```bash
flutter analyze
flutter test
```
