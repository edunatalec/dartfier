/// @docImport 'package:dartfier/dartfier.dart';
library;

import 'package:flutter/widgets.dart';

import 'tracker.dart';

/// A widget that rebuilds when any reactive value read in its builder
/// changes.
///
/// {@category Widgets}
///
/// The builder runs under dependency tracking: every [Signal] or [Computed]
/// read inside it subscribes the widget, with no listenable lists and no
/// [Listenable.merge]. Dependencies are rediscovered on every build, so
/// conditional reads stay correct.
///
/// ```dart
/// Observer((context) => Text('${count.value}'))
/// ```
///
/// Reads must happen in the builder body itself: closures that run later —
/// a nested [Builder], a gesture callback — execute outside tracking and do
/// not subscribe. In debug mode, a builder that tracks nothing throws a
/// [FlutterError], since such an observer would never rebuild.
///
/// The builder must not write to a value the observer tracks: the framework
/// discards a rebuild marked from inside a build, so the UI would silently
/// show stale state. In debug mode, such a write throws a [FlutterError].
///
/// A foreign [Listenable] — a [FocusNode], a [ScrollController], any
/// notifier that is not a [Signal] — is invisible to tracking. Pass it
/// through [listenables] to have the observer rebuild on its notifications
/// too, alongside the tracked reads:
///
/// ```dart
/// Observer(
///   (context) => Text(focusNode.hasFocus ? query.value : ''),
///   listenables: [focusNode],
/// )
/// ```
///
/// See also:
///
///  * [Observer.withChild], which keeps a heavy static subtree out of the
///    rebuilt region.
///  * [Effect], which does the same job outside the widget tree.
///  * [ReadonlySignal.peek], to read a value in the builder without
///    subscribing to it.
class Observer extends StatefulWidget {
  /// Creates an observer that rebuilds when values read in `builder` change.
  const Observer(
    Widget Function(BuildContext context) this._builder, {
    super.key,
    this.listenables,
  }) : _childBuilder = null,
       child = null;

  /// Creates an observer whose [child] subtree is built once and passed back
  /// to `builder` on every rebuild.
  ///
  /// Use it to keep a heavy static subtree out of the rebuilt region:
  ///
  /// ```dart
  /// Observer.withChild(
  ///   builder: (context, child) => Column(
  ///     children: [Text('${count.value}'), child!],
  ///   ),
  ///   child: const HeavyStaticWidget(),
  /// )
  /// ```
  const Observer.withChild({
    required Widget Function(BuildContext context, Widget? child) builder,
    super.key,
    this.child,
    this.listenables,
  }) : _builder = null,
       _childBuilder = builder;

  final Widget Function(BuildContext context)? _builder;

  final Widget Function(BuildContext context, Widget? child)? _childBuilder;

  /// Subtree passed back to the [Observer.withChild] builder without being
  /// rebuilt.
  final Widget? child;

  /// Foreign [Listenable]s that also trigger a rebuild when they notify.
  ///
  /// Auto-tracking only sees [Signal] and [Computed] reads; a plain
  /// [Listenable] consulted in the builder — a [FocusNode], a text
  /// controller — never subscribes. Listing it here subscribes the observer
  /// manually, so one widget combines tracked reads with untracked sources.
  /// The subscription follows the list by element identity: it is kept while
  /// the elements stay identical and renewed when they change. With a
  /// non-empty list, the debug no-dependency error does not throw.
  final List<Listenable>? listenables;

  @override
  State<Observer> createState() => _ObserverState();
}

class _ObserverState extends State<Observer> {
  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  Listenable? _merged;

  bool _building = false;

  @override
  void initState() {
    super.initState();

    _subscribeListenables();
  }

  @override
  void didUpdateWidget(Observer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_sameElements(oldWidget.listenables, widget.listenables)) return;

    _unsubscribeListenables();
    _subscribeListenables();
  }

  @override
  Widget build(BuildContext context) {
    _building = true;

    final Widget built;
    try {
      built = _dependencies.track(() {
        final Widget Function(BuildContext context)? builder = widget._builder;

        if (builder != null) return builder(context);

        return widget._childBuilder!(context, widget.child);
      });
    } finally {
      _building = false;
    }

    assert(() {
      final bool subscribed = widget.listenables?.isNotEmpty ?? false;

      if (!_dependencies.hasDependencies && !subscribed) {
        throw FlutterError(
          'Observer built without reading any Signal or Computed, so it will '
          'never rebuild on its own. Read a reactive value inside the '
          'builder, pass listenables, or remove the Observer.',
        );
      }

      return true;
    }());

    return built;
  }

  void _onDependencyChanged() {
    if (!mounted) return;

    assert(() {
      if (!_building) return true;

      throw FlutterError(
        'Observer builder wrote to a Signal (or notified a Listenable) this '
        'observer is subscribed to. The framework discards a rebuild marked '
        'from inside a build, so the UI would silently show stale state. '
        'Move the write out of the builder — a callback, an Effect — or '
        'read the value with peek().',
      );
    }());

    setState(() {});
  }

  void _subscribeListenables() {
    final List<Listenable>? listenables = widget.listenables;

    if (listenables == null || listenables.isEmpty) return;

    _merged = Listenable.merge(List<Listenable>.of(listenables))
      ..addListener(_onDependencyChanged);
  }

  void _unsubscribeListenables() {
    _merged?.removeListener(_onDependencyChanged);
    _merged = null;
  }

  bool _sameElements(List<Listenable>? previous, List<Listenable>? next) {
    final List<Listenable> left = previous ?? const [];
    final List<Listenable> right = next ?? const [];

    if (left.length != right.length) return false;

    for (int i = 0; i < left.length; i++) {
      if (!identical(left[i], right[i])) return false;
    }

    return true;
  }

  @override
  void dispose() {
    _unsubscribeListenables();
    _dependencies.dispose();

    super.dispose();
  }
}
