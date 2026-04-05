typedef SocketLogger = void Function(String message);

/// Central connection settings for one socket instance.
///
/// Keep this object in your app config layer so you can swap environments,
/// tokens, rooms, and reconnection behavior without editing the client code.
class SocketConfig {
  SocketConfig({
    required this.url,
    this.path = '/socket.io/',
    this.query,
    this.auth,
    this.extraHeaders,
    this.autoConnect = true,
    this.enableReconnection = true,
    this.reconnectionAttempts,
    this.reconnectionDelay = const Duration(seconds: 2),
    this.reconnectionDelayMax = const Duration(seconds: 10),
    this.connectionTimeout = const Duration(seconds: 20),
    this.ackTimeout = const Duration(seconds: 15),
    this.transports = const ['websocket'],
    this.forceNew = true,
    this.rememberUpgrade = false,
    this.withCredentials = false,
    this.enableLogging = true,
    this.logger,
  });

  /// Full server url or namespace url.
  ///
  /// Example:
  /// `https://api.example.com`
  /// `https://api.example.com/chat`
  final String url;

  /// Socket.IO path on the backend.
  ///
  /// Leave the default value unless your backend uses a custom path.
  final String path;

  /// Extra query values sent during the handshake.
  final Map<String, dynamic>? query;

  /// Auth payload used by the backend during connection.
  final Map<String, dynamic>? auth;

  /// Extra headers sent during the handshake.
  final Map<String, dynamic>? extraHeaders;

  /// When `true`, the socket starts connecting immediately after creation.
  ///
  /// Set this to `false` if you want to prepare listeners first and connect
  /// later with `manualConnect()`.
  final bool autoConnect;

  /// Enables Socket.IO automatic reconnection behavior.
  final bool enableReconnection;

  /// Total reconnect attempts before giving up.
  ///
  /// Leave `null` to use the package default behavior.
  final int? reconnectionAttempts;

  /// Delay before the first reconnect attempt.
  final Duration reconnectionDelay;

  /// Max delay between reconnect attempts.
  final Duration reconnectionDelayMax;

  /// Timeout used while opening the socket connection.
  final Duration connectionTimeout;

  /// Default timeout for `emitWithAck`.
  final Duration ackTimeout;

  /// Transport order used by the Socket.IO client.
  final List<String> transports;

  /// Forces a fresh low-level manager instead of reusing an older one.
  final bool forceNew;

  /// Uses websocket first after a successful previous upgrade.
  final bool rememberUpgrade;

  /// Sends cookies/credentials when supported by the platform.
  final bool withCredentials;

  /// Toggles internal logs.
  final bool enableLogging;

  /// Optional custom logger.
  ///
  /// If omitted, `print` is used when `enableLogging` is `true`.
  final SocketLogger? logger;

  /// Creates a new config with selected overrides.
  SocketConfig copyWith({
    String? url,
    String? path,
    Map<String, dynamic>? query,
    Map<String, dynamic>? auth,
    Map<String, dynamic>? extraHeaders,
    bool? autoConnect,
    bool? enableReconnection,
    int? reconnectionAttempts,
    Duration? reconnectionDelay,
    Duration? reconnectionDelayMax,
    Duration? connectionTimeout,
    Duration? ackTimeout,
    List<String>? transports,
    bool? forceNew,
    bool? rememberUpgrade,
    bool? withCredentials,
    bool? enableLogging,
    SocketLogger? logger,
  }) {
    return SocketConfig(
      url: url ?? this.url,
      path: path ?? this.path,
      query: query ?? this.query,
      auth: auth ?? this.auth,
      extraHeaders: extraHeaders ?? this.extraHeaders,
      autoConnect: autoConnect ?? this.autoConnect,
      enableReconnection: enableReconnection ?? this.enableReconnection,
      reconnectionAttempts: reconnectionAttempts ?? this.reconnectionAttempts,
      reconnectionDelay: reconnectionDelay ?? this.reconnectionDelay,
      reconnectionDelayMax: reconnectionDelayMax ?? this.reconnectionDelayMax,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      ackTimeout: ackTimeout ?? this.ackTimeout,
      transports: transports ?? this.transports,
      forceNew: forceNew ?? this.forceNew,
      rememberUpgrade: rememberUpgrade ?? this.rememberUpgrade,
      withCredentials: withCredentials ?? this.withCredentials,
      enableLogging: enableLogging ?? this.enableLogging,
      logger: logger ?? this.logger,
    );
  }
}
