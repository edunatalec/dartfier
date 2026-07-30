import 'dart:async';

import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../widgets/widgets.dart';

class StreamSignalPage extends StatefulWidget {
  const StreamSignalPage({super.key});

  @override
  State<StreamSignalPage> createState() => _StreamSignalPageState();
}

class _StreamSignalPageState extends State<StreamSignalPage> {
  final _controller = StreamController<int>();
  late final _readings = StreamSignal<int>(_controller.stream);

  final _notifications = Signal(0);
  final _closed = Signal(false);
  final _eventLog = Signal(const <String>[]);

  int _next = 1;

  @override
  void initState() {
    super.initState();

    _readings.addListener(_onReadingChanged);
  }

  @override
  void dispose() {
    _eventLog.dispose();
    _closed.dispose();
    _notifications.dispose();
    _readings.dispose();
    unawaited(_controller.close());

    super.dispose();
  }

  void _onReadingChanged() {
    _notifications.update((int current) => current + 1);
  }

  void _log(String entry) {
    _eventLog.value = [..._eventLog.peek(), entry];
  }

  void _onEmitTap() {
    final int value = _next++;

    _controller.add(value);
    _log('add($value)');
  }

  void _onEmitSameTap() {
    final int? value = _readings.peek().valueOrNull;

    if (value == null) return;

    _controller.add(value);
    _log('add($value) — same value, no notification');
  }

  void _onEmitErrorTap() {
    _controller.addError(StateError('sensor offline'));
    _log('addError(sensor offline)');
  }

  void _onCloseTap() {
    unawaited(_controller.close());
    _closed.value = true;
    _log('close() — last state stays');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('StreamSignal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('A Stream as a reactive value'),
            const SizedBox(height: 8),
            const InfoCard(
              'StreamSignal<T> subscribes on creation, so it starts '
              'AsyncLoading and moves to AsyncData on the first event. An '
              'error becomes AsyncError carrying the data from before it, and '
              'the subscription stays open — a later event publishes data '
              'again. Closing the stream leaves the last state in place.',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Observer(
                (context) => switch (_readings.value) {
                  AsyncLoading() => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text('Nothing emitted yet'),
                      ],
                    ),
                  ),
                  AsyncData(:final value) => Center(
                    child: Text(
                      'reading: $value',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  AsyncError(:final error, :final previous?) => Center(
                    child: Text(
                      'failed: $error\nlast reading: $previous',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  AsyncError(:final error) => Center(
                    child: Text('failed: $error', textAlign: TextAlign.center),
                  ),
                  AsyncIdle() => const SizedBox.shrink(),
                },
              ),
            ),
            const SizedBox(height: 8),
            Observer(
              (context) => Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed: _closed.value ? null : _onEmitTap,
                    child: const Text('Emit next'),
                  ),
                  FilledButton.tonal(
                    onPressed: _closed.value ? null : _onEmitSameTap,
                    child: const Text('Emit same value'),
                  ),
                  FilledButton.tonal(
                    onPressed: _closed.value ? null : _onEmitErrorTap,
                    child: const Text('Emit error'),
                  ),
                  FilledButton.tonal(
                    onPressed: _closed.value ? null : _onCloseTap,
                    child: const Text('Close stream'),
                  ),
                ],
              ),
            ),
            const Divider(height: 48),
            const SectionTitle('State, not events'),
            const SizedBox(height: 8),
            const InfoCard(
              'The equality guard of Signal still applies: a stream '
              'republishing a value it already emitted notifies nobody. Tap '
              'Emit same value and watch the counter stay put. That makes '
              'StreamSignal a fit for state arriving over time — a location, '
              'a connectivity status, a document — and a poor one for a '
              'sequence of events, where two identical payloads are two '
              'distinct facts. Keep those on the Stream.',
            ),
            const SizedBox(height: 16),
            Center(
              child: CountBadge(label: 'notifications', count: _notifications),
            ),
            const SizedBox(height: 16),
            Observer((context) => EventLog(entries: _eventLog.value)),
          ],
        ),
      ),
    );
  }
}
