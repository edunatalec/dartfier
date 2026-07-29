import 'package:example/recipes/cart/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CartPage: shipping and coupon rules land on the total', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CartPage()));

    final Finder checkout = find.widgetWithText(FilledButton, 'Checkout');

    expect(tester.widget<FilledButton>(checkout).onPressed, isNull);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    expect(find.text('\$68.00'), findsOneWidget);
    expect(find.text('\$12.90'), findsOneWidget);
    expect(find.text('\$80.90'), findsOneWidget);
    expect(tester.widget<FilledButton>(checkout).onPressed, isNotNull);

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    expect(find.text('free'), findsOneWidget);
    expect(find.text('\$136.00'), findsNWidgets(2));

    await tester.tap(find.text('WELCOME10'));
    await tester.pump();

    expect(find.text('\$13.60'), findsOneWidget);
    expect(find.text('\$122.40'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('CartPage: switching coupons leaves subtotal cached', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CartPage()));

    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    expect(
      find.textContaining('subtotal 2 · shipping 2 · total 2'),
      findsOneWidget,
    );

    await tester.tap(find.text('WELCOME10'));
    await tester.pump();

    expect(
      find.textContaining('subtotal 2 · shipping 2 · total 3'),
      findsOneWidget,
    );

    await tester.tap(find.text('EXPIRED5'));
    await tester.pump();

    expect(
      find.textContaining('subtotal 2 · shipping 2 · total 4'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
