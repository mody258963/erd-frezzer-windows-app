import 'package:erd_rezzer/core/dashboard/dashboard_period.dart';
import 'package:erd_rezzer/data/models/dashboard_cash_model.dart';
import 'package:erd_rezzer/features/dashboard/daily_profit.dart';
import 'package:erd_rezzer/features/dashboard/dashboard_summary_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('profitFromSummary', () {
    const monthSummary = {
      'period_profit': 10904.93,
      'period_revenue': 83170.80,
      'period_net_sales': 82625.80,
      'period_gross_profit': 11492.78,
      'period_discount': 42.85,
      'period_customer_refunds': 545.00,
      'period_customer_refund_profit_impact': 545.00,
    };

    test('COGS is revenue minus gross profit, not revenue minus profit', () {
      final m = profitFromSummary(
        monthSummary,
        period: DashboardPeriod.month,
      );

      expect(m, isNotNull);
      expect(m!.reportedProfit, 10904.93);
      expect(m.costOfGoods, closeTo(83170.80 - 11492.78, 0.01));
      expect(m.cost, isNot(m.sales - m.profit));
    });

    test('margin uses net sales denominator', () {
      final m = profitFromSummary(
        monthSummary,
        period: DashboardPeriod.month,
      );
      expect(m!.marginPercent, closeTo(10904.93 / 82625.80 * 100, 0.1));
    });

    test('profit formula matches API fields', () {
      expect(summaryProfitConsistent(monthSummary), isTrue);
    });
  });

  group('DashboardCash.fromResponses', () {
    test('snapshot from summary, period flow from cash endpoint', () {
      final cash = DashboardCash.fromResponses(
        summary: {
          'cash_on_hand_realized': 21728.27,
          'must_collect_customers': 18665,
          'period_net_cash_flow_realized': -77271.73,
          'period_cash_in_realized': 75395.80,
          'period_cash_out_realized': 152667.53,
        },
        cashEndpoint: {
          'period_net_cash_flow_realized': 72380.80,
          'period_cash_in_realized': 100000,
          'period_cash_out_realized': 27619.20,
        },
      );

      expect(cash.cashOnHandRealized, 21728.27);
      expect(cash.periodNetCashFlowRealized, 72380.80);
      expect(cash.mustCollectCustomers, 18665);
    });

    test('period fields fall back to summary when cash endpoint missing', () {
      final cash = DashboardCash.fromResponses(
        summary: {
          'cash_on_hand_realized': 1000,
          'period_net_cash_flow_realized': 1190,
          'period_cash_in_realized': 2000,
          'period_cash_out_realized': 810,
        },
      );

      expect(cash.periodNetCashFlowRealized, 1190);
      expect(cash.cashFlowConsistent, isTrue);
      expect(summaryNetCashFlowConsistent({
        'period_cash_in_realized': 2000,
        'period_cash_out_realized': 810,
        'period_net_cash_flow_realized': 1190,
      }), isTrue);
    });

    test('snapshot fields prefer cash endpoint', () {
      final cash = DashboardCash.fromResponses(
        summary: {
          'cash_on_hand_realized': 1000,
          'must_collect_customers': 500,
        },
        cashEndpoint: {
          'cash_on_hand_realized': 2500,
          'must_collect_customers': 100,
          'must_pay_suppliers': 50,
          'period_cash_in_realized': 120,
          'period_cash_out_realized': 50,
          'period_net_cash_flow_realized': 70,
        },
      );

      expect(cash.cashOnHandRealized, 2500);
      expect(cash.mustCollectCustomers, 100);
      expect(cash.mustPaySuppliers, 50);
      expect(cash.cashFlowConsistent, isTrue);
    });
  });

  group('summaryPeriodNum', () {
    test('prefers period_* over weekly_*', () {
      final v = summaryPeriodNum({
        'period_profit': 100,
        'weekly_profit': 999,
      }, 'profit');
      expect(v, 100);
    });

    test('falls back to weekly_* only when period_* absent', () {
      final v = summaryPeriodNum({'weekly_profit': 50}, 'profit');
      expect(v, 50);
    });
  });
}
