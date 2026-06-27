bool isCashPaymentType(String? paymentType) {
  final p = (paymentType ?? '').trim().toLowerCase();
  if (p.isEmpty) return false;
  return p == 'cash' || p == 'نقدي' || p == 'نقدى';
}

bool isCreditPaymentType(String? paymentType) {
  final p = (paymentType ?? '').trim().toLowerCase();
  if (p.isEmpty) return false;
  return p == 'credit' || p == 'آجل' || p == 'اجل';
}
