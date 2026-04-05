/// Standard connection states exposed by the reusable client.
enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Signature for event listeners that receive one payload object.
typedef SocketEventHandler = void Function(dynamic data);

/// Signature for catch-all listeners that receive event name plus payload.
typedef SocketAnyEventHandler = void Function(String event, dynamic data);

/// Shared shape for all events emitted by [SocketClient.events].
abstract class SocketEvent {
  SocketEvent({required this.name, this.data}) : timestamp = DateTime.now();

  /// Incoming event name.
  final String name;

  /// Payload delivered by the socket server.
  final dynamic data;

  /// Local time when this event was received.
  final DateTime timestamp;
}

/// Lifecycle event used for connect/disconnect/reconnect transitions.
class SocketLifecycleEvent extends SocketEvent {
  SocketLifecycleEvent({required this.status, required super.name, super.data});

  final SocketConnectionStatus status;
}

/// Event emitted for reconnect attempts.
class SocketReconnectAttemptEvent extends SocketEvent {
  SocketReconnectAttemptEvent({required this.attempt, super.data})
    : super(name: 'reconnect_attempt');

  final int attempt;
}

/// Wrapper for all custom events delivered by the backend.
class SocketCustomEvent extends SocketEvent {
  SocketCustomEvent({required super.name, super.data});
}
