import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'preferences_store.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  final _store = PreferencesStore();

  @override
  void dispose() {
    _store.dispose();

    super.dispose();
  }

  void _onThemeChanged(Set<AppTheme> selection) {
    _store.theme.value = selection.first;
  }

  void _onLanguageChanged(Set<String> selection) {
    _store.language.value = selection.first;
  }

  void _onNotificationsChanged(bool enabled) {
    _store.notifications.value = enabled;
  }

  void _onRestoreDefaultsTap() {
    _store.restoreDefaults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings that persist')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Persist on change, never on open'),
              const SizedBox(height: 8),
              const InfoCard(
                'A settings screen writes to storage when a preference '
                'changes — and must not write the moment it opens, which is '
                'exactly what an Effect would do on its first run. Watch reads '
                'the three signals as one record, stays quiet on creation, and '
                'hands the callback the previous and the next value, so the '
                'store knows which field moved without keeping a shadow copy '
                'of the form.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => SegmentedButton<AppTheme>(
                  segments: const [
                    ButtonSegment(
                      value: AppTheme.system,
                      label: Text('System'),
                    ),
                    ButtonSegment(value: AppTheme.light, label: Text('Light')),
                    ButtonSegment(value: AppTheme.dark, label: Text('Dark')),
                  ],
                  selected: {_store.theme.value},
                  onSelectionChanged: _onThemeChanged,
                ),
              ),
              const SizedBox(height: 12),
              Observer(
                (context) => SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'en', label: Text('English')),
                    ButtonSegment(value: 'pt', label: Text('Português')),
                    ButtonSegment(value: 'es', label: Text('Español')),
                  ],
                  selected: {_store.language.value},
                  onSelectionChanged: _onLanguageChanged,
                ),
              ),
              Observer(
                (context) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications'),
                  value: _store.notifications.value,
                  onChanged: _onNotificationsChanged,
                ),
              ),
              const SizedBox(height: 8),
              Observer(
                (context) => EventLog(
                  entries: _store.writes.value,
                  emptyLabel: 'Nothing written yet — the screen just opened',
                ),
              ),
              const Divider(height: 48),
              const SectionTitle('One write, not three'),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'Restore defaults assigns all three preferences in the same '
                'turn. Reruns coalesce per microtask, so the callback runs '
                'once with the value from before the burst — one write to '
                'storage listing every field that moved, not three. Press it '
                'twice: the second press changes nothing, the record compares '
                'equal, and no write happens at all. No batch needed for '
                'either.',
              ),
              const SizedBox(height: 16),
              Center(
                child: FilledButton.tonal(
                  onPressed: _onRestoreDefaultsTap,
                  child: const Text('Restore defaults'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
