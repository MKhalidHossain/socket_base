import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import 'socket_config.dart';
import 'socket_events.dart';
import 'socket_exceptions.dart';

/// Cancelable handle returned by listener registration helpers.
class SocketSubscription {
  SocketSubscription(this._onCancel);

  final void Function() _onCancel;
  bool _isCanceled = false;

  /// Removes the listener only once.
  void cancel() {
    if (_isCanceled) {
      return;
    }

    _isCanceled = true;
    _onCancel();
  }
}

/// Reusable Socket.IO client for Flutter projects.
///
/// Recommended usage patterns:
/// 1. Create one shared instance with dependency injection for the whole app.
/// 2. Create one feature-scoped instance if a screen owns the socket lifecycle.
/// 3. Use `statusStream` and `events` when you prefer reactive UI updates.
class SocketClient {
  SocketClient({SocketConfig? config}) : _config = config;

  /// Optional app-wide singleton if you want one shared connection.
  static final SocketClient shared = SocketClient();

  final StreamController<SocketConnectionStatus> _statusController =
      StreamController<SocketConnectionStatus>.broadcast();
  final StreamController<SocketEvent> _eventController =
      StreamController<SocketEvent>.broadcast();

  final Map<String, Map<SocketEventHandler, SocketEventHandler>>
  _eventHandlers = {};
  final Map<String, Map<SocketEventHandler, SocketEventHandler>> _onceHandlers =
      {};
  final Map<SocketAnyEventHandler, void Function(dynamic, [dynamic])>
  _anyHandlers = {};

  io.Socket? _socket;
  SocketConfig? _config;
  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;
  bool _isDisposed = false;
  void Function(dynamic, [dynamic])? _internalAnyHandler;

  /// Active config on the current socket instance.
  SocketConfig? get currentConfig => _config;

  /// Exposes the raw Socket.IO socket for edge cases.
  io.Socket? get rawSocket => _socket;

  /// True when the underlying socket is connected.
  bool get isConnected => _socket?.connected ?? false;

  /// True after `connect()` created a socket instance.
  bool get isInitialized => _socket != null;

  /// Current lifecycle status.
  SocketConnectionStatus get status => _status;

  /// Reactive connection status updates.
  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;

  /// Reactive stream of lifecycle and custom socket events.
  Stream<SocketEvent> get events => _eventController.stream;

  /// Builds the socket and starts the connection flow.
  ///
  /// Call this again with a new config to recreate the socket with fresh values.
  void connect([SocketConfig? config]) {
    _ensureUsable();

    final resolvedConfig = config ?? _config;
    if (resolvedConfig == null) {
      throw SocketConfigurationException(
        'No SocketConfig was provided. Pass a config to connect().',
      );
    }

    _validateConfig(resolvedConfig);
    _config = resolvedConfig;

    try {
      _disposeSocketInstance();

      final builder = io.OptionBuilder()
          .setTransports(resolvedConfig.transports)
          .setPath(resolvedConfig.path)
          .setTimeout(resolvedConfig.connectionTimeout.inMilliseconds)
          .setAckTimeout(resolvedConfig.ackTimeout.inMilliseconds)
          .setRememberUpgrade(resolvedConfig.rememberUpgrade);

      if (resolvedConfig.forceNew) {
        builder.enableForceNew();
      } else {
        builder.disableForceNew();
      }

      if (resolvedConfig.withCredentials) {
        builder.enableWithCredentials();
      }

      if (resolvedConfig.autoConnect) {
        builder.enableAutoConnect();
      } else {
        builder.disableAutoConnect();
      }

      if (resolvedConfig.enableReconnection) {
        builder.enableReconnection();
      } else {
        builder.disableReconnection();
      }

      if (resolvedConfig.reconnectionAttempts != null) {
        builder.setReconnectionAttempts(resolvedConfig.reconnectionAttempts!);
      }

      builder
        ..setReconnectionDelay(resolvedConfig.reconnectionDelay.inMilliseconds)
        ..setReconnectionDelayMax(
          resolvedConfig.reconnectionDelayMax.inMilliseconds,
        );

      if (resolvedConfig.query != null && resolvedConfig.query!.isNotEmpty) {
        builder.setQuery(resolvedConfig.query!);
      }

      if (resolvedConfig.auth != null && resolvedConfig.auth!.isNotEmpty) {
        builder.setAuth(resolvedConfig.auth!);
      }

      if (resolvedConfig.extraHeaders != null &&
          resolvedConfig.extraHeaders!.isNotEmpty) {
        builder.setExtraHeaders(resolvedConfig.extraHeaders!);
      }

      _socket = io.io(resolvedConfig.url, builder.build());
      _attachCoreListeners();
      _bindStoredListeners();

      if (resolvedConfig.autoConnect) {
        _updateStatus(SocketConnectionStatus.connecting);
        _log('Connecting to ${resolvedConfig.url}');
      } else {
        _updateStatus(SocketConnectionStatus.disconnected);
        _log('Socket created. Call manualConnect() when you are ready.');
      }
    } catch (error) {
      _log('Socket initialization failed: $error');
      throw SocketInitializationException(error);
    }
  }

  /// Starts the connection when `autoConnect` is disabled.
  void manualConnect() {
    _ensureUsable();

    if (_socket == null) {
      connect();
    }

    _updateStatus(SocketConnectionStatus.connecting);
    _log('Manual socket connect requested');
    _socket?.connect();
  }

  /// Emits a fire-and-forget event.
  void emit(String event, [dynamic data]) {
    _ensureConnected();

    try {
      _socket?.emit(event, data);
      _log('Emitted event: $event');
    } catch (error) {
      _log('Emit failed for $event: $error');
      throw SocketEmitException(event, error);
    }
  }

  /// Emits an event and waits for server acknowledgement.
  Future<dynamic> emitWithAck(
    String event, {
    dynamic data,
    Duration? timeout,
  }) async {
    _ensureConnected();

    try {
      final socket = _socket!;
      final ackSocket = timeout == null
          ? socket
          : socket.timeout(timeout.inMilliseconds);

      final response = await ackSocket.emitWithAckAsync(event, data);
      _log('Ack received for event: $event');
      return response;
    } catch (_) {
      throw SocketTimeoutException('ack for "$event"');
    }
  }

  /// Waits for the next occurrence of an event and returns its payload.
  Future<dynamic> waitFor(
    String event, {
    Duration timeout = const Duration(seconds: 15),
  }) {
    _ensureUsable();

    final completer = Completer<dynamic>();
    late final SocketSubscription subscription;
    Timer? timer;

    subscription = once(event, (data) {
      timer?.cancel();
      if (!completer.isCompleted) {
        completer.complete(data);
      }
    });

    timer = Timer(timeout, () {
      subscription.cancel();
      if (!completer.isCompleted) {
        completer.completeError(SocketTimeoutException(event));
      }
    });

    return completer.future;
  }

  /// Registers a normal event listener.
  ///
  /// Store the returned subscription if you want easy cleanup in `dispose()`.
  SocketSubscription on(String event, SocketEventHandler handler) {
    _ensureUsable();

    final handlers = _eventHandlers.putIfAbsent(event, () => {});
    if (handlers.containsKey(handler)) {
      return SocketSubscription(() => off(event, handler));
    }

    handlers[handler] = handler;
    _socket?.on(event, handler);

    return SocketSubscription(() => off(event, handler));
  }

  /// Registers a one-time listener that removes itself after the first event.
  SocketSubscription once(String event, SocketEventHandler handler) {
    _ensureUsable();

    final handlers = _onceHandlers.putIfAbsent(event, () => {});
    if (handlers.containsKey(handler)) {
      return SocketSubscription(() => off(event, handler));
    }

    void wrapper(dynamic data) {
      off(event, handler);
      handler(data);
    }

    handlers[handler] = wrapper;
    _socket?.on(event, wrapper);

    return SocketSubscription(() => off(event, handler));
  }

  /// Removes a listener for one event.
  ///
  /// Call `off('message')` to clear all handlers for only that event.
  void off(String event, [SocketEventHandler? handler]) {
    if (_socket == null && handler == null) {
      _eventHandlers.remove(event);
      _onceHandlers.remove(event);
      return;
    }

    if (handler == null) {
      _socket?.off(event);
      _eventHandlers.remove(event);
      _onceHandlers.remove(event);
      return;
    }

    final normalWrapper = _eventHandlers[event]?.remove(handler);
    if (normalWrapper != null) {
      _socket?.off(event, normalWrapper);
    }

    final onceWrapper = _onceHandlers[event]?.remove(handler);
    if (onceWrapper != null) {
      _socket?.off(event, onceWrapper);
    }

    if (_eventHandlers[event]?.isEmpty ?? false) {
      _eventHandlers.remove(event);
    }

    if (_onceHandlers[event]?.isEmpty ?? false) {
      _onceHandlers.remove(event);
    }
  }

  /// Registers a catch-all listener for every incoming socket event.
  SocketSubscription onAny(SocketAnyEventHandler handler) {
    _ensureUsable();

    if (_anyHandlers.containsKey(handler)) {
      return SocketSubscription(() => offAny(handler));
    }

    void wrapper(dynamic event, [dynamic data]) {
      handler(event.toString(), data);
    }

    _anyHandlers[handler] = wrapper;
    _socket?.onAny(wrapper);

    return SocketSubscription(() => offAny(handler));
  }

  /// Removes one catch-all listener or all of them.
  void offAny([SocketAnyEventHandler? handler]) {
    if (handler == null) {
      for (final wrapper in _anyHandlers.values) {
        _socket?.offAny(wrapper);
      }
      _anyHandlers.clear();
      return;
    }

    final wrapper = _anyHandlers.remove(handler);
    if (wrapper != null) {
      _socket?.offAny(wrapper);
    }
  }

  /// Removes every custom listener registered through this client.
  void clearCustomListeners() {
    for (final event in {..._eventHandlers.keys, ..._onceHandlers.keys}) {
      _socket?.off(event);
    }

    offAny();
    _eventHandlers.clear();
    _onceHandlers.clear();
  }

  /// Helper for joining a room with the common `join` event convention.
  void joinRoom(
    String room, {
    Map<String, dynamic>? data,
    String joinEvent = 'join',
    String roomKey = 'room',
  }) {
    emit(joinEvent, {roomKey: room, ...?data});
  }

  /// Helper for leaving a room with the common `leave` event convention.
  void leaveRoom(
    String room, {
    Map<String, dynamic>? data,
    String leaveEvent = 'leave',
    String roomKey = 'room',
  }) {
    emit(leaveEvent, {roomKey: room, ...?data});
  }

  /// Disconnects but keeps the client reusable.
  void disconnect() {
    _ensureUsable();
    _socket?.disconnect();
    _updateStatus(SocketConnectionStatus.disconnected);
    _log('Socket disconnected');
  }

  /// Reconnects using the existing socket or recreates it from the last config.
  void reconnect() {
    _ensureUsable();

    if (_socket != null) {
      _updateStatus(SocketConnectionStatus.reconnecting);
      _log('Socket reconnect requested');
      _socket?.disconnect();
      _socket?.connect();
      return;
    }

    connect();
    if (!(_config?.autoConnect ?? true)) {
      manualConnect();
    }
  }

  /// Recreates the socket with a fresh config.
  void reconnectWithConfig(SocketConfig config) {
    _ensureUsable();
    connect(config);
    if (!config.autoConnect) {
      manualConnect();
    }
  }

  /// Fully disposes the client.
  ///
  /// Use this only when the instance will never be reused again.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _disposeSocketInstance();
    clearCustomListeners();
    _isDisposed = true;
    _config = null;

    await _statusController.close();
    await _eventController.close();
  }

  void _attachCoreListeners() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    socket.onConnect((_) {
      _updateStatus(SocketConnectionStatus.connected);
      _eventController.add(
        SocketLifecycleEvent(
          status: SocketConnectionStatus.connected,
          name: 'connect',
        ),
      );
      _log('Socket connected');
    });

    socket.onDisconnect((reason) {
      _updateStatus(SocketConnectionStatus.disconnected);
      _eventController.add(
        SocketLifecycleEvent(
          status: SocketConnectionStatus.disconnected,
          name: 'disconnect',
          data: reason,
        ),
      );
      _log('Socket disconnected: $reason');
    });

    socket.onConnectError((error) {
      _eventController.add(
        SocketLifecycleEvent(
          status: SocketConnectionStatus.disconnected,
          name: 'connect_error',
          data: error,
        ),
      );
      _log('Connect error: $error');
    });

    socket.onError((error) {
      _eventController.add(
        SocketLifecycleEvent(status: _status, name: 'error', data: error),
      );
      _log('Socket error: $error');
    });

    socket.on('reconnect_attempt', (attempt) {
      final parsedAttempt = attempt is int ? attempt : int.tryParse('$attempt');
      _updateStatus(SocketConnectionStatus.reconnecting);
      _eventController.add(
        SocketReconnectAttemptEvent(attempt: parsedAttempt ?? 0, data: attempt),
      );
      _log('Reconnect attempt: ${parsedAttempt ?? attempt}');
    });

    socket.on('reconnect', (attempt) {
      _updateStatus(SocketConnectionStatus.connected);
      _eventController.add(
        SocketLifecycleEvent(
          status: SocketConnectionStatus.connected,
          name: 'reconnect',
          data: attempt,
        ),
      );
      _log('Socket reconnected');
    });

    socket.on('reconnect_error', (error) {
      _eventController.add(
        SocketLifecycleEvent(
          status: SocketConnectionStatus.reconnecting,
          name: 'reconnect_error',
          data: error,
        ),
      );
      _log('Reconnect error: $error');
    });

    socket.on('reconnect_failed', (error) {
      _updateStatus(SocketConnectionStatus.disconnected);
      _eventController.add(
        SocketLifecycleEvent(
          status: SocketConnectionStatus.disconnected,
          name: 'reconnect_failed',
          data: error,
        ),
      );
      _log('Reconnect failed: $error');
    });

    void internalAnyHandler(dynamic event, [dynamic data]) {
      _eventController.add(
        SocketCustomEvent(name: event.toString(), data: data),
      );
    }

    _internalAnyHandler = internalAnyHandler;
    socket.onAny(internalAnyHandler);
  }

  void _bindStoredListeners() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    for (final entry in _eventHandlers.entries) {
      for (final wrapper in entry.value.values) {
        socket.on(entry.key, wrapper);
      }
    }

    for (final entry in _onceHandlers.entries) {
      for (final wrapper in entry.value.values) {
        socket.on(entry.key, wrapper);
      }
    }

    for (final wrapper in _anyHandlers.values) {
      socket.onAny(wrapper);
    }
  }

  void _disposeSocketInstance() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    if (_internalAnyHandler != null) {
      socket.offAny(_internalAnyHandler);
      _internalAnyHandler = null;
    }

    socket.dispose();
    _socket = null;
    _updateStatus(SocketConnectionStatus.disconnected);
  }

  void _updateStatus(SocketConnectionStatus next) {
    _status = next;
    if (!_statusController.isClosed) {
      _statusController.add(next);
    }
  }

  void _validateConfig(SocketConfig config) {
    if (config.url.trim().isEmpty) {
      throw SocketConfigurationException('`url` cannot be empty.');
    }

    if (config.path.trim().isEmpty) {
      throw SocketConfigurationException('`path` cannot be empty.');
    }

    if (config.connectionTimeout <= Duration.zero) {
      throw SocketConfigurationException(
        '`connectionTimeout` must be greater than zero.',
      );
    }

    if (config.ackTimeout <= Duration.zero) {
      throw SocketConfigurationException(
        '`ackTimeout` must be greater than zero.',
      );
    }
  }

  void _ensureConnected() {
    _ensureUsable();

    if (!isConnected) {
      throw SocketNotConnectedException();
    }
  }

  void _ensureUsable() {
    if (_isDisposed) {
      throw SocketDisposedException();
    }
  }

  void _log(String message) {
    final config = _config;
    if (config == null || !config.enableLogging) {
      return;
    }

    final logger = config.logger;
    if (logger != null) {
      logger('[SocketClient] $message');
      return;
    }

    // ignore: avoid_print
    print('[SocketClient] $message');
  }
}
