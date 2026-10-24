import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/domain/auth_models.dart';

/// Shares in-flight work only. Values are never retained after dispatch.
class SharedReadQueue<K, V> {
  SharedReadQueue({
    required this.load,
    required this.copy,
    this.release,
    this.concurrency = 4,
  }) : assert(concurrency > 0);
  final Future<V> Function(K, CancelToken) load;
  final V Function(V) copy;
  final void Function(V)? release;
  final int concurrency;
  final _entries = <Object?, _ReadEntry<V>>{};
  final _waiting = <_ReadEntry<V>>[];
  int _active = 0, _peak = 0, _started = 0, _joined = 0, _cancelled = 0;
  bool _closed = false;

  /// Aggregate counters contain no account, asset, URL or payload values.
  ({int active, int queued, int peak, int started, int joined, int cancelled})
  get statistics => (
    active: _active,
    queued: _waiting.length,
    peak: _peak,
    started: _started,
    joined: _joined,
    cancelled: _cancelled,
  );

  Future<V> read(K key, {CancelToken? cancelToken, bool priority = false}) {
    if (_closed || cancelToken?.isCancelled == true) {
      return Future.error(const AuthFailure('cancelled'));
    }
    var entry = _entries[key];
    if (entry == null) {
      entry = _ReadEntry<V>(key, priority);
      _entries[key] = entry;
      _waiting.add(entry);
    } else {
      _joined++;
      entry.priority = entry.priority || priority;
    }
    final subscriber = Completer<V>();
    entry.subscribers.add(subscriber);
    final owned = entry;
    cancelToken?.whenCancel.then((_) {
      if (!owned.subscribers.remove(subscriber)) return;
      _cancelled++;
      subscriber.completeError(const AuthFailure('cancelled'));
      if (owned.subscribers.isEmpty) _remove(owned);
    });
    _pump();
    return subscriber.future;
  }

  void _remove(_ReadEntry<V> entry) {
    if (identical(_entries[entry.key], entry)) _entries.remove(entry.key);
    _waiting.remove(entry);
    entry.token.cancel();
  }

  void _pump() {
    while (!_closed && _active < concurrency && _waiting.isNotEmpty) {
      final priority = _waiting.indexWhere((entry) => entry.priority);
      final entry = _waiting.removeAt(priority < 0 ? 0 : priority);
      _active++;
      _started++;
      if (_active > _peak) _peak = _active;
      unawaited(_run(entry));
    }
  }

  Future<void> _run(_ReadEntry<V> entry) async {
    try {
      final value = await load(entry.key as K, entry.token);
      try {
        for (final subscriber in entry.subscribers) {
          subscriber.complete(copy(value));
        }
      } finally {
        release?.call(value);
      }
    } catch (error, stack) {
      for (final subscriber in entry.subscribers) {
        if (!subscriber.isCompleted) subscriber.completeError(error, stack);
      }
    } finally {
      entry.subscribers.clear();
      _remove(entry);
      // A cancelled transport retains its slot until it actually settles.
      _active--;
      _pump();
    }
  }

  void clear() {
    for (final entry in _entries.values.toList()) {
      for (final subscriber in entry.subscribers) {
        _cancelled++;
        subscriber.completeError(const AuthFailure('cancelled'));
      }
      entry.subscribers.clear();
      _remove(entry);
    }
  }

  void dispose() {
    _closed = true;
    clear();
  }
}

class _ReadEntry<V> {
  _ReadEntry(this.key, this.priority);
  final Object? key;
  bool priority;
  final token = CancelToken();
  final subscribers = <Completer<V>>{};
}
