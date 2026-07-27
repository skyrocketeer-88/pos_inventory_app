import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/pdf_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final String receiptId;
  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final receipt = storage.receipts.get(receiptId);
    final pdfService = context.read<PdfService>();
    final currency = NumberFormat.currency(symbol: '\$');

    if (receipt == null) {
      return const Scaffold(
        appBar: ThemedAppBar(title: 'Receipt'),
        body: Center(child: Text('This receipt was deleted.')),
      );
    }

    return Scaffold(
      appBar: ThemedAppBar(
        title: receipt.vendorOrCustomer,
        extraActions: [
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await storage.deleteReceipt(receipt.id);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(DateFormat.yMMMMd().add_jm().format(receipt.date), style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: receipt.items
                    .map((item) => ListTile(
                          title: Text(item.name),
                          subtitle: Text('${item.quantity} x ${currency.format(item.price)}'),
                          trailing: Text(currency.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _totalRow('Subtotal', currency.format(receipt.subtotal)),
                  _totalRow('Tax', currency.format(receipt.tax)),
                  const Divider(),
                  _totalRow('Total', currency.format(receipt.total), bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => pdfService.previewAndPrint(receipt, storage.templateConfig),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Preview / Print PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pdfService.share(receipt, storage.templateConfig),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share PDF'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
