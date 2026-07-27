import 'package:hive/hive.dart';

part 'pdf_template.g.dart';

@HiveType(typeId: 5)
class PdfTemplateConfig extends HiveObject {
  @HiveField(0)
  String businessName;

  @HiveField(1)
  String address;

  @HiveField(2)
  String phone;

  @HiveField(3)
  String footerText;

  @HiveField(4)
  int primaryColorValue; // ARGB int, so it survives Hive storage

  @HiveField(5)
  bool showTaxLine;

  @HiveField(6)
  bool showLogoPlaceholder;

  @HiveField(7)
  String documentTitle; // e.g. "RECEIPT" / "INVOICE"

  @HiveField(8)
  String currencySymbol;

  @HiveField(9)
  int secondaryColorValue;

  @HiveField(10)
  bool landscape;

  PdfTemplateConfig({
    this.businessName = 'My Business',
    this.address = '123 Main Street, Your City',
    this.phone = '+1 (555) 000-0000',
    this.footerText = 'Thank you for your business!',
    this.primaryColorValue = 0xFF1B365D,
    this.showTaxLine = true,
    this.showLogoPlaceholder = true,
    this.documentTitle = 'RECEIPT',
    this.currencySymbol = '\$',
    this.secondaryColorValue = 0xFFCBA052,
    this.landscape = false,
  });
}
