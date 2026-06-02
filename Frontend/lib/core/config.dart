import 'package:flutter/foundation.dart' show kIsWeb;

/// Single source of truth for the backend server address.
///
///   Web admin dashboard   : uses localhost (browser runs on the host machine)
///   Android emulator      : uses 10.0.2.2 (emulator's alias for host localhost)
///   LAN / physical device : change to your machine's LAN IP (e.g. 192.168.0.241)
final String kServerOrigin = kIsWeb ? 'http://localhost:1337' : 'http://10.0.2.2:1337';
final String kApiBase      = '$kServerOrigin/api';
