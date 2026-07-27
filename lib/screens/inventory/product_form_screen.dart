import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? existing;
  const ProductFormScreen({super.key, this.existing});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _quantity;
  late final TextEditingController _category;
  late final TextEditingController _reorder;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _sku = TextEditingController(text: p?.sku ?? '');
    _price = TextEditingController(text: p?.price.toString() ?? '');
    _cost = TextEditingController(text: p?.costPrice.toString() ?? '0');
    _quantity = TextEditingController(text: p?.quantity.toString() ?? '0');
    _category = TextEditingController(text: p?.category ?? 'General');
    _reorder = TextEditingController(text: p?.reorderLevel.toString() ?? '5');
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _cost.dispose();
    _quantity.dispose();
    _category.dispose();
    _reorder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final storage = context.read<StorageService>();

    if (_isEditing) {
      final p = widget.existing!;
      p
        ..name = _name.text.trim()
        ..sku = _sku.text.trim()
        ..price = double.parse(_price.text)
        ..costPrice = double.tryParse(_cost.text) ?? 0
        ..quantity = int.parse(_quantity.text)
        ..category = _category.text.trim()
        ..reorderLevel = int.parse(_reorder.text);
      await storage.updateProduct(p);
    } else {
      await storage.addProduct(
        name: _name.text.trim(),
        sku: _sku.text.trim(),
        price: double.parse(_price.text),
        quantity: int.parse(_quantity.text),
        category: _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
        reorderLevel: int.parse(_reorder.text),
        costPrice: double.tryParse(_cost.text) ?? 0,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThemedAppBar(title: _isEditing ? 'Edit Product' : 'Add Product'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.check),
        label: const Text('Save'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Product name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sku,
              decoration: const InputDecoration(labelText: 'SKU / code'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Sell price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => double.tryParse(v ?? '') == null ? 'Enter a number' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cost,
                    decoration: const InputDecoration(labelText: 'Cost price'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    decoration: const InputDecoration(labelText: 'Quantity in stock'),
                    keyboardType: TextInputType.number,
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a whole number' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _reorder,
                    decoration: const InputDecoration(labelText: 'Reorder level'),
                    keyboardType: TextInputType.number,
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
