import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'dart:io' as io;

import '../../models/pdf_template.dart';
import '../../models/receipt.dart';
import '../../services/pdf_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/themed_app_bar.dart';

const List<Color> _swatches = [
  Color(0xFF2563EB), // blue
  Color(0xFF16A34A), // green
  Color(0xFFDC2626), // red
  Color(0xFF9333EA), // purple
  Color(0xFFEA580C), // orange
  Color(0xFF0F172A), // near-black
];

class PdfTemplateScreen extends StatefulWidget {
  const PdfTemplateScreen({super.key});

  @override
  State<PdfTemplateScreen> createState() => _PdfTemplateScreenState();
}

class _PdfTemplateScreenState extends State<PdfTemplateScreen> {
  late PdfTemplateConfig _draft;
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _footer;
  late final TextEditingController _docTitle;
  late final TextEditingController _currency;
  Uint8List? _uploadedTemplateBytes;

  @override
  void initState() {
    super.initState();
    final saved = context.read<StorageService>().templateConfig;
    _draft = PdfTemplateConfig(
      businessName: saved.businessName,
      address: saved.address,
      phone: saved.phone,
      footerText: saved.footerText,
      primaryColorValue: saved.primaryColorValue,
      showTaxLine: saved.showTaxLine,
      showLogoPlaceholder: saved.showLogoPlaceholder,
      documentTitle: saved.documentTitle,
      currencySymbol: saved.currencySymbol,
    );
    _name = TextEditingController(text: _draft.businessName);
    _address = TextEditingController(text: _draft.address);
    _phone = TextEditingController(text: _draft.phone);
    _footer = TextEditingController(text: _draft.footerText);
    _docTitle = TextEditingController(text: _draft.documentTitle);
    _currency = TextEditingController(text: _draft.currencySymbol);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    _footer.dispose();
    _docTitle.dispose();
    _currency.dispose();
    super.dispose();
  }

  void _sync() {
    _draft.businessName = _name.text;
    _draft.address = _address.text;
    _draft.phone = _phone.text;
    _draft.footerText = _footer.text;
    _draft.documentTitle = _docTitle.text.isEmpty ? 'RECEIPT' : _docTitle.text;
    _draft.currencySymbol = _currency.text.isEmpty ? '\$' : _currency.text;
    setState(() {});
  }

  Future<void> _save() async {
    _sync();
    await context.read<StorageService>().saveTemplate(_draft);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template saved')));
  }

  Future<void> _pickTemplate() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.isEmpty) return;
    Uint8List? bytes = result.files.first.bytes;
    final path = result.files.first.path;
    if (bytes == null && path != null) {
      try {
        bytes = await io.File(path).readAsBytes();
      } catch (_) {}
    }
    if (bytes == null) return;
    setState(() {
      _uploadedTemplateBytes = bytes;
      _draft.landscape = true;
    });
  }

  Receipt _sampleReceipt() => Receipt(
        id: 'preview',
        vendorOrCustomer: 'Jane Doe',
        date: DateTime.now(),
        items: [
          ReceiptItem(name: 'Sample Product A', quantity: 2, price: 12.5),
          ReceiptItem(name: 'Sample Product B', quantity: 1, price: 34.0),
        ],
        taxRate: 0.08,
      );

  @override
  Widget build(BuildContext context) {
    final pdfService = context.read<PdfService>();
    final wide = MediaQuery.sizeOf(context).width >= 800;

    final form = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Business name'), onChanged: (_) => _sync()),
        const SizedBox(height: 12),
        TextField(controller: _address, decoration: const InputDecoration(labelText: 'Address'), onChanged: (_) => _sync()),
        const SizedBox(height: 12),
        TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone'), onChanged: (_) => _sync()),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(controller: _docTitle, decoration: const InputDecoration(labelText: 'Document title'), onChanged: (_) => _sync()),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 90,
              child: TextField(controller: _currency, decoration: const InputDecoration(labelText: 'Currency'), onChanged: (_) => _sync()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(controller: _footer, decoration: const InputDecoration(labelText: 'Footer message'), onChanged: (_) => _sync()),
        const SizedBox(height: 20),
        Text('Accent color', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: _swatches.map((c) {
            final selected = _draft.primaryColorValue == c.toARGB32();
            return GestureDetector(
              onTap: () => setState(() => _draft.primaryColorValue = c.toARGB32()),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show tax line'),
          value: _draft.showTaxLine,
          onChanged: (v) => setState(() => _draft.showTaxLine = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Show logo placeholder'),
          value: _draft.showLogoPlaceholder,
          onChanged: (v) => setState(() => _draft.showLogoPlaceholder = v),
        ),
        const SizedBox(height: 20),
        Row(children: [
          FilledButton.icon(onPressed: _save, icon: const Icon(Icons.save_outlined), label: const Text('Save template')),
          const SizedBox(width: 12),
          FilledButton.icon(onPressed: _pickTemplate, icon: const Icon(Icons.upload_file), label: const Text('Upload PDF template')),
        ]),
      ],
    );

    final previewPanel = Padding(
      padding: const EdgeInsets.all(16),
          child: Card(
        clipBehavior: Clip.antiAlias,
        child: PdfPreview(
          key: ValueKey('${_draft.businessName}-${_draft.primaryColorValue}-${_draft.showTaxLine}-${_draft.showLogoPlaceholder}-${_draft.documentTitle}-${_draft.currencySymbol}-${_draft.footerText}-${_draft.address}-${_draft.phone}-${_uploadedTemplateBytes?.lengthInBytes ?? 0}'),
          build: (format) async {
            if (_uploadedTemplateBytes != null) return _uploadedTemplateBytes!;
            return pdfService.buildReceiptPdf(_sampleReceipt(), _draft);
          },
          canChangePageFormat: false,
          canChangeOrientation: false,
          allowPrinting: false,
          allowSharing: false,
          useActions: false,
        ),
      ),
    );

    if (!wide) {
      return Scaffold(
        appBar: const ThemedAppBar(title: 'PDF Template'),
        body: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(tabs: [Tab(text: 'Edit'), Tab(text: 'Preview')]),
              Expanded(child: TabBarView(children: [form, previewPanel])),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const ThemedAppBar(title: 'PDF Template'),
      body: Row(
        children: [
          SizedBox(width: 420, child: form),
          const VerticalDivider(width: 1),
          Expanded(child: previewPanel),
        ],
      ),
    );
  }
}

