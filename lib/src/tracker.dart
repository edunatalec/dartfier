import 'package:flutter/foundation.dart';

abstract final class Tracker {
  static Set<Listenable>? _reads;

  static T collect<T>(Set<Listenable> reads, T Function() run) {
    final Set<Listenable>? previous = _reads;
    _reads = reads;

    try {
      return run();
    } finally {
      _reads = previous;
    }
  }

  static void reportRead(Listenable source) => _reads?.add(source);

  static T untracked<T>(T Function() run) {
    final Set<Listenable>? previous = _reads;
    _reads = null;

    try {
      return run();
    } finally {
      _reads = previous;
    }
  }
}

class DependencyBag {
  DependencyBag(this._onDependencyChanged);

  final VoidCallback _onDependencyChanged;

  Set<Listenable> _dependencies = const {};

  T track<T>(T Function() run) {
    final Set<Listenable> reads = <Listenable>{};
    final T result = Tracker.collect(reads, run);

    _swap(reads);

    return result;
  }

  void _swap(Set<Listenable> next) {
    for (final Listenable dependency in _dependencies) {
      if (!next.contains(dependency)) {
        dependency.removeListener(_onDependencyChanged);
      }
    }

    for (final Listenable dependency in next) {
      if (!_dependencies.contains(dependency)) {
        dependency.addListener(_onDependencyChanged);
      }
    }

    _dependencies = next;
  }

  void dispose() {
    for (final Listenable dependency in _dependencies) {
      dependency.removeListener(_onDependencyChanged);
    }

    _dependencies = const {};
  }
}
