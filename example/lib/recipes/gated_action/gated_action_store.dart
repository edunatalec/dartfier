import 'package:dartfier/dartfier.dart';

class Profile {
  const Profile({required this.name, required this.handle});

  final String name;
  final String handle;

  @override
  bool operator ==(Object other) =>
      other is Profile && other.name == name && other.handle == handle;

  @override
  int get hashCode => Object.hash(name, handle);
}

class GatedActionStore {
  static const Duration latency = Duration(milliseconds: 1200);

  final _profile = AsyncSignal<Profile>();

  ReadonlySignal<AsyncValue<Profile>> get profile => _profile;

  Future<void> load() => _profile.run(_fetch);

  Future<void> loadFromBrokenBackend() => _profile.run(_fetchFailing);

  void dispose() {
    _profile.dispose();
  }

  Future<Profile> _fetch() async {
    await Future<void>.delayed(latency);

    return const Profile(name: 'Ana Ribeiro', handle: '@ana');
  }

  Future<Profile> _fetchFailing() async {
    await Future<void>.delayed(latency);

    throw StateError('profile service unreachable');
  }
}
