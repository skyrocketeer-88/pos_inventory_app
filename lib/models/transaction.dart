import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 1)
enum TransactionType {
  @HiveField(0)
  sale,
  @HiveField(1)
  purchase,
  @HiveField(2)
  adjustment,
}

@HiveType(typeId: 2)
class InventoryTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  TransactionType type;

  @HiveField(2)
  String productId;

  @HiveField(3)
  String productName;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  double amount;

  @HiveField(6)
  DateTime timestamp;

  @HiveField(7)
  String note;

  InventoryTransaction({
    required this.id,
    required this.type,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.amount,
    required this.timestamp,
    this.note = '',
  });
}
