import 'tracker.dart';

T untracked<T>(T Function() run) => Tracker.untracked(run);
