// ignore_for_file: constant_identifier_names
// Enum value names must match backend strings exactly for .byName() deserialization.

enum UserRole { admin, manager, player, employee }

enum TerrainType { Football, Basketball, Paddel, Tennis }

enum ReservationType { normal, urgent }

enum ReservationStatus { pending, confirmed, cancelled }

enum WeekAgendaStatus { Draft, Published }

enum DayOfWeek { Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday }

enum DayType { normal, urgent_only, day_off }

enum MessageType { text, image, system }
