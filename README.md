# MedTrack: Patient Health & Family Care App

Offline-first personal health record app that extends into real-time family
and doctor visibility.

![screenshots](screenshots/preview.png)

## Features
- Medicine reminders with confirm-taken flow and automatic 5-minute follow-up
- Adherence history log
- Visit/report history with camera capture and PDF export
- Offline-readable QR/NFC emergency ID
- Family and doctor linking via invite code, with full vs. limited permissions
  enforced server-side and per-connection revocation
- Real-time dashboards and SOS alerts to all linked contacts (Supabase Realtime)
- AI-assisted medicine insight summaries and multi-turn symptom-to-urgency triage

## Tech stack
Flutter · Dart · Supabase (PostgreSQL, Auth, Storage, Realtime) · Local notifications · AI API

## Run locally
1. `git clone <repo-url>`
2. `flutter pub get`
3. Copy `.env.example` to `.env` and add your own Supabase keys
4. `flutter run`

## Key challenges solved
- Keeping reminders reliable offline and syncing when the connection returns
- Enforcing permission scopes on the server, not just in the UI

## Status
Personal project / In progress
