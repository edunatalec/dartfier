import 'package:dartfier/dartfier.dart';
import 'package:flutter/material.dart';

import '../../widgets/widgets.dart';
import 'cart_store.dart';

String _money(double value) => '\$${value.toStringAsFixed(2)}';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _store = CartStore();

  @override
  void dispose() {
    _store.dispose();

    super.dispose();
  }

  void _onCouponChanged(Set<String> selection) {
    _store.applyCoupon(selection.first);
  }

  void _onCheckoutTap() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Charging ${_money(_store.total.peek())}'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _buildLine(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text('${item.name} — ${_money(item.price)}')),
          IconButton.filledTonal(
            onPressed: () => _store.decrement(item.name),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 32,
            child: Text('${item.quantity}', textAlign: TextAlign.center),
          ),
          IconButton.filledTonal(
            onPressed: () => _store.increment(item.name),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, ReadonlySignal<double> amount) {
    return Observer(
      (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text(_money(amount.value))],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout rules')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionTitle('Business rules as derived values'),
              const SizedBox(height: 8),
              const InfoCard(
                'Free shipping above \$100, a 10% coupon, a checkout button '
                'that only lights up with something in the cart — four rules, '
                'four Computeds, each written once. The alternative is '
                'arithmetic inside build(): the same rule copied into the '
                'summary, the button and the badge, drifting apart the day one '
                'of them changes. Each summary row below reads its own value '
                'and rebuilds alone.',
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Column(
                  children: _store.items.value.map(_buildLine).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Observer(
                (context) => Center(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: '', label: Text('No coupon')),
                      ButtonSegment(
                        value: CartStore.validCoupon,
                        label: Text(CartStore.validCoupon),
                      ),
                      ButtonSegment(value: 'EXPIRED5', label: Text('EXPIRED5')),
                    ],
                    selected: {_store.coupon.value},
                    onSelectionChanged: _onCouponChanged,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('subtotal', _store.subtotal),
              Observer(
                (context) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('shipping'),
                      Text(
                        _store.shipping.value == 0
                            ? 'free'
                            : _money(_store.shipping.value),
                      ),
                    ],
                  ),
                ),
              ),
              _buildSummaryRow('discount', _store.discount),
              const Divider(),
              Observer(
                (context) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _money(_store.total.value),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Observer(
                (context) => Center(
                  child: FilledButton(
                    onPressed: _store.canCheckout.value ? _onCheckoutTap : null,
                    child: const Text('Checkout'),
                  ),
                ),
              ),
              const Divider(height: 48),
              const SectionTitle('Cached, consistent, recomputed on demand'),
              const SizedBox(height: 8),
              const InfoCard.highlight(
                'total reads subtotal and discount, and discount reads subtotal '
                'too — a diamond. Changing a quantity notifies once, and every '
                'read after it sees consistent state: never a total built from '
                'the new discount and the old subtotal. The cache is real as '
                'well — switching coupons recomputes discount and total and '
                'leaves subtotal alone, which is exactly what the counters '
                'below show.',
              ),
              const SizedBox(height: 16),
              Observer((context) {
                final double total = _store.total.value;

                return Text(
                  'total ${_money(total)} — recomputes: '
                  'subtotal ${_store.subtotalRuns} · '
                  'shipping ${_store.shippingRuns} · '
                  'total ${_store.totalRuns}',
                  textAlign: TextAlign.center,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
