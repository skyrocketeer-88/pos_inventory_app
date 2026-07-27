import '../models/product.dart';
import '../models/transaction.dart';
import 'storage_service.dart';

class SalesPoint {
  final DateTime day;
  final double total;
  SalesPoint(this.day, this.total);
}

class FinanceReport {
  final double totalRevenue;
  final double totalCostOfGoodsSold;
  final double grossProfit;
  final double totalPurchasesCost;
  final double inventoryValue;
  final List<Product> lowStockProducts;
  final List<MapEntry<Product, double>> topSellingByRevenue;
  final List<SalesPoint> salesLast7Days;

  FinanceReport({
    required this.totalRevenue,
    required this.totalCostOfGoodsSold,
    required this.grossProfit,
    required this.totalPurchasesCost,
    required this.inventoryValue,
    required this.lowStockProducts,
    required this.topSellingByRevenue,
    required this.salesLast7Days,
  });
}

/// Pure aggregation logic over the transaction ledger + product catalog.
/// Kept separate from StorageService so it's easy to unit test.
class FinanceService {
  final StorageService storage;
  FinanceService(this.storage);

  FinanceReport buildReport() {
    final txs = storage.allTransactions;
    final products = {for (final p in storage.allProducts) p.id: p};

    double revenue = 0;
    double cogs = 0;
    double purchases = 0;
    final revenueByProduct = <String, double>{};

    for (final tx in txs) {
      final product = products[tx.productId];
      switch (tx.type) {
        case TransactionType.sale:
          revenue += tx.amount;
          revenueByProduct.update(tx.productId, (v) => v + tx.amount, ifAbsent: () => tx.amount);
          if (product != null) cogs += product.costPrice * tx.quantity;
          break;
        case TransactionType.purchase:
          purchases += tx.amount;
          break;
        case TransactionType.adjustment:
          break;
      }
    }

    final inventoryValue = products.values.fold<double>(0, (sum, p) => sum + p.inventoryValue);
    final lowStock = products.values.where((p) => p.isLowStock).toList()
      ..sort((a, b) => a.quantity.compareTo(b.quantity));

    final topSelling = revenueByProduct.entries
        .map((e) => MapEntry(products[e.key], e.value))
        .where((e) => e.key != null)
        .map((e) => MapEntry(e.key!, e.value))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();
    final salesByDay = <DateTime, double>{};
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      salesByDay[day] = 0;
    }
    for (final tx in txs.where((t) => t.type == TransactionType.sale)) {
      final day = DateTime(tx.timestamp.year, tx.timestamp.month, tx.timestamp.day);
      if (salesByDay.containsKey(day)) {
        salesByDay[day] = salesByDay[day]! + tx.amount;
      }
    }

    return FinanceReport(
      totalRevenue: revenue,
      totalCostOfGoodsSold: cogs,
      grossProfit: revenue - cogs,
      totalPurchasesCost: purchases,
      inventoryValue: inventoryValue,
      lowStockProducts: lowStock,
      topSellingByRevenue: topSelling.take(5).toList(),
      salesLast7Days: salesByDay.entries.map((e) => SalesPoint(e.key, e.value)).toList(),
    );
  }
}
