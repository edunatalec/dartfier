import 'package:dartfier/dartfier.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  const CartItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final double price;
  final int quantity;

  double get lineTotal => price * quantity;

  CartItem withQuantity(int value) =>
      CartItem(name: name, price: price, quantity: value);

  @override
  bool operator ==(Object other) =>
      other is CartItem &&
      other.name == name &&
      other.price == price &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(name, price, quantity);
}

const _catalog = <CartItem>[
  CartItem(name: 'Mechanical keyboard', price: 68, quantity: 0),
  CartItem(name: 'USB-C hub', price: 24.5, quantity: 0),
  CartItem(name: 'Desk mat', price: 18, quantity: 0),
];

class CartStore {
  static const double freeShippingThreshold = 100;
  static const double shippingFee = 12.9;
  static const String validCoupon = 'WELCOME10';

  final _items = Signal<List<CartItem>>(_catalog, equals: listEquals);
  final _coupon = Signal('');

  int subtotalRuns = 0;
  int shippingRuns = 0;
  int totalRuns = 0;

  late final _subtotal = Computed(() {
    subtotalRuns++;

    return _items.value.fold<double>(0, (sum, item) => sum + item.lineTotal);
  });

  late final _shipping = Computed(() {
    shippingRuns++;

    final double subtotal = _subtotal.value;

    if (subtotal == 0) return 0.0;

    return subtotal >= freeShippingThreshold ? 0.0 : shippingFee;
  });

  late final _discount = Computed(
    () => _coupon.value == validCoupon ? _subtotal.value * 0.1 : 0.0,
  );

  late final _total = Computed(() {
    totalRuns++;

    return _subtotal.value - _discount.value + _shipping.value;
  });

  late final _canCheckout = Computed(
    () => _items.value.any((item) => item.quantity > 0),
  );

  ReadonlySignal<List<CartItem>> get items => _items;
  ReadonlySignal<String> get coupon => _coupon;
  ReadonlySignal<double> get subtotal => _subtotal;
  ReadonlySignal<double> get shipping => _shipping;
  ReadonlySignal<double> get discount => _discount;
  ReadonlySignal<double> get total => _total;
  ReadonlySignal<bool> get canCheckout => _canCheckout;

  void increment(String name) {
    _changeQuantity(name, 1);
  }

  void decrement(String name) {
    _changeQuantity(name, -1);
  }

  void applyCoupon(String code) {
    _coupon.value = code;
  }

  void dispose() {
    _canCheckout.dispose();
    _total.dispose();
    _discount.dispose();
    _shipping.dispose();
    _subtotal.dispose();
    _coupon.dispose();
    _items.dispose();
  }

  void _changeQuantity(String name, int delta) {
    _items.update(
      (current) => [
        for (final CartItem item in current)
          if (item.name == name)
            item.withQuantity((item.quantity + delta).clamp(0, 99))
          else
            item,
      ],
    );
  }
}
