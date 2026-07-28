import 'package:flutter/material.dart';

class EventLog extends StatelessWidget {
  const EventLog({
    super.key,
    required this.entries,
    this.emptyLabel = 'Nothing logged yet',
  });

  final List<String> entries;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: entries.isEmpty
          ? Text(
              emptyLabel,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            )
          : ListView.builder(
              reverse: true,
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final String entry = entries[entries.length - 1 - index];

                return Text(
                  entry,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                );
              },
            ),
    );
  }
}
