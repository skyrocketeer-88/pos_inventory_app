import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'services/storage_service.dart';
import 'services/chatbot_service.dart';
import 'services/pdf_service.dart';
import 'services/receipt_scanner_service.dart';
import 'screens/receipts/receipts_screen.dart';
import 'screens/inventory/inventory_screen.dart';
import 'screens/template/pdf_template_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/chat/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<StorageService>.value(value: storage),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        Provider(create: (_) => PdfService()),
        Provider(create: (_) => ReceiptScannerService()),
        Provider(create: (ctx) => ChatbotService(ctx.read<StorageService>())),
      ],
      child: const InventoryApp(),
    ),
  );
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp(
      title: 'Inventory & Receipts',
      debugShowCheckedModeBanner: false,
      themeMode: themeController.mode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const RootShell(),
    );
  }
}

/// Bottom-navigation shell. Tab order per product requirements:
/// Receipts -> Inventory -> PDF Template, then Reports and the offline
/// assistant as supporting tabs.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    ReceiptsScreen(),
    InventoryScreen(),
    PdfTemplateScreen(),
    ReportsScreen(),
    ChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    const destinations = [
      NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Receipts'),
      NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Inventory'),
      NavigationDestination(icon: Icon(Icons.picture_as_pdf_outlined), selectedIcon: Icon(Icons.picture_as_pdf), label: 'Template'),
      NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'Reports'),
      NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy), label: 'Assistant'),
    ];

    final themeToggle = IconButton(
      tooltip: 'Toggle theme',
      onPressed: themeController.toggle,
      icon: Icon(
        themeController.mode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
      ),
    );

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: themeToggle,
              ),
              destinations: destinations
                  .map((d) => NavigationRailDestination(icon: d.icon, selectedIcon: d.selectedIcon, label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _screens[_index]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: destinations,
      ),
    );
  }
}
