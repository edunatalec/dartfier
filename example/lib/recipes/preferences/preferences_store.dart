import 'package:dartfier/dartfier.dart';

enum AppTheme { system, light, dark }

typedef Preferences = (AppTheme theme, String language, bool notifications);

class PreferencesStore {
  PreferencesStore() {
    _watcher = Watch(
      () => (theme.value, language.value, notifications.value),
      _onPreferencesChanged,
    );
  }

  final theme = Signal(AppTheme.system);
  final language = Signal('en');
  final notifications = Signal(true);

  final writes = Signal(const <String>[]);

  late final Watch<Preferences> _watcher;

  void restoreDefaults() {
    theme.value = AppTheme.system;
    language.value = 'en';
    notifications.value = true;
  }

  void dispose() {
    _watcher.dispose();
    writes.dispose();
    notifications.dispose();
    language.dispose();
    theme.dispose();
  }

  void _onPreferencesChanged(Preferences previous, Preferences next) {
    final List<String> changed = <String>[
      if (previous.$1 != next.$1) 'theme=${next.$1.name}',
      if (previous.$2 != next.$2) 'language=${next.$2}',
      if (previous.$3 != next.$3) 'notifications=${next.$3}',
    ];

    writes.value = [...writes.peek(), 'wrote ${changed.join(' ')}'];
  }
}
