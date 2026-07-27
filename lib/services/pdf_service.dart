import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/receipt.dart';
import '../models/pdf_template.dart';

/// Builds a PDF document for a [Receipt] using the user's saved
/// [PdfTemplateConfig], and provides helpers to preview/print/share it.
class PdfService {
  Future<Uint8List> buildReceiptPdf(Receipt receipt, PdfTemplateConfig cfg) async {
    final doc = pw.Document();
    final primary = PdfColor.fromInt(cfg.primaryColorValue);
    final currency = NumberFormat.currency(symbol: cfg.currencySymbol);
    final dateFmt = DateFormat.yMMMd().add_jm();

    doc.addPage(
      pw.Page(
        pageFormat: cfg.landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(cfg, primary),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Billed to / Vendor', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(receipt.vendorOrCustomer, style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text(dateFmt.format(receipt.date), style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              _itemsTable(receipt, primary, currency),
              pw.SizedBox(height: 12),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: _totals(receipt, cfg, currency),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColors.grey300),
              pw.Center(
                child: pw.Text(cfg.footerText, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _header(PdfTemplateConfig cfg, PdfColor primary) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(cfg.businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: primary)),
            pw.SizedBox(height: 4),
            pw.Text(cfg.address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Text(cfg.phone, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          ],
        ),
        if (cfg.showLogoPlaceholder)
          pw.Container(
            width: 56,
            height: 56,
            decoration: pw.BoxDecoration(
              color: primary,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            alignment: pw.Alignment.center,
            child: pw.Text(
              cfg.businessName.isNotEmpty ? cfg.businessName[0].toUpperCase() : '?',
              style: const pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
        pw.Text(cfg.documentTitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(cfg.secondaryColorValue))),
      ],
    );
  }

  pw.Widget _itemsTable(Receipt receipt, PdfColor primary, NumberFormat currency) {
    return pw.Table(
      border: const pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey300),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primary),
          children: [
            _cell('Item', bold: true, color: PdfColors.white, padTop: 8, padBottom: 8),
            _cell('Qty', bold: true, color: PdfColors.white, align: pw.TextAlign.center, padTop: 8, padBottom: 8),
            _cell('Price', bold: true, color: PdfColors.white, align: pw.TextAlign.right, padTop: 8, padBottom: 8),
            _cell('Total', bold: true, color: PdfColors.white, align: pw.TextAlign.right, padTop: 8, padBottom: 8),
          ],
        ),
        for (final item in receipt.items)
          pw.TableRow(
            children: [
              _cell(item.name),
              _cell('${item.quantity}', align: pw.TextAlign.center),
              _cell(currency.format(item.price), align: pw.TextAlign.right),
              _cell(currency.format(item.lineTotal), align: pw.TextAlign.right),
            ],
          ),
      ],
    );
  }

  pw.Widget _cell(String text, {bool bold = false, PdfColor color = PdfColors.black, pw.TextAlign align = pw.TextAlign.left, double padTop = 6, double padBottom = 6}) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(top: padTop, bottom: padBottom, left: 4, right: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal, color: color),
      ),
    );
  }

  pw.Widget _totals(Receipt receipt, PdfTemplateConfig cfg, NumberFormat currency) {
    pw.Widget row(String label, String value, {bool bold = false}) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.SizedBox(width: 90, child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
              pw.SizedBox(width: 80, child: pw.Text(value, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal))),
            ],
          ),
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        row('Subtotal', currency.format(receipt.subtotal)),
        if (cfg.showTaxLine) row('Tax (${(receipt.taxRate * 100).toStringAsFixed(1)}%)', currency.format(receipt.tax)),
        pw.Divider(color: PdfColors.grey400),
        row('Total', currency.format(receipt.total), bold: true),
      ],
    );
  }

  Future<void> previewAndPrint(Receipt receipt, PdfTemplateConfig cfg) async {
    await Printing.layoutPdf(onLayout: (format) => buildReceiptPdf(receipt, cfg));
  }

  Future<void> share(Receipt receipt, PdfTemplateConfig cfg) async {
    final bytes = await buildReceiptPdf(receipt, cfg);
    await Printing.sharePdf(bytes: bytes, filename: 'receipt_${receipt.id}.pdf');
  }
}
