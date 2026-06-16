import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/api_labels.dart';
import '../../core/l10n/l10n_extension.dart';
import '../../core/printer/printer_print_helper.dart';
import '../../core/printer/services/invoice_printer_service.dart';
import '../../core/printer/services/printer_service.dart';
import '../../data/local/app_database.dart';
import '../../data/models/invoice_model.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../di/injection.dart';
import '../../router/route_paths.dart';
import 'pos_bloc.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({
    required this.id,
    this.offline = false,
    this.amountPaid,
    this.changeDue,
    super.key,
  });

  final String id;
  final bool offline;
  final double? amountPaid;
  final double? changeDue;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  String _title = '';
  List<String> _lines = [];
  InvoicePrintData? _printData;
  bool _loading = true;
  bool _printing = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    final l10n = context.l10n;
    try {
      if (widget.offline) {
        final db = getIt<AppDatabase>();
        final inv = await (db.select(db.pendingInvoices)
              ..where((p) => p.localId.equals(widget.id)))
            .getSingle();
        final items = await db.itemsForInvoice(widget.id);
        final customerName =
            await db.getCustomerName(inv.customerId) ?? inv.customerId;
        setState(() {
          _title = l10n.receiptPending;
          _lines = [
            'Local ID: ${inv.localId}',
            '${l10n.customer}: $customerName',
            'Status: ${inv.status}',
            'Subtotal: ${inv.subtotal}',
            if (inv.discount > 0) 'Discount: -${inv.discount}',
            'Total: ${inv.total}',
            'Payment: ${inv.paymentType}',
            if (widget.amountPaid != null)
              '${l10n.amountReceived}: ${formatMoney(context, widget.amountPaid)}',
            if (widget.changeDue != null && widget.changeDue! > 0)
              '${l10n.changeDue}: ${formatMoney(context, widget.changeDue)}',
            '---',
            ...items.map(
              (i) =>
                  '${i.partCode} x${i.quantity} @ ${i.unitPrice} = ${i.lineTotal}',
            ),
          ];
          _printData = InvoicePrintData(
            invoiceNumber: inv.localId.length > 8
                ? inv.localId.substring(0, 8)
                : inv.localId,
            invoiceDate: DateTime.now().toIso8601String().split('T').first,
            items: items
                .map(
                  (i) => InvoiceItemModel(
                    partId: i.partId,
                    quantity: i.quantity,
                    unitPrice: i.unitPrice,
                    partCode: i.partCode,
                    partName: i.partName,
                    lineTotal: i.lineTotal,
                  ),
                )
                .toList(),
            subtotal: inv.subtotal,
            total: inv.total,
            discount: inv.discount,
            paymentMethod: inv.paymentType,
            customerName: customerName,
            amountPaid: widget.amountPaid,
            changeDue: widget.changeDue,
          );
          _loading = false;
        });
      } else {
        final inv = await getIt<InvoiceRepository>().get(widget.id);
        setState(() {
          _title = '${l10n.receipt} #${inv.id.substring(0, 8)}';
          _lines = [
            'Invoice: ${inv.id}',
            'Customer: ${inv.customerName ?? inv.customerId}',
            'Subtotal: ${inv.subtotal}',
            if (inv.discount > 0) 'Discount: -${inv.discount}',
            'Total: ${inv.total}',
            'Payment: ${inv.paymentType}',
            if (widget.amountPaid != null)
              '${l10n.amountReceived}: ${formatMoney(context, widget.amountPaid)}',
            if (widget.changeDue != null && widget.changeDue! > 0)
              '${l10n.changeDue}: ${formatMoney(context, widget.changeDue)}',
            '---',
            ...inv.items.map(
              (i) =>
                  '${i.partCode ?? i.partId} x${i.quantity} = ${i.lineTotal ?? ''}',
            ),
          ];
          _printData = InvoicePrintData.fromModel(inv).copyWith(
            amountPaid: widget.amountPaid,
            changeDue: widget.changeDue,
          );
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _lines = [e.toString()];
        _loading = false;
      });
    }
  }

  Future<void> _print() async {
    final data = _printData;
    if (data == null) return;
    setState(() => _printing = true);
    try {
      await printInvoiceData(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.printSuccess)),
        );
      }
    } on PrinterException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.printFailed(e.message))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.printFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title.isEmpty ? l10n.receipt : _title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/pos'),
        ),
        actions: [
          if (!_loading && _printData != null)
            IconButton(
              icon: _printing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print),
              tooltip: l10n.printReceipt,
              onPressed: _printing ? null : _print,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          if (widget.changeDue != null &&
                              widget.changeDue! > 0) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade300),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.changeDue,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    formatMoney(context, widget.changeDue),
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ..._lines.map(
                            (l) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(l),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      if (_printData != null)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _printing ? null : _print,
                            icon: const Icon(Icons.print),
                            label: Text(
                              _printing ? l10n.printing : l10n.printReceipt,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            try {
                              context
                                  .read<PosBloc>()
                                  .add(const PosAcknowledgeSale());
                            } catch (_) {}
                            context.go(RoutePaths.pos);
                          },
                          child: Text(l10n.newSale),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
