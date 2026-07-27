# Inventory & Receipts

A Flutter app for small businesses: manage inventory, scan written receipts
into PDFs, customize the PDF template, track financial reports, and talk to
a fully offline assistant. Targets **iOS, Android, and Web** from one codebase.

## Features

- **Receipts tab** — scan a written/printed receipt with the camera (mobile
  OCR via ML Kit) or enter items manually, then generate, preview, print,
  or share a PDF.
- **Inventory tab** — add/edit/delete products (name, SKU, category, price,
  cost, quantity, reorder level); record sales, purchases, or manual stock
  adjustments per product.
- **PDF Template tab** — customize business name, address, phone, accent
  color, document title, currency symbol, footer text, and toggle the tax
  line / logo placeholder, with a live PDF preview.
- **Reports tab** — revenue, gross profit, cost of goods sold, purchase
  spend, current inventory value, a 7-day sales chart, top sellers, and
  low-stock alerts.
- **Assistant tab** — a rule-based, **fully offline** chat assistant that can
  answer balance/stock/price questions and record sales or purchases by
  typing things like `"sold 3 candles at 15"`. No network calls, no data
  leaves the device.
- **Light / dark mode** — toggle from the app bar on every screen (follows
  system by default).

## Getting started

1. Install the Flutter SDK (3.22+) and make sure `flutter doctor` is clean
   for the platforms you're targeting.
2. Generate the native platform folders (not included here, since they're
   large generated boilerplate):
   ```bash
   flutter create . --project-name pos_inventory_app --platforms ios,android,web
   ```
   Run this **from inside this project folder** — it will fill in
   `ios/`, `android/`, and `web/` around the existing `lib/` and
   `pubspec.yaml` without overwriting them.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Generate the Hive model adapters (`*.g.dart` files referenced by the
   `part` directives in `lib/models/`):
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```
5. Run it:
   ```bash
   flutter run                # picks a connected device/simulator
   flutter run -d chrome      # web
   ```

## Project structure

```
lib/
  main.dart                     # app entrypoint, providers, bottom-nav shell
  theme/
    app_theme.dart              # light/dark ThemeData
    theme_controller.dart       # ThemeMode toggle (ChangeNotifier)
  models/                       # Hive data models (Product, Receipt, etc.)
  services/
    storage_service.dart        # Hive CRUD, single source of truth
    finance_service.dart        # pure aggregation for reports
    pdf_service.dart            # builds/prints/shares receipt PDFs
    receipt_scanner_service.dart# camera capture + on-device OCR parsing
    chatbot_service.dart        # offline rule-based assistant
  screens/
    receipts/                   # list, editor (scan/manual), detail+PDF
    inventory/                  # list, add/edit form, record-transaction sheet
    template/                   # PDF template editor + live preview
    reports/                    # financial dashboard
    chat/                       # assistant UI
  widgets/                      # shared app bar, empty state
```

## Platform notes

- **OCR on Web**: `google_mlkit_text_recognition` wraps native iOS/Android
  on-device OCR engines and does not run in a browser. On web, the "Scan
  with camera / Upload photo" buttons still let you attach a photo, but text
  isn't auto-extracted — the UI tells the user to enter items manually. If
  you need OCR on web too, swap `ReceiptScannerService` for a call to a
  cloud OCR API (e.g. Google Cloud Vision) behind the same method signature;
  nothing else in the app needs to change.
- **Storage**: uses [Hive](https://pub.dev/packages/hive), which persists to
  the filesystem on iOS/Android and to IndexedDB on web — same API, same
  code path, everywhere.
- **PDF/printing**: uses the `pdf` + `printing` packages, which support
  print dialogs and native share sheets on all three targets.

## About the "AI chat bot"

The assistant is **intentionally not a cloud LLM** — the request was for it
to work fully offline, including for money/balance data, so
`ChatbotService` uses a local intent-matching approach (regex + keyword
rules) against your on-device ledger. It can:

- Record sales/purchases: `"sold 3 candles at 15"`, `"bought 20 notebooks at 2.5"`
- Answer stock/price questions: `"how many candles"`, `"price of candles"`
- Summarize finances: `"what's my balance"`
- Flag low stock: `"low stock"`
- Report the top seller: `"top seller"`

If you later want genuine on-device generative AI (e.g. for open-ended
natural language rather than pattern matching), the cleanest path is to keep
`ChatbotService.handle(String message)`'s signature and swap its internals
for an on-device model runner such as
[`flutter_gemma`](https://pub.dev/packages/flutter_gemma) or a
`llama.cpp` binding — the rest of the app (chat UI, storage, finance
calculations) doesn't need to change.

## Extending

- **Multi-currency / tax rules**: extend `PdfTemplateConfig` and
  `Receipt.taxRate` handling in `pdf_service.dart`.
- **Barcode scanning for inventory**: add `mobile_scanner` and wire it into
  `product_form_screen.dart`'s SKU field.
- **Cloud sync / multi-device**: `StorageService` is the single place that
  talks to Hive — swap or wrap it with a remote backend (Firebase,
  Supabase, your own API) without touching the UI layer.
