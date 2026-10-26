import 'package:flutter/material.dart';
import 'colors.dart';
import 'app_store.dart';
import 'home_page.dart';
import 'post_page.dart';
import 'claims_page.dart';
import 'handover_page.dart';
import 'admin_page.dart';

/* =========================================================
   2. APP SHELL
   User = 4 tab (Home, Post, Claims, Handover)
   Admin = 5 tab (+ Admin)
========================================================= */

class AppShell extends StatefulWidget {
  final AppStore store;
  final int startIndex;
  final bool isAdmin;
  final VoidCallback onLogout;

  const AppShell({
    super.key,
    required this.store,
    required this.startIndex,
    required this.isAdmin,
    required this.onLogout,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.startIndex;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final pages = [
          HomePage(
            store: widget.store,
            onLogout: widget.onLogout,
            onOpenPost: () => setState(() => selectedIndex = 1),
          ),
          PostPage(
            store: widget.store,
            onGoHome: () => setState(() => selectedIndex = 0),
          ),
          RequestsPage(store: widget.store),
          HandoverPage(store: widget.store),
          if (widget.isAdmin)
            AdminPage(store: widget.store, onLogout: widget.onLogout),
        ];

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: IndexedStack(index: selectedIndex, children: pages),
              ),
            ),
          ),
          bottomNavigationBar: NavigationBar(
            height: 70,
            backgroundColor: Colors.white,
            elevation: 10,
            selectedIndex: selectedIndex,
            indicatorColor: primaryIndigo.withOpacity(0.15),
            onDestinationSelected: (idx) => setState(() => selectedIndex = idx),
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: primaryIndigo),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.add_box_outlined),
                selectedIcon: Icon(Icons.add_box, color: primaryIndigo),
                label: 'Post',
              ),
              const NavigationDestination(
                icon: Icon(Icons.assignment_outlined),
                selectedIcon: Icon(Icons.assignment, color: primaryIndigo),
                label: 'Claims',
              ),
              const NavigationDestination(
                icon: Icon(Icons.handshake_outlined),
                selectedIcon: Icon(Icons.handshake, color: primaryIndigo),
                label: 'Handover',
              ),
              if (widget.isAdmin)
                const NavigationDestination(
                  icon: Icon(Icons.admin_panel_settings_outlined),
                  selectedIcon: Icon(
                    Icons.admin_panel_settings,
                    color: primaryIndigo,
                  ),
                  label: 'Admin',
                ),
            ],
          ),
        );
      },
    );
  }
}
