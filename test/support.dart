import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps [child] in the minimum a widget test needs to pump text.
Widget host(Widget child) {
  return Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Redirects [FlutterError.onError] into the returned list for one test.
///
/// The previous handler is restored on tear-down.
List<Object> captureFlutterErrors() {
  final List<Object> reported = <Object>[];
  final FlutterExceptionHandler? handler = FlutterError.onError;

  FlutterError.onError = (FlutterErrorDetails details) =>
      reported.add(details.exception);
  addTearDown(() => FlutterError.onError = handler);

  return reported;
}
