# Reusable Flutter Socket Service

This module is arranged so you can copy `lib/socket_service/` into any Flutter project and reuse the same socket implementation instead of rebuilding it from scratch each time.

## Covers

- basic connect and disconnect
- manual connect
- reconnect and reconnect with new config
- auth, query, headers, path, transports
- emit and emit with ack
- `on`, `once`, `off`, `onAny`, `offAny`
- room join and leave helpers
- reactive status and event streams
- clear error classes

## Folder structure

```text
lib/socket_service/
├── README.md
├── examples.dart
├── index.dart
├── socket_client.dart
├── socket_config.dart
├── socket_events.dart
├── socket_exceptions.dart
├── socket_service.dart
└── src/
    ├── socket_client.dart
    ├── socket_config.dart
    ├── socket_events.dart
    └── socket_exceptions.dart
```

## Copy into another Flutter project

1. Copy the full `lib/socket_service/` folder.
2. Add the dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  socket_io_client: ^3.1.4
```

3. Run:

```bash
flutter pub get
```

4. Import the module:

```dart
import 'package:your_app/socket_service/socket_service.dart';
```

## Quick start

```dart
import 'package:your_app/socket_service/socket_service.dart';

final socket = SocketClient.shared;

void setupSocket() {
  final config = SocketConfig(
    url: 'https://api.example.com',
    auth: {'token': 'jwt-token'},
    query: {'platform': 'flutter'},
    enableLogging: true,
  );

  socket.on('connect', (_) {
    print('Connected');
  });

  socket.on('message', (data) {
    print('Message: $data');
  });

  socket.connect(config);
}
```

## Main ways to use it

1. App-level singleton with `SocketClient.shared`
2. Feature-level instance with `SocketClient()`
3. Dependency injection with Riverpod, Provider, GetIt, or Bloc
4. Callback listeners with `on`, `once`, and `onAny`
5. Reactive UI with `statusStream` and `events`
6. Request-response style socket calls with `emitWithAck`

## SocketConfig example

```dart
final config = SocketConfig(
  url: 'https://api.example.com',
  path: '/socket.io/',
  auth: {'token': 'jwt-token'},
  query: {'appVersion': '1.0.0'},
  extraHeaders: {'Authorization': 'Bearer jwt-token'},
  autoConnect: true,
  enableReconnection: true,
  reconnectionAttempts: 5,
  reconnectionDelay: const Duration(seconds: 2),
  reconnectionDelayMax: const Duration(seconds: 10),
  connectionTimeout: const Duration(seconds: 20),
  ackTimeout: const Duration(seconds: 15),
  transports: const ['websocket'],
  enableLogging: true,
);
```

## Common operations

### Listen to an event

```dart
final subscription = socket.on('message', (data) {
  print('Message payload: $data');
});

subscription.cancel();
```

### Listen once

```dart
socket.once('profile_updated', (data) {
  print('Runs once: $data');
});
```

### Listen to all events

```dart
socket.onAny((event, data) {
  print('$event => $data');
});
```

### Emit

```dart
socket.emit('typing', {'roomId': 10});
```

### Emit with ack

```dart
final response = await socket.emitWithAck(
  'send_message',
  data: {'roomId': 10, 'text': 'Hello'},
);

print(response);
```

### Wait for one future event

```dart
final users = await socket.waitFor('online_users');
print(users);
```

### Room helpers

```dart
socket.joinRoom('chat-room', data: {'userId': 7});
socket.leaveRoom('chat-room');
```

## Flutter integration

### StreamBuilder

```dart
StreamBuilder<SocketConnectionStatus>(
  stream: socket.statusStream,
  builder: (context, snapshot) {
    final status = snapshot.data ?? SocketConnectionStatus.disconnected;
    return Text('Status: $status');
  },
);
```

### Provider or Riverpod style

```dart
final socketProvider = Provider<SocketClient>((ref) {
  final socket = SocketClient();

  socket.connect(
    SocketConfig(
      url: 'https://api.example.com',
      autoConnect: true,
    ),
  );

  ref.onDispose(() => socket.dispose());
  return socket;
});
```

## Error handling

```dart
try {
  socket.emit('send_message', {'text': 'hello'});
} on SocketNotConnectedException catch (error) {
  print(error.message);
} on SocketTimeoutException catch (error) {
  print(error.message);
} on SocketException catch (error) {
  print(error.message);
}
```

## Important notes

- Use `disconnect()` when you may reuse the same instance later.
- Use `dispose()` only when that socket instance is finished forever.
- If auth, query, or headers change, rebuild with `reconnectWithConfig()`.
- If your backend uses different room event names, pass `joinEvent`, `leaveEvent`, or `roomKey`.

## Files to import

- `socket_service.dart`: recommended single import
- `index.dart`: compatibility export
- `examples.dart`: reference file only
