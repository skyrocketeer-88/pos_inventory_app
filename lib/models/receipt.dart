import 'package:hive/hive.dart';

part 'receipt.g.dart';

@HiveType(typeId: 3)
class ReceiptItem extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int quantity;

  @HiveField(2)
  double price;

  ReceiptItem({required this.name, required this.quantity, required this.price});

  double get lineTotal => quantity * price;
}

@HiveType(typeId: 4)
class Receipt extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vendorOrCustomer;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  List<ReceiptItem> items;

  @HiveField(4)
  double taxRate; // e.g. 0.08 for 8%

  @HiveField(5)
  String rawOcrText;

  @HiveField(6)
  String notes;

  Receipt({
    required this.id,
    required this.vendorOrCustomer,
    required this.date,
    required this.items,
    this.taxRate = 0,
    this.rawOcrText = '',
    this.notes = '',
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.lineTotal);
  double get tax => subtotal * taxRate;
  double get total => subtotal + tax;
}
