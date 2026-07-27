import 'package:intl/intl.dart';

import '../models/transaction.dart';
import 'finance_service.dart';
import 'storage_service.dart';

/// A fully offline assistant: no network calls, no cloud LLM. It works by
/// matching the message against a set of intents (regex + keyword rules)
/// and reading/writing directly against [StorageService]. This keeps money
/// and account data on-device.
///
/// To upgrade this to a real on-device LLM later (e.g. via `flutter_gemma`
/// or `llama.cpp` bindings), keep this class's public `handle()` signature
/// and swap the matching logic for model inference — the rest of the app
/// doesn't need to change.
class ChatbotService {
  final StorageService storage;
  late final FinanceService finance;
  final _currency = NumberFormat.currency(symbol: '\$');

  ChatbotService(this.storage) {
    finance = FinanceService(storage);
  }

  Future<String> handle(String message) async {
    final text = message.trim();
    final lower = text.toLowerCase();

    if (_matchesAny(lower, ['balance', 'net worth', 'how am i doing', 'profit'])) {
      return _balanceReply();
    }

    if (_matchesAny(lower, ['low stock', 'reorder', 'running out'])) {
      return _lowStockReply();
    }

    final sale = RegExp(r'(?:sold|sell|record sale of)\s+(\d+)?\s*x?\s*([a-zA-Z0-9 \-]+?)(?:\s+at\s+\$?(\d+(?:\.\d+)?))?$').firstMatch(lower);
    if (sale != null) {
      return _recordTransactionFromMatch(sale, TransactionType.sale);
    }

    final purchase = RegExp(r'(?:bought|purchase(?:d)?|restock(?:ed)?|received)\s+(\d+)?\s*x?\s*([a-zA-Z0-9 \-]+?)(?:\s+at\s+\$?(\d+(?:\.\d+)?))?$').firstMatch(lower);
    if (purchase != null) {
      return _recordTransactionFromMatch(purchase, TransactionType.purchase);
    }

    final stockQuery = RegExp(r'(?:how many|stock of|quantity of)\s+([a-zA-Z0-9 \-]+)').firstMatch(lower);
    if (stockQuery != null) {
      final name = stockQuery.group(1)!.trim();
      final product = storage.findProductByName(name);
      if (product == null) return "I couldn't find a product matching \"$name\".";
      return '${product.name}: ${product.quantity} in stock (reorder at ${product.reorderLevel}).';
    }

    final priceQuery = RegExp(r'(?:price of|cost of|how much is)\s+([a-zA-Z0-9 \-]+)').firstMatch(lower);
    if (priceQuery != null) {
      final name = priceQuery.group(1)!.trim();
      final product = storage.findProductByName(name);
      if (product == null) return "I couldn't find a product matching \"$name\".";
      return '${product.name} is priced at ${_currency.format(product.price)}.';
    }

    if (_matchesAny(lower, ['top seller', 'best seller', 'top product'])) {
      final report = finance.buildReport();
      if (report.topSellingByRevenue.isEmpty) return "No sales recorded yet.";
      final top = report.topSellingByRevenue.first;
      return 'Your top seller is ${top.key.name}, with ${_currency.format(top.value)} in revenue.';
    }

    if (_matchesAny(lower, ['help', 'what can you do'])) {
      return _helpReply();
    }

    return "I didn't quite catch that. Try things like:\n"
        '• "sold 3 blue mugs at 12"\n'
        '• "bought 20 notebooks at 2.5"\n'
        '• "how many blue mugs"\n'
        '• "what\'s my balance"\n'
        '• "low stock"';
  }

  bool _matchesAny(String text, List<String> keywords) => keywords.any((k) => text.contains(k));

  String _balanceReply() {
    final r = finance.buildReport();
    final buf = StringBuffer();
    buf.writeln('Here\'s where things stand:');
    buf.writeln('• Revenue: ${_currency.format(r.totalRevenue)}');
    buf.writeln('• Cost of goods sold: ${_currency.format(r.totalCostOfGoodsSold)}');
    buf.writeln('• Gross profit: ${_currency.format(r.grossProfit)}');
    buf.writeln('• Spent on purchases: ${_currency.format(r.totalPurchasesCost)}');
    buf.write('• Current inventory value: ${_currency.format(r.inventoryValue)}');
    return buf.toString();
  }

  String _lowStockReply() {
    final r = finance.buildReport();
    if (r.lowStockProducts.isEmpty) return 'Nothing is low on stock right now. 🎉';
    final buf = StringBuffer('These items need restocking:\n');
    for (final p in r.lowStockProducts.take(10)) {
      buf.writeln('• ${p.name}: ${p.quantity} left (reorder at ${p.reorderLevel})');
    }
    return buf.toString().trim();
  }

  String _helpReply() {
    return 'I can help with, all offline:\n'
        '• Recording sales/purchases — "sold 2 candles at 15"\n'
        '• Checking stock — "how many candles"\n'
        '• Checking prices — "price of candles"\n'
        '• Financial summaries — "what\'s my balance"\n'
        '• Low stock alerts — "low stock"\n'
        '• Top sellers — "top seller"';
  }

  Future<String> _recordTransactionFromMatch(RegExpMatch match, TransactionType type) async {
    final qtyStr = match.group(1);
    final name = match.group(2)?.trim() ?? '';
    final priceStr = match.group(3);

    final product = storage.findProductByName(name);
    if (product == null) {
      return "I couldn't find a product called \"$name\". Add it in the Inventory tab first, then try again.";
    }

    final qty = int.tryParse(qtyStr ?? '') ?? 1;
    final overridePrice = priceStr != null ? double.tryParse(priceStr) : null;
    final overrideAmount = overridePrice != null ? overridePrice * qty : null;

    if (type == TransactionType.sale && product.quantity < qty) {
      return 'Only ${product.quantity} ${product.name} left in stock — can\'t record a sale of $qty. Want me to record ${product.quantity} instead?';
    }

    await storage.recordTransaction(
      type: type,
      product: product,
      quantity: qty,
      overrideAmount: overrideAmount,
      note: 'Recorded via chat assistant',
    );

    final verb = type == TransactionType.sale ? 'Sale' : 'Purchase';
    final amount = overrideAmount ?? (product.price * qty);
    return '$verb recorded: $qty x ${product.name} — ${_currency.format(amount)}. '
        'New stock level: ${product.quantity}.';
  }
}
