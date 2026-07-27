import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_controller.dart';

class ThemedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> extraActions;

  const ThemedAppBar({super.key, required this.title, this.extraActions = const []});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: [
        ...extraActions,
        IconButton(
          tooltip: 'Toggle theme',
          onPressed: themeController.toggle,
          icon: Icon(themeController.mode == ThemeMode.dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
