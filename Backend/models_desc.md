# Flutter Models — Database Class Reference

> Derived from Strapi schema JSON files in `backend/src/api/*/content-types/*/schema.json`.
> All API types, field names, casing rules, and response wrappers are reflected here exactly as the backend produces them.

---

## Casing rules (read before implementing)

| Model | Rule |
|-------|------|
| Campus | `Name`, `Address`, `NbTerrains`, `Lat`, `Long` are **PascalCase** — everything else is camelCase |
| All others | **camelCase** throughout |
| Reservation / WeekAgenda | Use `statu` (not `status`) — this is a typo in the schema that is baked into the DB |

---

## Response wrapper reference

Normalize in the repository layer. Screens must never see raw wrappers.

| Endpoint | Raw wrapper | Dart extraction |
|----------|-------------|-----------------|
| `POST /reservations` | `{ "data": { reservation } }` | `json['data']` |
| `GET /reservations/mine` | `{ "data": [ ... ] }` | `json['data'] as List` |
| `GET /time-slots` | `{ "data": [ ... ] }` | `json['data'] as List` |
| `GET /admin/admins` | `{ "result": [ ... ] }` | `json['result'] as List` |
| `GET /admin/managers` | `{ "result": [ ... ] }` | `json['result'] as List` |
| `GET /admin/players` | `{ "result": [ ... ] }` | `json['result'] as List` |
| `GET /admin/employees` | `{ "result": [ ... ] }` | `json['result'] as List` |
| `GET /admin/get-all-campuses` | plain array | `json as List` |
| `GET /admin/terrains` | `{ "terrains": [ ... ] }` | `json['terrains'] as List` |
| `GET /admin/week-agendas` | `{ "agendas": [ ... ] }` | `json['agendas'] as List` |

---

## Enums

```dart
enum UserRole { admin, manager, player, employee }

enum TerrainType { Football, Basketball, Paddel, Tennis }

enum ReservationType { normal, urgent }

enum ReservationStatus { pending, confirmed, cancelled }

enum WeekAgendaStatus { Draft, Published }

enum DayOfWeek { Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday }

enum DayType { normal, urgent_only, day_off }

enum MessageType { text, image, system }
```

> Map each enum with `EnumName.values.byName(json['field'])` for deserialization. For `DayType`, `urgent_only` contains an underscore — handle it with a manual switch or `EnumName.values.firstWhere`.

---

## 1. AuthUser

Returned by `POST /auth/login` inside `{ "user": {...}, "token": "..." }` and by `GET /auth/me`.

**Source:** `plugin::users-permissions.user` (subset returned by the auth endpoints — private fields stripped)

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | Strapi record ID |
| `username` | string | `String` | min 3 chars, unique |
| `email` | email | `String` | |
| `user_role` | enum | `UserRole` | `admin \| manager \| player \| employee` |

```dart
class AuthUser {
  final int id;
  final String username;
  final String email;
  final UserRole userRole;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.userRole,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        userRole: UserRole.values.byName(json['user_role'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'user_role': userRole.name,
      };
}
```

---

## 2. AuthResponse

Wraps the login response.

```dart
class AuthResponse {
  final AuthUser user;
  final String token;

  const AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        token: json['token'] as String,
      );
}
```

---

## 3. Campus

**Source:** `api::campus.campus` — collection name `campuses`

**Endpoint shapes:** returned by `/player/get-all-campuses`, `/player/get-campus/:id`, `/manager/get-campus-by-manager`, etc.

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | |
| `Name` | string | `String` | required, PascalCase |
| `Description` | string | `String?` | nullable |
| `Address` | string | `String` | required, PascalCase |
| `NbTerrains` | integer | `int` | required, PascalCase |
| `Lat` | float | `double?` | auto-geocoded; API may return as string — parse defensively |
| `Long` | float | `double?` | auto-geocoded; API may return as string — parse defensively |
| `phone` | string | `String?` | |
| `main_image` | media | `StrapiMedia?` | single image |
| `gallery` | media | `List<StrapiMedia>` | multiple images |
| `manager` | relation → AuthUser | `AuthUser?` | manyToOne, may be nested or null |
| `manager` | relation → Manager | `ManagerSummary?` | manyToOne, may be nested or null |
| `terrains` | relation → Terrain[] | `List<TerrainSummary>` | oneToMany, may be absent |
| `publishedAt` | datetime | `DateTime?` | Strapi auto-field |

> `Lat` / `Long` come back as `String` in the example response in `backend_desc.md` (`"36.7"`) despite being `float` in the schema. Parse with `double.tryParse(json['Lat'].toString())`.

```dart
class Campus {
  final int id;
  final String name;
  final String? description;
  final String address;
  final int nbTerrains;
  final double? lat;
  final double? long;
  final String? phone;
  final StrapiMedia? mainImage;
  final List<StrapiMedia> gallery;
  final AuthUser? manager;
  final ManagerSummary? manager;
  final List<TerrainSummary> terrains;
  final DateTime? publishedAt;

  const Campus({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.nbTerrains,
    this.lat,
    this.long,
    this.phone,
    this.mainImage,
    this.gallery = const [],
    this.manager,
    this.manager,
    this.terrains = const [],
    this.publishedAt,
  });

  factory Campus.fromJson(Map<String, dynamic> json) => Campus(
        id: json['id'] as int,
        name: json['Name'] as String,
        description: json['Description'] as String?,
        address: json['Address'] as String,
        nbTerrains: json['NbTerrains'] as int,
        lat: json['Lat'] != null ? double.tryParse(json['Lat'].toString()) : null,
        long: json['Long'] != null ? double.tryParse(json['Long'].toString()) : null,
        phone: json['phone'] as String?,
        mainImage: json['main_image'] != null
            ? StrapiMedia.fromJson(json['main_image'] as Map<String, dynamic>)
            : null,
        gallery: (json['gallery'] as List<dynamic>? ?? [])
            .map((e) => StrapiMedia.fromJson(e as Map<String, dynamic>))
            .toList(),
        manager: json['manager'] != null
            ? AuthUser.fromJson(json['manager'] as Map<String, dynamic>)
            : null,
        manager: json['manager'] != null
            ? ManagerSummary.fromJson(json['manager'] as Map<String, dynamic>)
            : null,
        terrains: (json['terrains'] as List<dynamic>? ?? [])
            .map((e) => TerrainSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        publishedAt: json['publishedAt'] != null
            ? DateTime.parse(json['publishedAt'] as String)
            : null,
      );
}
```

**Create/Update body** (`POST /manager/create-campus`, `PUT /manager/update-campus/:id`):

```dart
class CampusRequest {
  final String name;
  final String? description;
  final String address;
  final String? phone;
  final int nbTerrains;
  // mainImage and galleryImages are sent as multipart form fields — handle separately

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'address': address,
        if (phone != null) 'phone': phone,
        'nbTerrains': nbTerrains,
      };
}
```

---

## 4. Terrain

**Source:** `api::terrain.terrain` — collection name `terrains`

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | |
| `Type` | enum | `TerrainType` | `Football \| Basketball \| Paddel \| Tennis` — PascalCase key |
| `campus` | relation → Campus | `CampusSummary?` | manyToOne, nested on detail endpoints |
| `employee` | relation → Employee | `EmployeeSummary?` | oneToOne, may be null |
| `week_agenda` | relation → WeekAgenda[] | `List<WeekAgendaSummary>` | oneToMany |

```dart
class Terrain {
  final int id;
  final TerrainType type;
  final CampusSummary? campus;
  final EmployeeSummary? employee;
  final List<WeekAgendaSummary> weekAgenda;

  const Terrain({
    required this.id,
    required this.type,
    this.campus,
    this.employee,
    this.weekAgenda = const [],
  });

  factory Terrain.fromJson(Map<String, dynamic> json) => Terrain(
        id: json['id'] as int,
        type: TerrainType.values.byName(json['Type'] as String),
        campus: json['campus'] != null
            ? CampusSummary.fromJson(json['campus'] as Map<String, dynamic>)
            : null,
        employee: json['employee'] != null
            ? EmployeeSummary.fromJson(json['employee'] as Map<String, dynamic>)
            : null,
        weekAgenda: (json['week_agenda'] as List<dynamic>? ?? [])
            .map((e) => WeekAgendaSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

**Create/Update body** (`POST /manager/create-terrain`, `PUT /manager/update-terrain/:id`):

```dart
class TerrainRequest {
  final TerrainType type;
  final int campusId;
  final int? employeeId; // Strapi user ID, not employee profile ID

  Map<String, dynamic> toJson() => {
        'Type': type.name,
        'campusId': campusId,
        if (employeeId != null) 'employeeId': employeeId,
      };
}
```

---

## 5. Player

**Source:** `api::player.player` — collection name `players`

> A player has two records: an `AuthUser` (credentials) + a `Player` profile (extra fields). They are linked by a oneToOne relation (`user`).

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | profile ID (not user ID) |
| `nom` | string | `String?` | display name |
| `address` | string | `String?` | |
| `phone` | string | `String?` | |
| `firebaseUid` | string | `String?` | Firebase Auth UID |
| `fcmToken` | string | `String?` | FCM push token |
| `user` | relation → AuthUser | `AuthUser?` | oneToOne |
| `reservations` | relation → Reservation[] | `List<ReservationSummary>` | oneToMany |

```dart
class Player {
  final int id;
  final String? nom;
  final String? address;
  final String? phone;
  final String? firebaseUid;
  final String? fcmToken;
  final AuthUser? user;
  final List<ReservationSummary> reservations;

  const Player({
    required this.id,
    this.nom,
    this.address,
    this.phone,
    this.firebaseUid,
    this.fcmToken,
    this.user,
    this.reservations = const [],
  });

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as int,
        nom: json['nom'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        firebaseUid: json['firebaseUid'] as String?,
        fcmToken: json['fcmToken'] as String?,
        user: json['user'] != null
            ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        reservations: (json['reservations'] as List<dynamic>? ?? [])
            .map((e) => ReservationSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

**Register body** (`POST /auth/register`):

```dart
class RegisterRequest {
  final String username;
  final String email;
  final String password;
  final String? address;
  final String? phone;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
      };
}
```

---

## 6. Manager

**Source:** `api::manager.manager` — collection name `managers`

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | profile ID |
| `nom` | string | `String?` | |
| `address` | string | `String?` | |
| `phone` | string | `String?` | |
| `firebaseUid` | string | `String?` | |
| `fcmToken` | string | `String?` | |
| `user` | relation → AuthUser | `AuthUser?` | oneToOne |
| `campuses` | relation → Campus[] | `List<CampusSummary>` | oneToMany |
| `employees` | relation → Employee[] | `List<EmployeeSummary>` | oneToMany |

```dart
class Manager {
  final int id;
  final String? nom;
  final String? address;
  final String? phone;
  final String? firebaseUid;
  final String? fcmToken;
  final AuthUser? user;
  final List<CampusSummary> campuses;
  final List<EmployeeSummary> employees;

  const Manager({
    required this.id,
    this.nom,
    this.address,
    this.phone,
    this.firebaseUid,
    this.fcmToken,
    this.user,
    this.campuses = const [],
    this.employees = const [],
  });

  factory Manager.fromJson(Map<String, dynamic> json) => Manager(
        id: json['id'] as int,
        nom: json['nom'] as String?,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        firebaseUid: json['firebaseUid'] as String?,
        fcmToken: json['fcmToken'] as String?,
        user: json['user'] != null
            ? AuthUser.fromJson(json['user'] as Map<String, dynamic>)
            : null,
        campuses: (json['campuses'] as List<dynamic>? ?? [])
            .map((e) => CampusSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
        employees: (json['employees'] as List<dynamic>? ?? [])
            .map((e) => EmployeeSummary.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

---

## 7. Employee

**Source:** `api::employee.employee` — collection name `employees`

> The API response shape for employees differs from the schema: `GET /manager/employees` returns a flat object with user fields merged at the top level, plus `affected_to` (terrain ID or null).

| Field | API key | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | `id` | `int` | employee profile ID |
| `username` | `username` | `String` | from user record |
| `email` | `email` | `String` | from user record |
| `address` | `address` | `String?` | |
| `phone` | `phone` | `String?` | |
| `affected_to` | `affected_to` | `int?` | terrain ID, null if unassigned |

```dart
class Employee {
  final int id;
  final String username;
  final String email;
  final String? address;
  final String? phone;
  final int? affectedTo; // terrain ID

  const Employee({
    required this.id,
    required this.username,
    required this.email,
    this.address,
    this.phone,
    this.affectedTo,
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
        id: json['id'] as int,
        username: json['username'] as String,
        email: json['email'] as String,
        address: json['address'] as String?,
        phone: json['phone'] as String?,
        affectedTo: json['affected_to'] as int?,
      );
}
```

**Register body** (`POST /manager/register-employee`):

```dart
class RegisterEmployeeRequest {
  final String username;
  final String email;
  final String password;
  final String? address;
  final String? phone;
  final int? terrainId;

  Map<String, dynamic> toJson() => {
        'username': username,
        'email': email,
        'password': password,
        if (address != null) 'address': address,
        if (phone != null) 'phone': phone,
        if (terrainId != null) 'terrainId': terrainId,
      };
}
```

---

## 8. Reservation

**Source:** `api::reservation.reservation` — collection name `reservations`

**Response wrapper:**
- `POST /reservations` → `json['data']` (single object)
- `GET /reservations/mine` → `json['data']` (list)

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | |
| `type` | enum | `ReservationType` | `normal \| urgent` |
| `statu` | enum | `ReservationStatus` | **not** `status` — `pending \| confirmed \| cancelled` |
| `notes` | string | `String?` | |
| `bookedAt` | datetime | `DateTime?` | ISO 8601, e.g. `2024-06-09T18:00:00Z` |
| `terrain` | relation → Terrain | `TerrainSummary?` | oneToOne |
| `time_slot` | relation → TimeSlot | `TimeSlotSummary?` | oneToOne |
| `player` | relation → Player | `PlayerSummary?` | manyToOne |
| `employee` | relation → Employee | `EmployeeSummary?` | manyToOne |

```dart
class Reservation {
  final int id;
  final ReservationType type;
  final ReservationStatus statu;
  final String? notes;
  final DateTime? bookedAt;
  final TerrainSummary? terrain;
  final TimeSlotSummary? timeSlot;
  final PlayerSummary? player;
  final EmployeeSummary? employee;

  const Reservation({
    required this.id,
    required this.type,
    required this.statu,
    this.notes,
    this.bookedAt,
    this.terrain,
    this.timeSlot,
    this.player,
    this.employee,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'] as int,
        type: ReservationType.values.byName(json['type'] as String),
        statu: ReservationStatus.values.byName(json['statu'] as String),
        notes: json['notes'] as String?,
        bookedAt: json['bookedAt'] != null
            ? DateTime.parse(json['bookedAt'] as String)
            : null,
        terrain: json['terrain'] != null
            ? TerrainSummary.fromJson(json['terrain'] as Map<String, dynamic>)
            : null,
        timeSlot: json['time_slot'] != null
            ? TimeSlotSummary.fromJson(json['time_slot'] as Map<String, dynamic>)
            : null,
        player: json['player'] != null
            ? PlayerSummary.fromJson(json['player'] as Map<String, dynamic>)
            : null,
        employee: json['employee'] != null
            ? EmployeeSummary.fromJson(json['employee'] as Map<String, dynamic>)
            : null,
      );
}
```

**Create body** (`POST /reservations`):

```dart
class CreateReservationRequest {
  final int timeSlotId;
  final int campusId;
  final int terrainId;
  final int? employeeId;
  final ReservationType type;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'timeSlotId': timeSlotId,
        'campusId': campusId,
        'terrainId': terrainId,
        if (employeeId != null) 'employeeId': employeeId,
        'type': type.name,
        if (notes != null) 'notes': notes,
      };
}
```

**Update body** (`PUT /reservations/:id`):

```dart
class UpdateReservationRequest {
  final ReservationType? type;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'data': {
          if (type != null) 'type': type!.name,
          if (notes != null) 'notes': notes,
        },
      };
}
```

---

## 9. WeekAgenda

**Source:** `api::week-agenda.week-agenda` — collection name `week_agendas`

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | |
| `weekStartDate` | date | `String` | `YYYY-MM-DD` — use `String`, parse to `DateTime` only for display |
| `statu` | enum | `WeekAgendaStatus` | **not** `status` — `Draft \| Published` (capital first letter) |
| `terrain` | relation → Terrain | `TerrainSummary?` | manyToOne |
| `campus` | relation → Campus | `CampusSummary?` | manyToOne |
| `day_plans` | relation → DayPlan[] | `List<DayPlan>` | oneToMany |

```dart
class WeekAgenda {
  final int id;
  final String weekStartDate;
  final WeekAgendaStatus statu;
  final TerrainSummary? terrain;
  final CampusSummary? campus;
  final List<DayPlan> dayPlans;

  const WeekAgenda({
    required this.id,
    required this.weekStartDate,
    required this.statu,
    this.terrain,
    this.campus,
    this.dayPlans = const [],
  });

  factory WeekAgenda.fromJson(Map<String, dynamic> json) => WeekAgenda(
        id: json['id'] as int,
        weekStartDate: json['weekStartDate'] as String,
        statu: WeekAgendaStatus.values.byName(json['statu'] as String),
        terrain: json['terrain'] != null
            ? TerrainSummary.fromJson(json['terrain'] as Map<String, dynamic>)
            : null,
        campus: json['campus'] != null
            ? CampusSummary.fromJson(json['campus'] as Map<String, dynamic>)
            : null,
        dayPlans: (json['day_plans'] as List<dynamic>? ?? [])
            .map((e) => DayPlan.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
```

**Create body** (`POST /manager/week-agendas`):

```dart
class CreateWeekAgendaRequest {
  final String weekStartDate; // YYYY-MM-DD
  final int campusId;
  final TerrainType terrainType;

  Map<String, dynamic> toJson() => {
        'weekStartDate': weekStartDate,
        'campusId': campusId,
        'terrainType': terrainType.name,
      };
}
```

---

## 10. DayPlan

**Source:** `api::day-plan.day-plan` — collection name `day_plans`

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | |
| `dayOfWeek` | enum | `DayOfWeek` | `Monday`–`Sunday` |
| `date` | date | `String` | `YYYY-MM-DD` |
| `dayType` | enum | `DayType` | `normal \| urgent_only \| day_off` |
| `notes` | string | `String?` | |
| `week_agendum` | relation → WeekAgenda | `int?` | manyToOne, key is `week_agendum` (Strapi plural oddity) |
| `time_slots` | relation → TimeSlot[] | `List<TimeSlot>` | oneToMany |

```dart
class DayPlan {
  final int id;
  final DayOfWeek dayOfWeek;
  final String date;
  final DayType dayType;
  final String? notes;
  final List<TimeSlot> timeSlots;

  const DayPlan({
    required this.id,
    required this.dayOfWeek,
    required this.date,
    required this.dayType,
    this.notes,
    this.timeSlots = const [],
  });

  factory DayPlan.fromJson(Map<String, dynamic> json) => DayPlan(
        id: json['id'] as int,
        dayOfWeek: DayOfWeek.values.byName(json['dayOfWeek'] as String),
        date: json['date'] as String,
        dayType: _parseDayType(json['dayType'] as String),
        notes: json['notes'] as String?,
        timeSlots: (json['time_slots'] as List<dynamic>? ?? [])
            .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  static DayType _parseDayType(String value) => switch (value) {
        'normal' => DayType.normal,
        'urgent_only' => DayType.urgent_only,
        'day_off' => DayType.day_off,
        _ => throw FormatException('Unknown dayType: $value'),
      };
}
```

> `DayType.urgent_only` contains an underscore which prevents `EnumName.values.byName()` from working — use the `_parseDayType` helper above.

**Available-slots response** (`GET /week-agendas/available-slots`): the API returns a list of `DayPlan`-shaped objects with `time_slots` already filtered to `isActive: true`. Deserialize as `List<DayPlan>`.

---

## 11. TimeSlot

**Source:** `api::time-slot.time-slot` — collection name `time_slots`

**Response wrapper:** `GET /time-slots` → `json['data']` (list)

| Field | DB type | Dart type | Notes |
|-------|---------|-----------|-------|
| `id` | integer | `int` | |
| `startTime` | string | `String` | `HH:MM` format |
| `endTime` | string | `String` | `HH:MM` format |
| `isActive` | boolean | `bool` | `false` = slot is reserved/locked |
| `day_plan` | relation → DayPlan | `int?` | manyToOne, often just the ID |
| `reservation` | relation → Reservation | `ReservationSummary?` | oneToOne, may be null |

```dart
class TimeSlot {
  final int id;
  final String startTime;
  final String endTime;
  final bool isActive;
  final ReservationSummary? reservation;

  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    this.reservation,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
        id: json['id'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
        isActive: json['isActive'] as bool? ?? true,
        reservation: json['reservation'] != null
            ? ReservationSummary.fromJson(json['reservation'] as Map<String, dynamic>)
            : null,
      );
}
```

**Create body** (`POST /time-slots`):

```dart
class CreateTimeSlotRequest {
  final int dayPlanId;
  final String startTime; // HH:MM
  final String endTime;   // HH:MM

  Map<String, dynamic> toJson() => {
        'data': {
          'day_plan': dayPlanId,
          'startTime': startTime,
          'endTime': endTime,
        },
      };
}
```

**Update body** (`PUT /time-slots/:id`):

```dart
class UpdateTimeSlotRequest {
  final String? startTime;
  final String? endTime;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
        'data': {
          if (startTime != null) 'startTime': startTime,
          if (endTime != null) 'endTime': endTime,
          if (isActive != null) 'isActive': isActive,
        },
      };
}
```

---

## 12. Message (Firebase Firestore)

**Source:** Firestore collection `conversations/{conversationId}/messages/{messageId}`

> No Strapi auth on these routes. Real-time updates come from `cloud_firestore` `.snapshots()`, not the REST endpoints.

| Field | Firestore type | Dart type | Notes |
|-------|---------------|-----------|-------|
| `id` | document ID | `String` | Firestore auto-ID |
| `senderUid` | string | `String` | Strapi user ID as string |
| `text` | string | `String` | message body |
| `type` | string | `MessageType` | `text \| image \| system`, defaults to `text` |
| `createdAt` | Timestamp | `DateTime` | |

```dart
class Message {
  final String id;
  final String senderUid;
  final String text;
  final MessageType type;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.type,
    required this.createdAt,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderUid: data['senderUid'] as String,
      text: data['text'] as String,
      type: MessageType.values.byName((data['type'] as String?) ?? 'text'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
```

**Send body** (`POST /conversations/:conversationId/messages`):

```dart
class SendMessageRequest {
  final String conversationId;
  final String senderUid;
  final String text;
  final MessageType type;

  Map<String, dynamic> toJson() => {
        'conversationId': conversationId,
        'senderUid': senderUid,
        'text': text,
        'type': type.name,
      };
}
```

---

## Summary models (relation stubs)

Use these lightweight classes when a relation is nested inside another model. They avoid circular dependencies and keep payloads small.

```dart
class CampusSummary {
  final int id;
  final String name;

  const CampusSummary({required this.id, required this.name});

  factory CampusSummary.fromJson(Map<String, dynamic> json) =>
      CampusSummary(id: json['id'] as int, name: json['Name'] as String);
}

class TerrainSummary {
  final int id;
  final TerrainType type;

  const TerrainSummary({required this.id, required this.type});

  factory TerrainSummary.fromJson(Map<String, dynamic> json) =>
      TerrainSummary(id: json['id'] as int, type: TerrainType.values.byName(json['Type'] as String));
}

class ManagerSummary {
  final int id;
  final String? nom;

  const ManagerSummary({required this.id, this.nom});

  factory ManagerSummary.fromJson(Map<String, dynamic> json) =>
      ManagerSummary(id: json['id'] as int, nom: json['nom'] as String?);
}

class EmployeeSummary {
  final int id;
  final String? username;

  const EmployeeSummary({required this.id, this.username});

  factory EmployeeSummary.fromJson(Map<String, dynamic> json) =>
      EmployeeSummary(id: json['id'] as int, username: json['username'] as String?);
}

class PlayerSummary {
  final int id;
  final String? nom;

  const PlayerSummary({required this.id, this.nom});

  factory PlayerSummary.fromJson(Map<String, dynamic> json) =>
      PlayerSummary(id: json['id'] as int, nom: json['nom'] as String?);
}

class ReservationSummary {
  final int id;
  final ReservationStatus statu;

  const ReservationSummary({required this.id, required this.statu});

  factory ReservationSummary.fromJson(Map<String, dynamic> json) =>
      ReservationSummary(
        id: json['id'] as int,
        statu: ReservationStatus.values.byName(json['statu'] as String),
      );
}

class TimeSlotSummary {
  final int id;
  final String startTime;
  final String endTime;

  const TimeSlotSummary({required this.id, required this.startTime, required this.endTime});

  factory TimeSlotSummary.fromJson(Map<String, dynamic> json) =>
      TimeSlotSummary(
        id: json['id'] as int,
        startTime: json['startTime'] as String,
        endTime: json['endTime'] as String,
      );
}

class WeekAgendaSummary {
  final int id;
  final String weekStartDate;
  final WeekAgendaStatus statu;

  const WeekAgendaSummary({required this.id, required this.weekStartDate, required this.statu});

  factory WeekAgendaSummary.fromJson(Map<String, dynamic> json) =>
      WeekAgendaSummary(
        id: json['id'] as int,
        weekStartDate: json['weekStartDate'] as String,
        statu: WeekAgendaStatus.values.byName(json['statu'] as String),
      );
}
```

---

## StrapiMedia

Strapi media upload objects (used for `Campus.main_image` and `Campus.gallery`).

```dart
class StrapiMedia {
  final int id;
  final String url;
  final String? name;
  final String? mime;
  final int? size;

  const StrapiMedia({
    required this.id,
    required this.url,
    this.name,
    this.mime,
    this.size,
  });

  factory StrapiMedia.fromJson(Map<String, dynamic> json) => StrapiMedia(
        id: json['id'] as int,
        url: json['url'] as String,
        name: json['name'] as String?,
        mime: json['mime'] as String?,
        size: json['size'] as int?,
      );

  String get fullUrl => url.startsWith('http') ? url : 'http://localhost:1337$url';
}
```

---

## Error response

All Strapi error responses (and some `400` plain-string bodies):

```dart
class ApiError {
  final String message;

  const ApiError({required this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map<String, dynamic>) {
      return ApiError(message: error['message'] as String? ?? 'Unknown error');
    }
    return ApiError(message: json.toString());
  }
}
```

> On `401`, clear stored credentials and redirect to Login.
