import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/receipt.dart';
import '../../services/receipt_scanner_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';

class ReceiptEditorScreen extends StatefulWidget {
  const ReceiptEditorScreen({super.key});

  @override
  State<ReceiptEditorScreen> createState() => _ReceiptEditorScreenState();
}

class _ReceiptEditorScreenState extends State<ReceiptEditorScreen> {
  final _vendorController = TextEditingController();
  final _taxController = TextEditingController(text: '0');
  DateTime _date = DateTime.now();
  final List<ReceiptItem> _items = [];
  String _rawOcrText = '';
  bool _scanning = false;

  @override
  void dispose() {
    _vendorController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _scan(ImageSource source) async {
    final scanner = context.read<ReceiptScannerService>();

    if (!scanner.isOcrSupportedOnThisPlatform) {
      _showSnack('OCR scanning isn\'t available on web — add items manually below, or run this app on iOS/Android to scan.');
      return;
    }

    setState(() => _scanning = true);
    try {
      final result = await scanner.captureAndScan(source: source);
      if (result == null) return;
      setState(() {
        _rawOcrText = result.rawText;
        if (result.guessedVendor != null && _vendorController.text.isEmpty) {
          _vendorController.text = result.guessedVendor!;
        }
        _items.addAll(result.parsedItems);
      });
      if (result.parsedItems.isEmpty) {
        _showSnack('Scanned, but I couldn\'t confidently detect line items — please add them manually.');
      }
    } catch (e) {
      _showSnack('Scan failed: $e');
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _addBlankItem() {
    setState(() => _items.add(ReceiptItem(name: '', quantity: 1, price: 0)));
  }

  Future<void> _save() async {
    if (_vendorController.text.trim().isEmpty || _items.isEmpty) {
      _showSnack('Add a vendor/customer name and at least one item.');
      return;
    }
    final storage = context.read<StorageService>();
    final receipt = Receipt(
      id: storage.newId(),
      vendorOrCustomer: _vendorController.text.trim(),
      date: _date,
      items: _items.where((i) => i.name.trim().isNotEmpty).toList(),
      taxRate: (double.tryParse(_taxController.text) ?? 0) / 100,
      rawOcrText: _rawOcrText,
    );
    await storage.saveReceipt(receipt);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ThemedAppBar(title: 'New Receipt'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanning ? null : () => _scan(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Scan with camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scanning ? null : () => _scan(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Upload photo'),
                ),
              ),
            ],
          ),
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'On web, scanned photos are added but text is not auto-extracted — enter items manually below.',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
              ),
            ),
          if (_scanning) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
          const SizedBox(height: 20),
          TextField(
            controller: _vendorController,
            decoration: const InputDecoration(labelText: 'Vendor / Customer name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _taxController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Tax %'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(onPressed: _addBlankItem, icon: const Icon(Icons.add), label: const Text('Add item')),
            ],
          ),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((entry) => _ItemRow(
                item: entry.value,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() => _items.removeAt(entry.key)),
              )),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ReceiptItem item;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ItemRow({required this.item, required this.onChanged, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                initialValue: item.name,
                decoration: const InputDecoration(labelText: 'Item name', isDense: true),
                onChanged: (v) {
                  item.name = v;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: item.quantity.toString(),
                decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  item.quantity = int.tryParse(v) ?? 1;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: item.price.toString(),
                decoration: const InputDecoration(labelText: 'Price', isDense: true),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) {
                  item.price = double.tryParse(v) ?? 0;
                  onChanged();
                },
              ),
            ),
            IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
          ],
        ),
      ),
    );
  }
}
