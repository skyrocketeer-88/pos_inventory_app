import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/receipt.dart';

/// Result of an OCR scan before the user confirms/edits it.
class ScanResult {
  final String rawText;
  final List<ReceiptItem> parsedItems;
  final String? guessedVendor;
  final double? guessedTotal;

  ScanResult({required this.rawText, required this.parsedItems, this.guessedVendor, this.guessedTotal});
}

/// Captures a photo of a written/printed receipt and extracts line items.
///
/// NOTE ON PLATFORM SUPPORT: google_mlkit_text_recognition wraps native
/// on-device iOS/Android OCR engines and does not run on Flutter Web. On web
/// this service returns a null scan so the UI falls back to manual entry.
/// If you need OCR on web too, swap this implementation for a cloud OCR API
/// call (e.g. Google Cloud Vision) behind the same interface.
class ReceiptScannerService {
  final ImagePicker _picker = ImagePicker();

  bool get isOcrSupportedOnThisPlatform => !kIsWeb;

  Future<ScanResult?> captureAndScan({required ImageSource source}) async {
    final photo = await _picker.pickImage(source: source, imageQuality: 85);
    if (photo == null) return null;

    if (kIsWeb) {
      // No on-device OCR on web; caller should route to manual entry.
      return null;
    }

    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(photo.path);
      final recognized = await textRecognizer.processImage(inputImage);
      return _parse(recognized.text);
    } finally {
      await textRecognizer.close();
    }
  }

  /// Heuristic parser: looks for lines shaped like "Name ... qty x price"
  /// or "Name ... $price", and tries to find a vendor name (first line) and
  /// a total (line containing "total").
  ScanResult _parse(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final items = <ReceiptItem>[];
    double? total;
    final String? vendor = lines.isNotEmpty ? lines.first : null;

    final priceRegex = RegExp(r'(\d+[.,]\d{2})');
    final qtyRegex = RegExp(r'(?:x|qty)\s?(\d+)', caseSensitive: false);

    for (final line in lines) {
      final lower = line.toLowerCase();
      final priceMatch = priceRegex.firstMatch(line);
      if (priceMatch == null) continue;

      final price = double.tryParse(priceMatch.group(1)!.replaceAll(',', '.'));
      if (price == null) continue;

      if (lower.contains('total') && !lower.contains('subtotal')) {
        total = price;
        continue;
      }
      if (lower.contains('tax') || lower.contains('subtotal') || lower.contains('change')) {
        continue;
      }

      final qtyMatch = qtyRegex.firstMatch(line);
      final qty = qtyMatch != null ? int.tryParse(qtyMatch.group(1)!) ?? 1 : 1;

      var name = line.substring(0, priceMatch.start).trim();
      name = name.replaceAll(RegExp(r'[-.]+$'), '').trim();
      if (name.isEmpty) name = 'Item';

      items.add(ReceiptItem(name: name, quantity: qty, price: price));
    }

    return ScanResult(rawText: rawText, parsedItems: items, guessedVendor: vendor, guessedTotal: total);
  }
}
