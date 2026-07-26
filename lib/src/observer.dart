import 'package:flutter/widgets.dart';

import 'tracker.dart';

/// A widget that rebuilds when any reactive value read in its builder
/// changes.
///
/// The builder runs under dependency tracking: every `Signal` or `Computed`
/// read inside it subscribes the widget, with no listenable lists and no
/// `Listenable.merge`. Dependencies are rediscovered on every build, so
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
class Observer extends StatefulWidget {
  /// Creates an observer that rebuilds when values read in `builder` change.
  const Observer(
    Widget Function(BuildContext context) this._builder, {
    super.key,
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
  }) : _builder = null,
       _childBuilder = builder;

  final Widget Function(BuildContext context)? _builder;

  final Widget Function(BuildContext context, Widget? child)? _childBuilder;

  /// Subtree passed back to the [Observer.withChild] builder without being
  /// rebuilt.
  final Widget? child;

  @override
  State<Observer> createState() => _ObserverState();
}

class _ObserverState extends State<Observer> {
  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  @override
  Widget build(BuildContext context) {
    final Widget built = _dependencies.track(() {
      final Widget Function(BuildContext context)? builder = widget._builder;

      if (builder != null) return builder(context);

      return widget._childBuilder!(context, widget.child);
    });

    assert(() {
      if (!_dependencies.hasDependencies) {
        throw FlutterError(
          'Observer built without reading any Signal or Computed, so it will '
          'never rebuild on its own. Read a reactive value inside the '
          'builder, or remove the Observer.',
        );
      }

      return true;
    }());

    return built;
  }

  void _onDependencyChanged() {
    if (!mounted) return;

    setState(() {});
  }

  @override
  void dispose() {
    _dependencies.dispose();

    super.dispose();
  }
}
