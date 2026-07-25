import 'package:flutter/widgets.dart';

import 'tracker.dart';

class Observer extends StatefulWidget {
  const Observer(this.builder, {super.key});

  final Widget Function(BuildContext context) builder;

  @override
  State<Observer> createState() => _ObserverState();
}

class _ObserverState extends State<Observer> {
  late final DependencyBag _dependencies = DependencyBag(_onDependencyChanged);

  @override
  Widget build(BuildContext context) {
    return _dependencies.track(() => widget.builder(context));
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
