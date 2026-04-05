/// Base exception for reusable socket failures.
abstract class SocketException implements Exception {
  SocketException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when a method needs an active connection.
class SocketNotConnectedException extends SocketException {
  SocketNotConnectedException()
    : super('Socket is not connected. Connect first before using this call.');
}

/// Thrown when connect fails because the input config is invalid.
class SocketConfigurationException extends SocketException {
  SocketConfigurationException(String detail)
    : super('Invalid socket configuration: $detail');
}

/// Thrown when the socket cannot be initialized.
class SocketInitializationException extends SocketException {
  SocketInitializationException(this.originalError)
    : super('Failed to initialize socket: $originalError');

  final dynamic originalError;
}

/// Thrown when the socket cannot connect to the backend.
class SocketConnectionFailedException extends SocketException {
  SocketConnectionFailedException(this.originalError)
    : super('Failed to connect to the socket server: $originalError');

  final dynamic originalError;
}

/// Thrown when an event cannot be emitted.
class SocketEmitException extends SocketException {
  SocketEmitException(String event, [dynamic originalError])
    : super(
        originalError == null
            ? 'Failed to emit event: $event.'
            : 'Failed to emit event: $event. Error: $originalError',
      );
}

/// Thrown when an ack or one-time wait operation takes too long.
class SocketTimeoutException extends SocketException {
  SocketTimeoutException(String operation)
    : super('Socket timed out while waiting for: $operation');
}

/// Thrown when a disposed client is used again.
class SocketDisposedException extends SocketException {
  SocketDisposedException()
    : super('SocketClient was disposed and cannot be used again.');
}
