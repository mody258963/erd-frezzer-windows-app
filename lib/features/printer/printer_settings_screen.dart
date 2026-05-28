import 'package:flutter/material.dart';

import '../../core/l10n/l10n_extension.dart';
import '../../core/printer/models/printer_device.dart';
import '../../core/printer/models/printer_settings.dart';
import '../../core/printer/services/invoice_printer_service.dart';
import '../../core/printer/services/printer_manager.dart';
import '../../core/printer/services/printer_service.dart';
import '../../di/injection.dart';
import '../shared/page_scaffold.dart';
import '../shared/status_chip.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _company = TextEditingController();
  final _footer = TextEditingController();
  final _phone = TextEditingController();

  List<PrinterDevice> _devices = [];
  PrinterSettings _settings = const PrinterSettings();
  String? _selectedId;
  int _paperWidth = 58;
  bool _loading = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _settings = getIt<PrinterManager>().settings;
    _selectedId = _settings.selectedPrinterId;
    _paperWidth = _settings.paperWidthMm;
    _company.text = _settings.companyName;
    _footer.text = _settings.footer;
    _phone.text = _settings.phone;
    _refresh();
  }

  @override
  void dispose() {
    _company.dispose();
    _footer.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devices = await getIt<PrinterManager>().discoverPrinters();
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final settings = PrinterSettings(
      selectedPrinterId: _selectedId,
      paperWidthMm: _paperWidth,
      companyName: _company.text.trim(),
      footer: _footer.text.trim(),
      phone: _phone.text.trim(),
    );
    await getIt<PrinterManager>().saveSettings(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.printerSettingsSaved)),
      );
    }
  }

  PrinterDevice? get _selected =>
      _devices.where((d) => d.printerId == _selectedId).firstOrNull;

  Future<void> _connect() async {
    final device = _selected;
    if (device == null) return;
    setState(() => _busy = true);
    try {
      await getIt<PrinterManager>().selectAndConnect(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.printerConnected)),
        );
      }
    } on PrinterException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.printFailed(e.message))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    try {
      await getIt<PrinterManager>().disconnectPrinter();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.printerDisconnected)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testPrint() async {
    setState(() => _busy = true);
    try {
      await _save();
      await getIt<InvoicePrinterService>().printTestPage();
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
          SnackBar(content: Text(context.l10n.printFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connected = getIt<PrinterService>().connectedPrinter;

    return PageScaffold(
      title: l10n.printerSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.printerRefresh),
              ),
              const SizedBox(width: 12),
              if (connected != null)
                StatusChip(
                  label: l10n.printerConnected,
                  variant: StatusChipVariant.success,
                ),
              const Spacer(),
              OutlinedButton(
                onPressed: _busy || _selected == null ? null : _connect,
                child: Text(l10n.printerConnect),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _busy ? null : _disconnect,
                child: Text(l10n.printerDisconnect),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
          else if (_devices.isEmpty)
            Text(l10n.noPrintersFound)
          else
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final d = _devices[i];
                  return RadioListTile<String>(
                    title: Text(d.printerName),
                    subtitle: Text(
                      '${d.connectionType.value} · ${d.deviceAddress ?? ''}',
                    ),
                    value: d.printerId,
                    groupValue: _selectedId,
                    onChanged: (v) => setState(() => _selectedId = v),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Text(l10n.paperWidth, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              ButtonSegment(value: 58, label: Text(l10n.paperWidth58)),
              ButtonSegment(value: 80, label: Text(l10n.paperWidth80)),
            ],
            selected: {_paperWidth},
            onSelectionChanged: (s) => setState(() => _paperWidth = s.first),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _company,
            decoration: InputDecoration(labelText: l10n.companyName),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _footer,
            decoration: InputDecoration(labelText: l10n.footerText),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phone,
            decoration: InputDecoration(labelText: l10n.phoneNumber),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _busy ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(l10n.savePrinterSettings),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _busy ? null : _testPrint,
                icon: const Icon(Icons.print),
                label: Text(l10n.printTestPage),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
