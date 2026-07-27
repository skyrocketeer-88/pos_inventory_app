import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/receipt.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';
import '../../widgets/empty_state.dart';
import 'receipt_editor_screen.dart';
import 'receipt_detail_screen.dart';

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final receipts = storage.allReceipts;
    final currency = NumberFormat.currency(symbol: '\$');
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: const ThemedAppBar(title: 'Receipts'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReceiptEditorScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New receipt'),
      ),
      body: receipts.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No receipts yet',
              subtitle: 'Scan a written receipt or add one manually to generate a PDF.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              itemCount: receipts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final Receipt r = receipts[i];
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(r.vendorOrCustomer, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${dateFmt.format(r.date)} • ${r.items.length} item(s)'),
                    trailing: Text(currency.format(r.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReceiptDetailScreen(receiptId: r.id)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
