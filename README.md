# MedTrack

Offline-first Flutter patient app implementing Phases 1-10 of the CareBridge/MedTrack roadmap.

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Admin web: `flutter run -d chrome -t lib/main_admin.dart`

Supabase dart-defines: `SUPABASE_URL`, `SUPABASE_ANON_KEY`

Apply `supabase/migrations/001_initial_schema.sql` and deploy edge functions under `supabase/functions/`.
