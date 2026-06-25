# Shelf

A personal library management app: book shelf, adding books via barcode
scanner / ISBN search / manual entry, reading progress tracking, and
quotes captured through on-device OCR.

## Architecture

```
flutter_app/  -> Flutter app. Talks DIRECTLY to Supabase (full CRUD:
                 shelf, reading progress, quotes) via supabase_flutter + RLS.

backend/      -> Python microservice (FastAPI) with a SINGLE
                 responsibility: looking up book data by ISBN
                  (Open Library), caching the
                 result in the `books` table using the service_role key.

supabase/     -> schema.sql with all tables, the `shelf_view` view, and
                 every Row Level Security policy. Run it in your
                 project's SQL Editor.
```

Why split it this way? Simple CRUD operations (adding a book to the
shelf, updating the current page, saving a quote) don't need any
business logic — Supabase with RLS already guarantees each user only
accesses their own data. Python only comes in where it actually
matters: calling external APIs and keeping the service_role key out of the client app.

## 1. Set up Supabase

1. Create a project at https://supabase.com.
2. Go to **SQL Editor**, paste the contents of `supabase/schema.sql`,
   and run it.
3. Under **Authentication > Providers**, enable "Email" (email/password
   login, already used in the app). For quick prototyping, you can
   disable email confirmation in Authentication > Settings.
4. Under **Project Settings > API**, copy:
   - `Project URL` and `anon public key` -> used by the Flutter app.
   - `service_role key` -> used ONLY by the Python backend, never in
     the Flutter app.

## 2. Set up and run the Python backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# edit .env with SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY

uvicorn app.main:app --reload --port 8000
```

Quick test:

```bash
curl "http://localhost:8000/api/books/lookup?isbn=9788535914849"
```

For production, deploy to Railway, Render, Fly.io, or any small VM
with Docker. It's a stateless service, so it doesn't need much
resources.

## 3. Set up Flutter

```bash
cd flutter_app
flutter pub get
```

Copy `.env.example` to `.env` (same folder, at the root of
`flutter_app/`) and fill it in with your Supabase project's data:

```bash
cp .env.example .env
```

```env
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_ANON_KEY=ey... (paste your anon public key here)
BACKEND_BASE_URL=http://10.0.2.2:8000
```

Where to find each value:
- `SUPABASE_URL` and `SUPABASE_ANON_KEY` -> Supabase dashboard, under
  **Project Settings > API**. The *anon key* is safe to ship inside
  the app: it only unlocks whatever your RLS policies allow, unlike
  the *service_role key* (which stays in the backend only).
- `BACKEND_BASE_URL` -> depends on where you're testing:
  - Android emulator -> `http://10.0.2.2:8000`
  - iOS simulator -> `http://localhost:8000`
  - Physical device or production -> your backend's public URL (e.g.
    `https://your-backend.onrender.com`)

The `.env` file is already in `.gitignore` — it will never be
committed by accident. Anyone cloning the project just repeats
`cp .env.example .env` and fills in their own values.

Loading happens automatically in `main.dart`, before any other
initialization:

```dart
await dotenv.load(fileName: '.env');
await SupabaseService.initialize();
```

### Native permissions (required before running on a real device)

- Android: follow `android_config/AndroidManifest_instrucoes.txt`
- iOS: follow `ios_config/Info_plist_instrucoes.txt`

### Running the app

```bash
flutter devices          # list available emulators/devices
flutter run -d <device_id>
```

> **Important — Web is not supported.** `mobile_scanner` (barcode
> scanning) and `google_mlkit_text_recognition` (OCR) are mobile-only
> packages with no web implementation. Always run this app on an
> Android emulator, iOS simulator, or a physical device — not on
> Chrome. If you only need to poke at non-camera screens (login,
> shelf, manual entry) in a browser, see
> `flutter_app/web/INDEX_HTML_passkeys_fix.txt` for the extra script
> tag `supabase_flutter` requires on web; camera-dependent screens
> will still be unavailable there either way.

## 4. App flow

1. **Login/sign-up** via email and password (Supabase Auth).
2. **Shelf**: grid of books filterable by status (To read / Reading /
   Finished / Abandoned). Books marked "Reading" show a progress bar.
3. **Add book** (+ button), three paths:
   - **Scan**: `mobile_scanner` reads the barcode (EAN-13/UPC-A) ->
     calls the backend -> pre-fills the confirmation form.
   - **Search by ISBN**: same backend call, typed ISBN instead of
     scanned.
   - **Manual**: empty form, user fills in everything.
   - In every case, the final save happens **directly in Supabase**
     from Flutter (upsert into `books` + insert into `user_books`).
4. **Book detail**: change status, update the current page (the
   `shelf_view` view automatically recalculates `progress_percent`),
   and add quotes.
5. **Add quote**: take a photo of a book excerpt ->
   `google_mlkit_text_recognition` runs OCR **on-device** (no image is
   ever sent to any server) -> the extracted text appears editable ->
   the user reviews and saves it.

## Project structure

```
shelf_app/
├── README.md
├── .gitignore
├── supabase/
│   └── schema.sql
├── backend/
│   ├── requirements.txt
│   ├── .env.example
│   └── app/
│       ├── main.py
│       ├── config.py
│       ├── models.py
│       ├── supabase_client.py
│       ├── routers/
│       │   └── books.py
│       └── services/
│           └── isbn_lookup.py
└── flutter_app/
    ├── pubspec.yaml
    ├── .env.example
    ├── android_config/
    ├── ios_config/
    └── lib/
        ├── main.dart
        ├── config.dart
        ├── theme/
        ├── models/
        │   ├── book.dart
        │   ├── user_book.dart
        │   └── quote.dart
        ├── services/
        │   ├── supabase_service.dart
        │   ├── auth_repository.dart
        │   ├── shelf_repository.dart
        │   ├── isbn_lookup_service.dart
        │   └── ocr_service.dart
        ├── widgets/
        │   └── book_card.dart
        └── screens/
            ├── auth/
            ├── shelf/
            ├── add_book/
            │   ├── add_book_screen.dart
            │   ├── manual_form_screen.dart
            │   ├── scan_barcode_screen.dart
            │   └── isbn_search_screen.dart
            └── book/
                ├── book_detail_screen.dart
                └── add_quote_screen.dart
```