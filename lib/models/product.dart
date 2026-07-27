import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String sku;

  @HiveField(3)
  double price;

  @HiveField(4)
  int quantity;

  @HiveField(5)
  String category;

  @HiveField(6)
  int reorderLevel;

  @HiveField(7)
  double costPrice;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.quantity,
    this.category = 'General',
    this.reorderLevel = 5,
    this.costPrice = 0,
  });

  bool get isLowStock => quantity <= reorderLevel;

  double get inventoryValue => price * quantity;

  double get margin => price - costPrice;
}
