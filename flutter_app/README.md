# sharetribe_flutter

The Flutter app for the Sharetribe assessment: logs in to a Sharetribe
marketplace and lists its listings. Setup, credentials and the Sharetribe
steps are in the [repo README](../README.md).

```bash
make verify                     # flutter analyze + flutter test (the definition of done)
flutter run                     # mock mode, offline; customer@test.com / password123
make e2e DEVICE=<device-id>     # end-to-end on a simulator; also writes ../docs/screenshots/
```

Layout: `lib/core` (Env, Result, AppError), `lib/domain` (models and
repository interfaces), `lib/data` (JSON:API, the dio client, mock and live
repositories), `lib/presentation` (Cubits and pages).
