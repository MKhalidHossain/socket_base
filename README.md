# Socket Base

Reusable Flutter Socket.IO asset built so the whole `lib/socket_service/` folder can be copied into another project.

## What is inside

- Reusable `SocketClient`
- Central `SocketConfig`
- Event and exception models
- Example usage file
- Minimal demo app

## Project structure

```text
lib/
├── main.dart
└── socket_service/
    ├── README.md
    ├── examples.dart
    ├── index.dart
    ├── socket_client.dart
    ├── socket_config.dart
    ├── socket_events.dart
    ├── socket_exceptions.dart
    ├── socket_service.dart
    └── src/
```

## Main module docs

See [lib/socket_service/README.md](lib/socket_service/README.md) for:

- installation
- quick start
- available API
- integration patterns
- notes about `disconnect()` vs `dispose()`

## Preferred import

```dart
import 'package:your_app/socket_service/socket_service.dart';
```

## Local verification

```bash
flutter analyze
flutter test
```
