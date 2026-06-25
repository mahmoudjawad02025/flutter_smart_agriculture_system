import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../../features/firebase_data/models/farm_payload.dart';

/// Centralized, shared Firebase query streams.
///
/// Each shared stream keeps a single underlying subscription to the
/// corresponding `Query.onValue` and forwards events to all listeners.
/// The implementation caches the last received `DatabaseEvent` and
/// re-emits it to newly attached listeners so UI widgets don't see an
/// indefinite loading state when they subscribe after the first event.
class FirebaseStreams {
  static FirebaseDatabase get _db => FirebaseDatabase.instance;

  static _SharedQueryStream? _root;
  static Stream<DatabaseEvent> get rootStream {
    _root ??= _SharedQueryStream(FarmPayload.rootRef(_db));
    return _root!.stream;
  }

  static DatabaseEvent? get lastRootEvent => _root?._lastEvent;

  static _SharedQueryStream? _leaf;
  static Stream<DatabaseEvent> get leafStream {
    _leaf ??= _SharedQueryStream(_db.ref(FarmPayload.leafPath));
    return _leaf!.stream;
  }

  static DatabaseEvent? get lastLeafEvent => _leaf?._lastEvent;

  static _SharedQueryStream? _pumps;
  static Stream<DatabaseEvent> get pumpsStream {
    _pumps ??= _SharedQueryStream(_db.ref(FarmPayload.pumpsPath));
    return _pumps!.stream;
  }

  static DatabaseEvent? get lastPumpsEvent => _pumps?._lastEvent;

  static _SharedQueryStream? _config;
  static Stream<DatabaseEvent> get configStream {
    _config ??= _SharedQueryStream(_db.ref(FarmPayload.configPath));
    return _config!.stream;
  }

  static DatabaseEvent? get lastConfigEvent => _config?._lastEvent;

  static _SharedQueryStream? _logs;
  static Stream<DatabaseEvent> get logsStream {
    _logs ??= _SharedQueryStream(_db.ref(FarmPayload.logsPath));
    return _logs!.stream;
  }

  static DatabaseEvent? get lastLogsEvent => _logs?._lastEvent;

  static _SharedQueryStream? _notificationItems;
  static Stream<DatabaseEvent> get notificationItemsStream {
    _notificationItems ??= _SharedQueryStream(
      _db.ref(FarmPayload.notificationItemsPath),
    );
    return _notificationItems!.stream;
  }

  static DatabaseEvent? get lastNotificationItemsEvent =>
      _notificationItems?._lastEvent;

  static _SharedQueryStream? _unreadCount;
  static Stream<DatabaseEvent> get unreadCountStream {
    _unreadCount ??= _SharedQueryStream(_db.ref(FarmPayload.unreadCountPath));
    return _unreadCount!.stream;
  }

  static DatabaseEvent? get lastUnreadCountEvent => _unreadCount?._lastEvent;
}

class _SharedQueryStream {
  _SharedQueryStream(this._query);

  final Query _query;
  StreamController<DatabaseEvent>? _controller;
  StreamSubscription<DatabaseEvent>? _subscription;
  DatabaseEvent? _lastEvent;

  Stream<DatabaseEvent> get stream {
    _controller ??= StreamController<DatabaseEvent>.broadcast(
      onListen: _handleListen,
      onCancel: _handleCancel,
    );
    return _controller!.stream;
  }

  void _handleListen() {
    _subscription ??= _query.onValue.listen(
      (DatabaseEvent event) {
        _lastEvent = event;
        try {
          _controller?.add(event);
        } catch (_) {}
      },
      onError: (Object e, StackTrace? s) {
        _controller?.addError(e, s);
      },
    );

    final DatabaseEvent? cached = _lastEvent;
    if (cached != null) {
      scheduleMicrotask(() {
        if (_controller?.hasListener ?? false) {
          try {
            _controller?.add(cached);
          } catch (_) {}
        }
      });
    }
  }

  void _handleCancel() {
    // If there are no more listeners, cancel the underlying subscription
    // to avoid keeping the native query active unnecessarily.
    if (!(_controller?.hasListener ?? false)) {
      _subscription?.cancel();
      _subscription = null;
    }
  }
}
