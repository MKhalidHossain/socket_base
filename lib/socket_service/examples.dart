// ignore_for_file: avoid_print

import 'package:socket_base/socket_service/socket_service.dart';

/// Example 1
///
/// The most common setup for one shared app-level socket instance.
void basicSocketExample() {
  final socket = SocketClient.shared;

  // Step 1: describe how the socket should connect.
  final config = SocketConfig(
    url: 'https://api.example.com',
    auth: {'token': 'your-jwt-token'},
    enableLogging: true,
  );

  // Step 2: register listeners before or after connect.
  socket.on('message', (data) {
    print('Incoming message: $data');
  });

  // Step 3: connect once during app startup.
  socket.connect(config);
}

/// Example 2
///
/// Manual connect mode is useful when the user must log in first.
void manualConnectionExample() {
  final socket = SocketClient();

  // Disable auto connect when you want full control over timing.
  final config = SocketConfig(
    url: 'https://api.example.com',
    autoConnect: false,
    auth: {'token': 'token-after-login'},
  );

  socket.connect(config);

  // Call this only when your app is ready to open the connection.
  socket.manualConnect();
}

/// Example 3
///
/// Ack requests are useful for request/response style socket actions.
Future<void> emitWithAckExample() async {
  final socket = SocketClient.shared;

  try {
    final response = await socket.emitWithAck(
      'send_message',
      data: {'roomId': 'support-room', 'text': 'Hello from Flutter'},
    );

    print('Server ack response: $response');
  } on SocketTimeoutException catch (error) {
    print('Ack timed out: ${error.message}');
  }
}

/// Example 4
///
/// Room helpers keep the usual `join` and `leave` payload shape consistent.
void roomExample() {
  final socket = SocketClient.shared;

  socket.joinRoom('chat-room-1', data: {'userId': 7, 'role': 'member'});

  socket.emit('room_message', {
    'room': 'chat-room-1',
    'text': 'Hello everyone',
  });

  socket.leaveRoom('chat-room-1');
}

/// Example 5
///
/// `statusStream` and `events` are convenient with Bloc, Riverpod, or StreamBuilder.
void reactiveExample() {
  final socket = SocketClient.shared;

  socket.statusStream.listen((status) {
    print('Socket status changed: $status');
  });

  socket.events.listen((event) {
    print('Socket event: ${event.name} -> ${event.data}');
  });
}

/// Example 6
///
/// `once` and `waitFor` are useful when a screen needs exactly one reply.
Future<void> oneTimeResponseExample() async {
  final socket = SocketClient.shared;

  socket.once('profile_updated', (data) {
    print('First update only: $data');
  });

  final nextOnlineUsers = await socket.waitFor('online_users');
  print('Next online users event: $nextOnlineUsers');
}

/// Example 7
///
/// Always clean up feature-scoped sockets to avoid duplicate listeners.
Future<void> cleanupExample() async {
  final socket = SocketClient();

  socket.connect(
    SocketConfig(url: 'https://api.example.com', autoConnect: false),
  );

  socket.clearCustomListeners();
  socket.disconnect();
  await socket.dispose();
}
