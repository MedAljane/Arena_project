# Arena

A full-stack sports facility booking platform with AI-powered assistants for players, managers, and administrators. Built with Flutter (mobile + web) and Strapi (Node.js headless CMS) backed by MySQL.

---

## Overview

Arena enables users to discover sports campuses, browse terrain availability, and make reservations — all assisted by role-aware AI agents capable of executing multi-step operations on the user's behalf.

**User roles:**
- **Player** — Browse campuses, search available slots, book and manage reservations, chat with staff
- **Manager** — Manage campuses and terrains, create weekly schedules, confirm reservations, chat with players
- **Employee** — View assigned terrains and monitor reservations
- **Admin** — Web dashboard for platform-wide oversight of all entities

---

## Architecture

```
flutter_project/
├── Frontend/          # Flutter app (mobile: player/manager/employee, web: admin/manager dashboard)
└── Backend/           # Strapi 5 headless CMS with custom REST APIs and AI assistants
```

**Tech stack:**

| Layer | Technology |
|---|---|
| Mobile app | Flutter 3.10+, Provider, GoRouter, Dio |
| Admin dashboard | Flutter Web |
| Backend framework | Strapi 5.43 (Node.js) |
| Database | MySQL |
| AI/LLM | Vercel AI SDK, Google Gemini 2.5 Flash (default), OpenAI GPT-4o-mini, Ollama |
| Real-time chat | Firebase Firestore |
| Geocoding | Nominatim (OpenStreetMap) |

---

## Frontend

### Structure

```
Frontend/lib/
├── main.dart                        # Entry point — routes to AdminApp (web) or ArenaApp (mobile)
├── admin/                           # Web admin dashboard
│   ├── screens/                     # Dashboard, managers, players, employees, campuses, terrains
│   ├── widgets/                     # CRUD modals, data tables, stat cards
│   └── api/admin_client.dart
├── Screens/
│   ├── shared/                      # Splash, onboarding, signup, password reset, conversation
│   ├── player/                      # Dashboard, campus map, terrain availability, bookings, chat
│   ├── manager/                     # Dashboard, campus/terrain/agenda management, employee list
│   └── employee/
├── services/                        # Business logic; one service per domain
│   ├── auth/auth_service.dart
│   ├── ai/ai_service.dart           # POST /ai/player-chat and /ai/manager-chat
│   ├── campus/campus_service.dart
│   ├── terrain/terrain_service.dart
│   ├── reservation/reservation_service.dart
│   ├── week_agenda/week_agenda_service.dart
│   ├── employee/employee_service.dart
│   ├── message/message_service.dart # Firebase Firestore chat
│   └── ...
├── models/                          # Data classes (User, Campus, Terrain, Reservation, etc.)
├── providers/                       # ChangeNotifier state (auth, player, manager, reservation, ...)
├── core/
│   ├── config.dart
│   └── servecice/api_service.dart   # Dio HTTP client (base URL from env)
└── theme/app_colors.dart            # Dark theme, green accent (#2ECC71)
```

### Key dependencies (`pubspec.yaml`)

| Package | Version | Purpose |
|---|---|---|
| provider | ^6.1.2 | State management |
| dio | ^5.9.2 | HTTP requests |
| go_router | ^14.8.1 | Declarative navigation |
| firebase_core | ^3.13.1 | Firebase initialization (mobile only) |
| cloud_firestore | ^5.6.6 | Real-time chat |
| shared_preferences | ^2.5.5 | Local token/session storage |
| image_picker | ^1.1.2 | Profile and campus image upload |
| google_fonts | latest | Typography |

### Platform routing

`main.dart` checks `kIsWeb` at startup:
- **Web** loads `AdminApp` (dashboard, no Firebase)
- **Mobile** loads `ArenaApp` (player/manager/employee flows, Firebase initialized)

---

## Backend

### Structure

```
Backend/src/
├── api/
│   ├── auth/              # Login, register, forgot/reset password
│   ├── ai/                # AI chat endpoints + LLM integration
│   │   └── services/
│   │       ├── ai.js            # playerChat / managerChat orchestration
│   │       ├── provider.js      # LLM provider abstraction (Gemini, OpenAI, Ollama)
│   │       ├── player-tools.js  # Tool definitions for player AI
│   │       └── manager-tools.js # Tool definitions for manager AI
│   ├── ai-log/            # Per-turn AI conversation logging
│   ├── campus/            # Sports facility CRUD
│   ├── terrain/           # Individual field CRUD
│   ├── player/            # Player profiles and player-scoped endpoints
│   ├── manager/           # Manager profiles and manager-scoped endpoints
│   ├── employee/          # Employee profiles
│   ├── admin/             # Admin dashboard endpoints
│   ├── reservation/       # Booking lifecycle
│   ├── week-agenda/       # 7-day terrain schedules
│   ├── day-plan/          # Single-day planning
│   ├── time-slot/         # Hourly booking slots
│   └── message/           # Firebase Firestore chat REST wrapper
├── firebase/
│   └── firebase.service.js      # Firebase Admin SDK init
├── policies/                    # JWT middleware and role guards
│   ├── authMiddleware.js
│   ├── isPlayer.js
│   ├── isManager.js
│   └── isAdmin.js
├── utils/email.js               # Password reset and notification emails
└── config/                      # Database, server, middleware, plugins
```

### Key dependencies (`package.json`)

| Package | Purpose |
|---|---|
| @strapi/strapi ^5.43.0 | Headless CMS framework |
| ai ^4.0.0 | Vercel AI SDK (tool calling, streaming) |
| @ai-sdk/google ^1.0.0 | Google Gemini provider |
| @ai-sdk/openai ^1.0.0 | OpenAI + Ollama provider |
| firebase-admin ^13.10.0 | Firestore server-side access |
| mysql2 3.20.0 | MySQL driver |
| nodemailer ^8.0.5 | Transactional email |
| bcrypt ^6.0.0 | Password hashing |
| zod ^3.23.8 | Input validation |

---

## Data Models

| Model | Key Fields |
|---|---|
| AuthUser (Strapi built-in) | id, username, email, user_role (admin/manager/player/employee) |
| Campus | Name, Address, NbTerrains, Lat, Long, main_image, gallery, manager |
| Terrain | type (Football/Basketball/Paddel/Tennis), campus, employee, week_agenda |
| Player | nom, address, phone, firebaseUid, fcmToken, user, reservations |
| Manager | nom, address, phone, user, campuses, employees |
| Employee | username, email, affected_to (terrain ID), address, phone |
| Reservation | type (normal/urgent), statu (pending/confirmed/cancelled), notes, bookedAt |
| WeekAgenda | weekStartDate, statu (Draft/Published), terrain, campus, day_plans |
| DayPlan | dayOfWeek, date, dayType (normal/urgent_only/day_off), notes, time_slots |
| TimeSlot | startTime (HH:MM), endTime, isActive, reservation |
| AiLog | userAuthId, userRole, provider, model, userMessage, aiReply, toolsUsed, tokensUsed, processingMs, success |

**Schema notes:**
- Campus fields only (`Name`, `Address`, `NbTerrains`, `Lat`, `Long`) use PascalCase; all other models use camelCase
- `statu` (not `status`) is the stored field name in Reservation and WeekAgenda — this is baked into the database schema
- Campus latitude/longitude are auto-geocoded from the address via Nominatim on create/update; parse defensively with `double.tryParse`

---

## AI Assistants

Both roles get a dedicated AI agent backed by the Vercel AI SDK with tool-calling support. The provider is selected via `LLM_PROVIDER` environment variable (default: `gemini`).

**Supported providers:**
- `gemini` — Google Gemini 2.5 Flash
- `openai` — OpenAI GPT-4o-mini
- `ollama` — Any locally-served Ollama model (OpenAI-compatible)

### Player AI

**Route:** `POST /ai/player-chat` (requires player token)

The player assistant can search for available slots and complete bookings without additional confirmation steps.

**Tools available:**

| Tool | Action |
|---|---|
| getCampusesAndTerrains | List all campuses with terrain types |
| getAvailableSlotsForDate | Search by date, terrain type, and optional time window |
| getMyReservations | Retrieve the player's existing bookings |
| bookReservation | Create a reservation |
| cancelReservation | Cancel a booking |

Max tool steps per turn: **8**

### Manager AI

**Route:** `POST /ai/manager-chat` (requires manager token)

The manager assistant handles multi-step agenda operations, including creating a full week schedule, publishing it, and adjusting individual day plans in a single conversation turn.

**Tools available:**

| Tool | Action |
|---|---|
| getMyTerrains | List the manager's terrains |
| getAgendaDetails | Full week agenda with day plans and slots |
| getPendingReservations | Unconfirmed bookings |
| getReservationById / getReservationsByDate | Booking lookups |
| createWeekAgenda | Create a 7-day schedule (auto-generates day plans and default time slots) |
| publishAgenda | Make agenda visible to players |
| setDayPlanType | Mark a day as normal / urgent_only / day_off |
| createTimeSlot / deleteTimeSlot | Manage individual slots |
| confirmReservation / cancelReservation | Handle bookings |
| deleteAgenda | Remove a draft or published agenda |

Max tool steps per turn: **20**

### AI Logging

Every conversation turn is logged to the `ai-log` collection:

```
userAuthId, userRole, provider, model
userMessage, aiReply
toolsUsed[], actionsTaken[]
tokensUsed (prompt + completion)
processingMs
success, errorMessage
sessionId (UUID grouping turns in a session)
```

### Frontend integration

```dart
// Frontend/lib/services/ai/ai_service.dart
Future<AiChatResponse> playerChat(String message, List<AiChatMessage> history, String sessionId)
Future<AiChatResponse> managerChat(String message, List<AiChatMessage> history, String sessionId)
```

`sessionId` is generated client-side (UUID) and sent with every message to group turns for analytics.

---

## API Endpoints

### Authentication (public)

```
POST   /auth/register
POST   /auth/login                  → { user, token }
POST   /auth/forgot-password
POST   /auth/reset-password
```

### Player

```
GET    /player/get-all-campuses
GET    /player/get-campus/:id
GET    /player/get-terrains
GET    /week-agendas/available-slots?campusId=&terrainType=&date=YYYY-MM-DD
POST   /reservations
GET    /reservations/mine
PUT    /reservations/:id/cancel
POST   /ai/player-chat
```

### Manager

```
POST   /manager/create-campus
PUT    /manager/update-campus/:id
POST   /manager/create-terrain
POST   /manager/register-employee
POST   /manager/week-agendas
POST   /manager/week-agendas/:id/publish
GET    /manager/get-terrains
GET    /reservations/pending
PUT    /reservations/:id/confirm
POST   /ai/manager-chat
```

### Messaging (Firebase)

```
POST   /conversations/:conversationId/messages
GET    /conversations/:conversationId/messages
DELETE /conversations/:conversationId/messages/:messageId
```

### Admin

```
GET    /admin/admins
GET    /admin/managers
GET    /admin/players
GET    /admin/employees
GET    /admin/get-all-campuses
GET    /admin/terrains
GET    /admin/week-agendas
```

**Note:** API response shapes are inconsistent across endpoints. Examples:
- `POST /reservations` returns `{ data: reservation }`
- `GET /admin/admins` returns `{ result: [...] }`
- `GET /admin/get-all-campuses` returns a plain array
- `GET /admin/terrains` returns `{ terrains: [...] }`

---

## Firebase / Real-time Chat

Chat messages are stored in Firebase Firestore (not in MySQL). The backend wraps Firestore access via Firebase Admin SDK. Mobile clients connect directly via the `cloud_firestore` Flutter package; the web admin dashboard does not use Firebase.

Required files (not committed):
- `Frontend/android/app/google-services.json`
- `Frontend/ios/Runner/GoogleService-Info.plist`

---

## Environment Variables

The backend requires the following environment variables (typically in `Backend/.env`):

```env
# Database
DATABASE_CLIENT=mysql2
DATABASE_HOST=
DATABASE_PORT=3306
DATABASE_NAME=
DATABASE_USERNAME=
DATABASE_PASSWORD=

# Strapi
APP_KEYS=
API_TOKEN_SALT=
ADMIN_JWT_SECRET=
JWT_SECRET=

# AI
LLM_PROVIDER=gemini           # gemini | openai | ollama
GEMINI_API_KEY=
OPENAI_API_KEY=

# Email
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
```

The frontend API base URL is configured in `Frontend/lib/core/config.dart`.

---

## Getting Started

### Backend

```bash
cd Backend
npm install
# Configure Backend/.env
npm run develop
```

Strapi admin panel: http://localhost:1337/admin
API base: http://localhost:1337/api

### Frontend

```bash
cd Frontend
flutter pub get
# Configure lib/core/config.dart with backend URL
flutter run                   # Mobile
flutter run -d chrome         # Web admin dashboard
```

---

## Known Quirks

- The `week-agenda` creation endpoint requires the week to start on Monday. Monday and Tuesday default to `day_off` in the auto-generated day plans.
- The `statu` field (misspelled) is the canonical column name in the database for Reservation and WeekAgenda; do not correct it without a migration.
- Campus geocoding relies on Nominatim (rate-limited public API). Lat/Long values may arrive as strings and should be parsed with `double.tryParse`.
- AI tool steps are executed server-side and committed immediately — there is no confirmation step before writes are applied.
