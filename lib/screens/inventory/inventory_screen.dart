import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';
import '../../widgets/empty_state.dart';
import 'product_form_screen.dart';
import 'record_transaction_sheet.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final currency = NumberFormat.currency(symbol: '\$');

    var products = storage.allProducts;
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      products = products.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q) || p.category.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      appBar: const ThemedAppBar(title: 'Inventory'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProductFormScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search products, SKU, or category',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No products found',
                    subtitle: 'Add your first product to start tracking stock and pricing.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final Product p = products[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.sku} • ${p.category} • Qty: ${p.quantity}${p.isLowStock ? ' ⚠ Low stock' : ''}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(currency.format(p.price), style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProductFormScreen(existing: p)));
                                  } else if (value == 'record') {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder: (_) => RecordTransactionSheet(product: p),
                                    );
                                  } else if (value == 'delete') {
                                    storage.deleteProduct(p.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'record', child: Text('Record sale / purchase')),
                                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
