/// Sharetribe money: an [amount] in minor units (cents) plus a [currency].
/// Never a float.
class Money {
  const Money({required this.amount, required this.currency});

  final int amount;
  final String currency;

  @override
  bool operator ==(Object other) =>
      other is Money && other.amount == amount && other.currency == currency;

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => 'Money($amount $currency)';
}
