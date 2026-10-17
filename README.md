# Expense Tracker

A beginner-friendly full-stack personal finance app for a college project.

- **Frontend:** Flutter (Dart) with Material 3 and Provider
- **Backend:** FastAPI (Python) REST API
- **Database:** Supabase PostgreSQL

The Flutter app never talks to the database directly. It calls the FastAPI API. The API stores users, categories, and transactions in PostgreSQL and keeps each user's data private.

## Keep credentials private

The backend `.env` file contains your Supabase database URL and JWT secret. Never commit or publish it. The repository `.gitignore` excludes `.env` files; check `git status` before committing to make sure no secrets are staged.

## What you can do

- Register and log in (passwords are hashed, sessions use JWT)
- Add, edit, and delete income and expense transactions
- See total income, total expenses, and current balance
- Search and filter transactions
- Create, rename, and delete your own categories
- View monthly income vs expenses and spending by category
- Switch light / dark / system theme
- Log out and log back in with the same saved data

## Project layout

```
expense-tracker/
  backend/          FastAPI application
    app/
      main.py       App startup, CORS, error handlers
      config.py     Environment variables
      database.py   SQLAlchemy + PostgreSQL
      security.py   Password hashing and JWT
      models/       Database tables
      schemas.py    Request / response models
      routers/      HTTP endpoints
      services/     Business logic
  frontend/         Flutter application
    lib/
      screens/      UI screens
      providers/    App state (Provider)
      services/     HTTP API calls
      models/       Data classes
```

## 1. Configure Supabase

1. Create a project at [https://supabase.com](https://supabase.com).
2. Open **Project Settings → Database**.
3. Copy the **URI** connection string. It looks like:

   `postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres`

4. Replace `[YOUR-PASSWORD]` with the database password you set when creating the project.
5. Add `?sslmode=require` at the end if it is not already there.
6. The API creates missing tables automatically when it starts.

## 2. Configure the backend

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
New-Item .env
```

On macOS / Linux:

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
touch .env
```

Edit `.env`:

```
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@db.YOUR_PROJECT.supabase.co:5432/postgres?sslmode=require
JWT_SECRET=paste-a-long-random-string-here
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=10080
CORS_ORIGINS=*
```

Create a JWT secret:

```powershell
python -c "import secrets; print(secrets.token_hex(32))"
```

Do not commit `.env`. It contains secrets.

## 3. Start FastAPI

From the project root, run the Windows launcher. It uses the backend virtual environment directly, so the global Python installation is not used by mistake:

```powershell
.\backend\start_backend.ps1
```

If PowerShell blocks local scripts, run this once for your user account and then start the backend again:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Open [http://localhost:8000/health](http://localhost:8000/health). You should see `{"status":"ok"}`.

API docs: [http://localhost:8000/docs](http://localhost:8000/docs)

Keep this terminal running while you use the Flutter app.

## 4. Configure and run Flutter

```powershell
cd frontend
flutter pub get
flutter run
```

Default API URLs (already set in `lib/constants/api_constants.dart`):

| Where you run the app | API base URL |
| --- | --- |
| Windows / macOS / Linux desktop | `http://localhost:8000/api` |
| Chrome / web | `http://localhost:8000/api` |
| Android emulator | `http://10.0.2.2:8000/api` |

If the app is on a physical phone, use your computer's LAN IP:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Replace `192.168.1.10` with your PC's IPv4 address. The phone and PC must be on the same Wi-Fi, and the FastAPI server must be started with `--host 0.0.0.0`.

## Demo flow for presentation

1. Register a new account.
2. Log in (you are logged in automatically after register).
3. Add an income (for example Salary) and an expense (for example Food).
4. Confirm the dashboard balance is income minus expenses.
5. Open History, search, and filter by type / category / date.
6. Edit and delete a transaction and watch the balance update.
7. Create a custom category.
8. Open Analytics for the monthly chart and category pie chart.
9. Log out, log back in, and show that the data is still there.

## Default categories

Created automatically for every new user:

- **Expense:** Food, Transport, Shopping, Bills, Entertainment, Education, Health, Other
- **Income:** Salary, Freelance, Business, Gift, Other

## API overview

All routes below except register/login require a bearer token:

```http
Authorization: Bearer <access_token>
```

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/api/auth/register` | Create account |
| POST | `/api/auth/login` | Log in |
| GET | `/api/auth/me` | Current user |
| GET/POST | `/api/categories` | List / create categories |
| PUT/DELETE | `/api/categories/{id}` | Update / delete a category |
| GET/POST | `/api/transactions` | List (with filters) / create |
| PUT/DELETE | `/api/transactions/{id}` | Update / delete |
| GET | `/api/analytics/summary` | Totals and balance |
| GET | `/api/analytics/monthly` | Monthly income and expenses |
| GET | `/api/analytics/by-category` | Expense totals by category |

Query parameters for transactions: `type`, `category_id`, `start_date`, `end_date`, `search`.

Every query is filtered by the logged-in user id from the JWT, so one student cannot read another student's rows.

## Common problems

**Cannot reach the server**

Start FastAPI first. If you use an Android emulator, keep the default `10.0.2.2` URL. If you use a real phone, pass `--dart-define=API_BASE_URL=...` with your PC IP.

**Database connection error**

Check that your Supabase project is running and that `DATABASE_URL` contains the correct database password and `sslmode=require`. The API creates its tables automatically when it starts.

**Incorrect email or password**

Use the same email you registered. Passwords are stored as hashes, not plain text.

**Category cannot be deleted**

Move or delete transactions that still use that category.

**Python 3.14 notes**

This project uses current FastAPI / Pydantic / `psycopg` packages that have Python 3.14 wheels. If `pip install` tries to compile old packages, upgrade pip and install from `requirements.txt` again.

## Architecture in one sentence

Flutter screens → Provider → HTTP services → FastAPI routers → services → SQLAlchemy models → Supabase PostgreSQL.
