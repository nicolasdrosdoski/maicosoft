import 'package:flutter/material.dart';
import 'package:maicosoft/widgets/sidebar_widget.dart';

class DashboardShell extends StatelessWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar:
          isWide
              ? null
              : AppBar(
                title: const Text('MaicoSoft'),
                backgroundColor: Theme.of(context).colorScheme.secondary,
                iconTheme: const IconThemeData(color: Colors.white),
                titleTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
      drawer: isWide ? null : const Drawer(child: Sidebar()),
      body: Row(
        children: [if (isWide) const Sidebar(), Expanded(child: child)],
      ),
    );
  }
}
