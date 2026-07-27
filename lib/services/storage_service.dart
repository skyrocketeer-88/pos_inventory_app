import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'sync_service.dart';

import '../models/product.dart';
import '../models/transaction.dart';
import '../models/receipt.dart';
import '../models/pdf_template.dart';

/// Central data-access layer. Uses Hive so the exact same code path works on
/// iOS, Android, and Web (Hive persists to IndexedDB on web automatically).
class StorageService extends ChangeNotifier {
  static const _productsBox = 'products';
  static const _transactionsBox = 'transactions';
  static const _receiptsBox = 'receipts';
  static const _templateBox = 'pdf_template';

  final _uuid = const Uuid();

  late Box<Product> products;
  late Box<InventoryTransaction> transactions;
  late Box<Receipt> receipts;
  late Box<PdfTemplateConfig> template;

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(TransactionTypeAdapter());
    Hive.registerAdapter(InventoryTransactionAdapter());
    Hive.registerAdapter(ReceiptItemAdapter());
    Hive.registerAdapter(ReceiptAdapter());
    Hive.registerAdapter(PdfTemplateConfigAdapter());

    products = await Hive.openBox<Product>(_productsBox);
    transactions = await Hive.openBox<InventoryTransaction>(_transactionsBox);
    receipts = await Hive.openBox<Receipt>(_receiptsBox);
    template = await Hive.openBox<PdfTemplateConfig>(_templateBox);

    if (template.isEmpty) {
      await template.put('config', PdfTemplateConfig());
    }

    // Try to initialize optional remote sync (Firebase/Firestore) if configured.
    try {
      await SyncService.init();
      await SyncService.startSync(this);
    } catch (_) {}
  }

  // ---------- Products ----------
  List<Product> get allProducts => products.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  Future<Product> addProduct({
    required String name,
    required String sku,
    required double price,
    required int quantity,
    String category = 'General',
    int reorderLevel = 5,
    double costPrice = 0,
  }) async {
    final product = Product(
      id: _uuid.v4(),
      name: name,
      sku: sku,
      price: price,
      quantity: quantity,
      category: category,
      reorderLevel: reorderLevel,
      costPrice: costPrice,
    );
    await products.put(product.id, product);
    notifyListeners();
    return product;
  }

  Future<void> updateProduct(Product product) async {
    await product.save();
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    await products.delete(id);
    notifyListeners();
  }

  Product? findProductByName(String name) {
    final lower = name.toLowerCase().trim();
    for (final p in products.values) {
      if (p.name.toLowerCase() == lower) return p;
    }
    // fallback: partial match
    for (final p in products.values) {
      if (p.name.toLowerCase().contains(lower) || lower.contains(p.name.toLowerCase())) {
        return p;
      }
    }
    return null;
  }

  // ---------- Transactions (financial ledger) ----------
  Future<void> recordTransaction({
    required TransactionType type,
    required Product product,
    required int quantity,
    double? overrideAmount,
    String note = '',
  }) async {
    final amount = overrideAmount ?? (product.price * quantity);

    final tx = InventoryTransaction(
      id: _uuid.v4(),
      type: type,
      productId: product.id,
      productName: product.name,
      quantity: quantity,
      amount: amount,
      timestamp: DateTime.now(),
      note: note,
    );
    await transactions.put(tx.id, tx);

    // Adjust stock: sale reduces, purchase increases, adjustment sets delta directly.
    switch (type) {
      case TransactionType.sale:
        product.quantity = (product.quantity - quantity).clamp(0, 1 << 30);
        break;
      case TransactionType.purchase:
        product.quantity += quantity;
        break;
      case TransactionType.adjustment:
        product.quantity += quantity; // quantity may be negative for adjustments
        break;
    }
    await product.save();
    notifyListeners();
  }

  List<InventoryTransaction> get allTransactions =>
      transactions.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  // ---------- Receipts ----------
  Future<Receipt> saveReceipt(Receipt receipt) async {
    await receipts.put(receipt.id, receipt);
    notifyListeners();
    return receipt;
  }

  Future<void> deleteReceipt(String id) async {
    await receipts.delete(id);
    notifyListeners();
  }

  List<Receipt> get allReceipts =>
      receipts.values.toList()..sort((a, b) => b.date.compareTo(a.date));

  String newId() => _uuid.v4();

  // ---------- Template ----------
  PdfTemplateConfig get templateConfig => template.get('config')!;

  Future<void> saveTemplate(PdfTemplateConfig config) async {
    await template.put('config', config);
    notifyListeners();
  }
}
