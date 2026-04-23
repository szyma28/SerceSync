# SerceSync Mobile

Flutter client for carers and nurses.

It covers login, mandatory handover acknowledgement, priorities, residents, resident detail, `My Shift`, medication rounds, and offline-capable text note / incident capture with queued sync.

## Run

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

If `API_BASE_URL` is omitted, the app defaults to `http://localhost:3000`.

Useful checks:

```bash
flutter analyze
flutter test
```
