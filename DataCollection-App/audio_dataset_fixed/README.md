# 🎙️ Audio Dataset System v2.0

A complete hierarchical dataset collection platform with Admin and Level1 roles.

---

## 🏗️ Tech Stack
- **Backend**: FastAPI (Python) + PostgreSQL + JWT Auth
- **Frontend**: Flutter (Riverpod + Clean Architecture)
- **Storage**: Local file storage (`uploads/` folder)
- **Payments**: Internal wallet system

---

## 🚀 Quick Start

### 1. Backend Setup

#### Prerequisites
- Python 3.10+
- PostgreSQL running locally

#### Steps

```bash
cd backend

# 1. Copy env file and configure
cp .env.example .env
# Edit .env → set your DATABASE_URL

# 2. Create PostgreSQL database
psql -U postgres -c "CREATE DATABASE audio_dataset;"

# 3. Install dependencies & run
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be live at `http://localhost:8000`
Swagger docs at `http://localhost:8000/docs`

#### Default Users (auto-seeded on first run)
| Role    | Email                   | Password    |
|---------|-------------------------|-------------|
| Admin   | admin@example.com       | admin123    |
| Level 1 | level1@example.com      | level1123   |

---

### 2. Flutter App Setup

#### Prerequisites
- Flutter 3.19+ SDK
- Android Studio / VS Code
- Android emulator or physical device

#### Steps

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Run on Android emulator (uses 10.0.2.2 → localhost)
flutter run

# Run on physical device → first update API base URL:
# Edit: lib/core/constants/api_constants.dart
# Change: static const String baseUrl = 'http://YOUR_MACHINE_IP:8000';
```

---

## 📱 App Features

### Admin
- 📊 Dashboard with live statistics
- ✅ Create & assign tasks to Level1 users
- 📂 View all submitted files (audio, video, doc, pdf, etc.)
- ✔️ Approve / Reject submissions with remarks
- 💰 Auto-credit wallet on approval
- 👥 Manage Level1 users, view profiles, add wallet balance
- 👤 Full profile with personal, KYC & bank details

### Level 1
- 🏠 Personal dashboard with task & submission stats
- 📋 View assigned tasks with instructions
- ▶️ Start tasks, then upload work (any file format)
- 📤 Submit work with notes and multiple file uploads
- 📊 Track submission status (pending/approved/rejected)
- 💳 Wallet with transaction history
- 👤 Full profile with personal, KYC & bank details

---

## 📁 File Upload Support
- Audio: mp3, wav, m4a, ogg
- Video: mp4, mov, avi
- Documents: pdf, doc, docx, txt
- Images: jpg, png, webp
- Any other format

---

## 🗂️ Project Structure

```
project/
├── backend/
│   ├── app/
│   │   ├── main.py           # FastAPI entry point
│   │   ├── config.py         # Settings
│   │   ├── database.py       # DB connection
│   │   ├── models/           # SQLAlchemy models
│   │   ├── schemas/          # Pydantic schemas
│   │   ├── routers/          # API routes
│   │   └── utils/            # Auth utilities
│   ├── uploads/              # File storage
│   └── requirements.txt
│
└── flutter_app/
    └── lib/
        ├── main.dart
        ├── core/
        │   ├── constants/    # API URLs
        │   ├── network/      # Dio client
        │   └── theme/        # App theme
        ├── features/
        │   ├── auth/         # Login, signup
        │   ├── admin/        # Admin screens
        │   ├── level1/       # Level1 screens
        │   ├── profile/      # Profile screen
        │   └── wallet/       # Wallet screen
        └── shared/
            ├── models/       # Data models
            └── widgets/      # Reusable widgets
```

---

## 🔧 Troubleshooting

**Login Error**: Make sure the backend is running on port 8000 before launching the Flutter app.

**Network Error on Physical Device**: Change `baseUrl` in `api_constants.dart` from `10.0.2.2` to your machine's local IP address (e.g., `192.168.1.5`).

**Database Error**: Ensure PostgreSQL is running and the `audio_dataset` database exists.

**File Upload Failing**: Check that the `uploads/` folder exists inside the `backend/` directory.
