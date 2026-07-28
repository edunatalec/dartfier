import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.label, required this.count});

  final String label;
  final ReadonlySignal<int> count;

  @override
  Widget build(BuildContext context) {
    return Observer((context) => Chip(label: Text('$label: ${count.value}')));
  }
}
