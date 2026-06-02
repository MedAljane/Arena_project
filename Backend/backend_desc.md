# Arena App — Backend API Handoff for Flutter Mobile App

> **Backend:** Strapi on `http://localhost:1337`
> **All routes are prefixed with `/api`** — full base URL: `http://localhost:1337/api`
> **Messaging:** Firebase Firestore (real-time, separate from Strapi)

---

## Authentication

### Mechanism
Custom JWT — **not** Strapi's native auth. Every protected request must include:
```
Authorization: Bearer <token>
```

### Storage (suggested Flutter)
- Store `token` and `user` object in `flutter_secure_storage` or `SharedPreferences`.
- The `user` object contains `{ id, username, email, user_role }`.
- `user_role` values: `"player"` | `"manager"` | `"employee"` | `"admin"`

### Auth Endpoints (no token required)

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/auth/register` | `{username, email, password, address?, phone?}` | Register new player account |
| POST | `/auth/login` | `{email, password}` | Returns `{user, token}` |
| POST | `/auth/forgot-password` | `{email}` | Sends reset token by email |
| POST | `/auth/reset-password` | `{token, password}` | Reset using emailed token |

### Auth Endpoints (token required)

| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/auth/me` | — | Returns current user + player profile |
| POST | `/auth/logout` | — | Blacklists the token server-side |
| POST | `/auth/change-password` | `{currentPassword, newPassword}` | Change own password |

### Login Response Shape
```json
{
  "user": {
    "id": 1,
    "username": "john",
    "email": "john@example.com",
    "user_role": "player"
  },
  "token": "<jwt>"
}
```

---

## Role: Player

### Data Model
A player has two linked records:
- **User** (`plugin::users-permissions.user`): `id`, `username`, `email`, `user_role: "player"`
- **Player Profile** (`api::player.player`): `address`, `phone`, linked to user

---

### Campuses

| Method | Path | Description |
|--------|------|-------------|
| GET | `/player/get-all-campuses` | List all campuses |
| GET | `/player/get-campus/:id` | Single campus detail |
| GET | `/player/get-campus-by-manager` | Campus belonging to the caller's manager |

**Campus object:**
```json
{
  "id": 1,
  "Name": "Arena Nord",
  "Description": "...",
  "Address": "123 Main St",
  "phone": "+1234567890",
  "NbTerrains": 3,
  "Lat": "36.7",
  "Long": "3.05",
  "manager": { "id": 2, "username": "manager1", "email": "..." },
  "publishedAt": "2024-01-01T00:00:00Z"
}
```

---

### Terrains

| Method | Path | Description |
|--------|------|-------------|
| GET | `/player/get-terrains` | All terrains |
| GET | `/player/get-terrain/:id` | Single terrain detail |

**Terrain object:**
```json
{
  "id": 1,
  "Type": "Football",
  "campus": { "id": 1, "Name": "Arena Nord" },
  "employee": { "id": 3, "username": "emp1" }
}
```

`Type` values: `Football`, `Tennis`, `Padel`, `Squash`

---

### Managers & Employees (read)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/player/managers` | List all managers |
| GET | `/player/employees` | List all employees |

---

### Scheduling — Week Agendas & Slots

| Method | Path | Query params | Description |
|--------|------|-------------|-------------|
| GET | `/week-agendas/available-slots` | `campusId`, `terrainType`, `date` (YYYY-MM-DD) | Available time slots for a given date |
| GET | `/week-agendas/terrain` | `campusId`, `terrainType` | Full week agenda for a terrain |
| GET | `/week-agendas/:id` | — | Single week agenda by ID |
| GET | `/time-slots` | `day_plan` (ID), `isActive` (bool) | Time slots for a day plan |

**Available slots response:**
```json
[
  {
    "id": 5,
    "date": "2024-06-10",
    "dayOfWeek": "Monday",
    "dayType": "normal",
    "time_slots": [
      { "id": 12, "startTime": "14:00", "endTime": "16:00", "isActive": true }
    ]
  }
]
```

**Week Agenda object:**
```json
{
  "id": 1,
  "weekStartDate": "2024-06-10",
  "statu": "Published",
  "campus": { "id": 1, "Name": "Arena Nord" },
  "terrain": { "id": 2, "Type": "Football" },
  "day_plans": [ "..." ]
}
```

> Only `Published` agendas surface available slots. `Draft` agendas are invisible to players.

---

### Reservations

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/reservations` | `{timeSlotId, campusId, terrainId, employeeId?, type, notes?}` | Create reservation (locks the slot) |
| PUT | `/reservations/:id` | `{data: {type?, notes?}}` | Update own reservation |
| PUT | `/reservations/:id/cancel` | — | Cancel own reservation (re-activates the slot) |
| GET | `/reservations/mine` | — | List own reservations (newest first) |

**Reservation body example:**
```json
{
  "timeSlotId": 12,
  "campusId": 1,
  "terrainId": 2,
  "type": "training",
  "notes": "Bring extra balls"
}
```

**Reservation object:**
```json
{
  "id": 7,
  "statu": "confirmed",
  "type": "training",
  "notes": "...",
  "bookedAt": "2024-06-09T18:00:00Z",
  "time_slot": { "id": 12, "startTime": "14:00", "endTime": "16:00" },
  "terrain": { "id": 2, "Type": "Football" },
  "employee": { "id": 3 }
}
```

**Business rules:**
- A time slot is locked (`isActive = false`) the moment a reservation is created.
- Cancelling sets `statu = "cancelled"` and re-activates the slot.
- Cannot reserve a slot on a `day_off` day plan.
- Cannot reserve an already-reserved (inactive) slot.
- If no `employeeId` is provided, the terrain's assigned employee is used automatically.

---

### Player Booking Workflow

```
1. Browse Campuses  →  GET /player/get-all-campuses
2. Select Campus    →  browse its Terrains  →  GET /player/get-terrains
3. Pick a date      →  GET /week-agendas/available-slots?campusId=&terrainType=&date=
4. Select an active time slot
5.                     POST /reservations  { timeSlotId, campusId, terrainId, type }
6. View bookings    →  GET /reservations/mine
7. Cancel if needed →  PUT /reservations/:id/cancel
```

---

### Recommended Player Screens

| Screen | Purpose |
|--------|---------|
| Splash / Onboarding | App intro |
| Register | POST /auth/register |
| Login | POST /auth/login |
| Home / Dashboard | Upcoming reservations + featured campuses |
| Campus List | GET /player/get-all-campuses |
| Campus Detail | Campus info + terrain types available |
| Terrain Detail | Terrain info + assigned employee |
| Book a Slot | Date picker → available slots grid → confirm modal |
| My Reservations | GET /reservations/mine — tabs: Upcoming / Past / Cancelled |
| Reservation Detail | Full details + Cancel button |
| Profile / Settings | GET /auth/me, POST /auth/change-password |
| Chat | Firebase real-time messaging |

---

## Role: Manager

### Data Model
- **User** (`plugin::users-permissions.user`): `id`, `username`, `email`, `user_role: "manager"`
- **Manager Profile** (`api::manager.manager`): `address`, `phone`, linked to user
- **Campus**: one manager owns one campus via the `manager` relation

---

### Campus Management

| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/manager/get-campus-by-manager` | — | Manager's own campus |
| GET | `/manager/get-campuses` | — | All campuses |
| GET | `/manager/get-campus/:id` | — | Single campus |
| POST | `/manager/create-campus` | `{name, description, address, phone, nbTerrains, mainImage?, galleryImages?}` | Create campus |
| PUT | `/manager/update-campus/:id` | same fields | Update campus |
| DELETE | `/manager/delete-campus/:id` | — | Delete campus |

> `Address` is automatically geocoded to `Lat`/`Long` via Nominatim on create/update.

---

### Terrain Management

| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/manager/get-terrains` | — | All terrains for manager's campus |
| GET | `/manager/get-terrain/:id` | — | Single terrain |
| POST | `/manager/create-terrain` | `{Type, campusId, employeeId?}` | Create terrain |
| PUT | `/manager/update-terrain/:id` | `{Type?, campusId?, employeeId?}` | Update terrain |
| DELETE | `/manager/delete-terrain/:id` | — | Delete terrain (clears employee assignment) |

`employeeId` is the **user ID** of the employee — the backend resolves it to a profile ID internally.

---

### Employee Management

| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/manager/employees` | — | All employees |
| POST | `/manager/register-employee` | `{username, email, password, address?, phone?, terrainId?}` | Register employee + optionally assign terrain |
| PUT | `/manager/update-employee/:id` | `{username?, email?, address?, phone?}` | Update employee |
| DELETE | `/manager/delete-employee/:id` | — | Delete employee + user account |
| POST | `/manager/assign-employee/:employeeId/terrain/:terrainId` | — | Assign employee to terrain (both sides synced) |

**Employee object:**
```json
{
  "id": 5,
  "username": "emp1",
  "email": "emp@arena.com",
  "address": "...",
  "phone": "...",
  "affected_to": 2
}
```

`affected_to` is the terrain ID the employee is assigned to. `null` means unassigned.

**Assignment is bidirectional:** `terrain.employee` and `employee.affected_to` are always kept in sync by the backend across all code paths (register, create terrain, update terrain, delete terrain, explicit assign).

---

### Week Agenda Management

A week agenda covers 7 days for a specific terrain at a specific campus. Creating one auto-generates 7 day plans and default time slots.

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/manager/week-agendas` | `{weekStartDate, campusId, terrainType}` | Create agenda (auto-creates 7 day plans + slots) |
| POST | `/manager/week-agendas/:id/publish` | — | Publish agenda (makes visible to players) |

**Create body:**
```json
{
  "weekStartDate": "2024-06-10",
  "campusId": 1,
  "terrainType": "Football"
}
```

**Auto-generated structure on creation:**
- 7 DayPlans (Mon–Sun); Mon + Tue default to `dayType: "day_off"`
- Normal days get default slots: 14:00–16:00, 16:00–18:00, 18:00–20:00, 20:00–22:00
- Weekend (Sat/Sun) get extra slots: 10:00–12:00, 12:00–14:00

---

### Day Plan Management

| Method | Path | Body / Query | Description |
|--------|------|-------------|-------------|
| POST | `/manager/day-plans` | `{dayOfWeek, date, dayType, notes?, week_agendum}` | Create a day plan manually |
| GET | `/manager/day-plans/by-date` | `?date=YYYY-MM-DD&campusId=` | Get day plans for a date |

`dayType` values: `"normal"` | `"day_off"`

---

### Time Slot Management

| Method | Path | Body | Description |
|--------|------|------|-------------|
| GET | `/time-slots` | `?day_plan=&isActive=` | List slots (filtered) |
| POST | `/time-slots` | `{data: {day_plan, startTime, endTime}}` | Create slot |
| PUT | `/time-slots/:id` | `{data: {...}}` | Update slot |
| DELETE | `/time-slots/:id` | — | Delete slot |

Cannot create slots for a `day_off` day plan. Duplicate (same day_plan + startTime + endTime) is rejected.

---

### Manager Scheduling Workflow

```
1. Create Campus      →  POST /manager/create-campus
2. Create Terrains    →  POST /manager/create-terrain { Type, campusId }
3. Register Employees →  POST /manager/register-employee
4. Assign to Terrains →  POST /manager/assign-employee/:eId/terrain/:tId
5. Create Week Agenda →  POST /manager/week-agendas { weekStartDate, campusId, terrainType }
                         └─ Auto-generates 7 DayPlans + default TimeSlots
6. Adjust Day Plans if needed  (mark days off, add notes)
7. Adjust Time Slots if needed (add/remove slots)
8. Publish            →  POST /manager/week-agendas/:id/publish
                         └─ Now visible to players; slots can be reserved
```

---

### Recommended Manager Screens

| Screen | Purpose |
|--------|---------|
| Login | POST /auth/login (manager user_role) |
| Dashboard | Overview: campus info, active agendas, employee count |
| My Campus | GET /manager/get-campus-by-manager — view/edit campus |
| Terrain List | GET /manager/get-terrains — type + assigned employee |
| Terrain Form | Create / edit terrain, assign employee dropdown |
| Employee List | GET /manager/employees — with terrain assignment status |
| Employee Form | Register / edit employee, assign terrain |
| Week Agenda List | List agendas (Draft / Published) per terrain |
| Create Agenda | Form: weekStartDate + terrainType → auto-creates structure |
| Agenda Detail | 7-day calendar view of day plans + time slots |
| Day Plan Detail | Slot list, toggle day_off, add/remove time slots |
| Publish Agenda | Confirmation → POST .../publish |
| Profile / Settings | Change password, view profile |
| Chat | Firebase real-time messaging |

---

## Messaging — Firebase Firestore

> **No Strapi auth middleware** on these routes. Pass `senderUid` in the body.
> Real-time listening should be done directly via the **Firebase Flutter SDK** — use these REST endpoints for sending and initial load only; use Firestore `.snapshots()` for live updates.

| Method | Path | Body | Description |
|--------|------|------|-------------|
| POST | `/conversations/:conversationId/messages` | `{conversationId, senderUid, text, type?}` | Send a message |
| GET | `/conversations/:conversationId/messages` | — | Fetch all messages (ordered createdAt asc) |
| GET | `/conversations/:conversationId/messages/:messageId` | — | Single message |
| DELETE | `/conversations/:conversationId/messages/:messageId` | — | Delete a message |

**Firestore data structure:**
```
conversations/
  {conversationId}/
    lastMessage: "Hey!"
    lastMessageAt: Timestamp
    messages/
      {messageId}/
        senderUid: "5"
        text: "Hey!"
        type: "text"
        createdAt: Timestamp
```

`conversationId` is a string (Strapi numeric ID cast to string). `senderUid` is the Strapi user ID as a string. `type` defaults to `"text"` — extend as needed (`"image"`, `"system"`).

**Flutter:** add `cloud_firestore` to pubspec.yaml and listen with `.snapshots()` for the real-time chat UI. You'll need `google-services.json` from the Firebase project — get it from the backend team.

---

## Response Shape Reference

| Endpoint group | Response wrapper |
|----------------|-----------------|
| GET /admin/admins | `{ result: [...] }` |
| GET /admin/managers | `{ result: [...] }` |
| GET /admin/players | `{ result: [...] }` |
| GET /admin/employees | `{ result: [...] }` |
| GET /admin/get-all-campuses | plain array `[...]` |
| GET /admin/terrains | `{ terrains: [...] }` |
| GET /admin/week-agendas | `{ agendas: [...] }` |
| POST /reservations | `{ data: reservation }` |
| GET /reservations/mine | `{ data: [...] }` |
| GET /time-slots | `{ data: [...] }` |

These inconsistencies exist in the current backend. Normalize them in your Flutter repository/data layer so screens never see the raw wrapper.

---

## Error Handling

All error responses follow:
```json
{ "error": { "message": "Human readable message" } }
```

Some routes return a `400 Bad Request` with a plain string body. Handle both shapes.

`401` means the token is missing, expired, or blacklisted — redirect to the login screen and clear stored credentials.

---

## Notes for the Flutter Dev

1. **JWT** — store with `flutter_secure_storage`. Attach as `Authorization: Bearer <token>` on every API call after login.
2. **Role-based routing** — after login, read `user.user_role` and navigate to the player or manager shell. Reject unexpected roles at the gate.
3. **Slot booking race condition** — the backend marks slots inactive atomically. If a slot was just taken by someone else, you'll get a `400`. Show a "slot no longer available" message and refresh the slot list.
4. **Campus geocoding** — `Lat` and `Long` are auto-populated from `Address` on campus create/update. Use them directly for map pins — no client-side geocoding needed.
5. **Week agenda auto-structure** — when a manager creates an agenda, 7 day plans and all default slots are generated server-side. The manager only needs to manually adjust after that; don't build a flow that requires creating day plans one by one.
6. **Firebase credentials** — coordinate with the backend team to get the Firebase project ID and the `google-services.json` (Android) / `GoogleService-Info.plist` (iOS).
7. **Field casing** — Campus fields use `PascalCase` (`Name`, `Address`, `NbTerrains`, `Lat`, `Long`). All other models use `camelCase`. Don't assume uniform casing.
8. **`statu` not `status`** — both Reservations and WeekAgendas use the field name `statu` (typo in the schema, but that's what the DB stores — use it as-is).
