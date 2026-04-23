# SerceSync Web

Flutter web client for managers.

It covers manager login, browser-session restore, the live dashboard, residents, reporting/export flows, and medication/eMAR oversight tools.

## Run

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

If `API_BASE_URL` is omitted, the app defaults to `http://localhost:3000`.

For the local demo/browser-session flow, a built bundle served on port `8080` is also supported:

```bash
flutter build web
cd build/web
python3 -m http.server 8080
```
