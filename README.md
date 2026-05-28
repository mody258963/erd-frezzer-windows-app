# FrostParts (erd_rezzer)

Flutter Windows ERP client for the **ERB-Frezzer** API (`/api/v1`).

## Stack

- **flutter_bloc** — state management
- **go_router** — navigation with auth, RBAC, and offline guards
- **get_it** — dependency injection
- **dio** — HTTP client
- **drift** — SQLite (catalog cache + offline `pending_invoices` only)

## Run

1. Start the Laravel API at `f:\ERB-Frezzer` (`php artisan serve`).
2. Configure API URL on login (default `http://127.0.0.1:8000`).
3. Sign in with seeded credentials, e.g. `admin@example.com` / `password`.

```bash
flutter pub get
dart run build_runner build
flutter run -d windows
```

## Offline policy

When offline, only **POS / new sales** write to local SQLite (`pending_invoices`). Use **Sync** when back online to `POST /invoices` and refresh catalog.

## Code generation

```bash
dart run build_runner build
```
