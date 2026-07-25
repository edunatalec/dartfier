import 'package:flutter/widgets.dart';

import 'tracker.dart';

class Observer extends StatefulWidget {
  const Observer(
    Widget Function(BuildContext context) this.builder, {
    super.key,
  }) : childBuilder = null,
       child = null;

  const Observer.withChild({
    required Widget Function(BuildContext context, Widget? child)
    this.childBuilder,
    super.key,
    this.child,
  }) : builder = null;

  final Widget Function(BuildContext context)? builder;

  final Widget Function(BuildContext context, Widget? child)? childBuilder;

  final Widget? child;

  @override
  State<Observer> createState() => _ObserverState();
}

class _ObserverState extends State<Observer> {
  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  @override
  Widget build(BuildContext context) {
    final Widget built = _dependencies.track(() {
      final Widget Function(BuildContext context)? builder = widget.builder;

      if (builder != null) return builder(context);

      return widget.childBuilder!(context, widget.child);
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
