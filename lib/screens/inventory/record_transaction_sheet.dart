import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/transaction.dart';
import '../../services/storage_service.dart';

class RecordTransactionSheet extends StatefulWidget {
  final Product product;
  const RecordTransactionSheet({super.key, required this.product});

  @override
  State<RecordTransactionSheet> createState() => _RecordTransactionSheetState();
}

class _RecordTransactionSheetState extends State<RecordTransactionSheet> {
  TransactionType _type = TransactionType.sale;
  final _qtyController = TextEditingController(text: '1');
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _qtyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty == 0) return;
    if (_type != TransactionType.adjustment && qty < 0) return;

    final storage = context.read<StorageService>();
    await storage.recordTransaction(
      type: _type,
      product: widget.product,
      quantity: qty,
      note: _noteController.text.trim(),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Record activity — ${widget.product.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.sale, label: Text('Sale'), icon: Icon(Icons.point_of_sale)),
              ButtonSegment(value: TransactionType.purchase, label: Text('Purchase'), icon: Icon(Icons.local_shipping_outlined)),
              ButtonSegment(value: TransactionType.adjustment, label: Text('Adjust'), icon: Icon(Icons.tune)),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _type == TransactionType.adjustment ? 'Quantity delta (+/-)' : 'Quantity',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _submit, child: const Text('Save')),
          ),
        ],
      ),
    );
  }
}
