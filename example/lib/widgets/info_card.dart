import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  const InfoCard(this.text, {super.key}) : _highlight = false;

  const InfoCard.highlight(this.text, {super.key}) : _highlight = true;

  final String text;

  final bool _highlight;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _highlight
            ? colorScheme.tertiaryContainer
            : colorScheme.surfaceContainerHighest,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _highlight
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
    );
  }
}
