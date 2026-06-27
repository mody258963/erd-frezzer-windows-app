import 'package:erd_rezzer/data/models/capital_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CapitalSettings', () {
    test('parses profit_withdrawal block', () {
      final s = CapitalSettings.fromJson({
        'opening_cash_balance': 100000,
        'capital_amount': 100000,
        'business_capital': 150000,
        'profit_withdrawal': {
          'realized_profit': 20000,
          'total_withdrawn': 15000,
          'withdrawable_profit': 5000,
        },
        'financing_snapshot': {
          'inventory_at_cost': 100000,
          'cash_on_hand_realized': 50000,
        },
      });

      expect(s.openingCashBalance, 100000);
      expect(s.businessCapital, 150000);
      expect(s.withdrawableProfit, 5000);
      expect(s.realizedProfit, 20000);
      expect(s.totalProfitWithdrawn, 15000);
      expect(s.capitalAmount, s.openingCashBalance);
    });

    test('merges profit fields from cash-out style root response', () {
      final s = CapitalSettings.fromJson({
        'opening_cash_balance': 100000,
        'business_capital': 135000,
        'profit_withdrawal': {
          'realized_profit': 20000,
          'total_withdrawn': 20000,
          'withdrawable_profit': 0,
        },
        'financing_snapshot': {
          'cash_on_hand_realized': 35000,
          'inventory_at_cost': 100000,
        },
      });

      expect(s.openingCashBalance, 100000);
      expect(s.withdrawableProfit, 0);
      expect(s.cashOnHandRealized, 35000);
    });

    test('capital_amount aliases opening cash only', () {
      final s = CapitalSettings.fromJson({
        'capital_amount': 80000,
        'business_capital': 120000,
      });

      expect(s.openingCashBalance, 80000);
      expect(s.businessCapital, 120000);
      expect(s.capitalAmount, 80000);
      expect(s.capitalAmount, isNot(s.businessCapital));
    });
  });
}
