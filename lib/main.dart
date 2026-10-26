import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'colors.dart';
import 'app_store.dart';
import 'login_screen.dart';
import 'app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LostFoundApp());
}

/* =========================================================
   APP ROOT
========================================================= */

class LostFoundApp extends StatefulWidget {
  const LostFoundApp({super.key});

  @override
  State<LostFoundApp> createState() => _LostFoundAppState();
}

class _LostFoundAppState extends State<LostFoundApp> {
  final AppStore store = AppStore();

  bool isLoggedIn = false;
  bool isAdminLogin = false;

  Future<String?> handleUserLogin(String email, String password) async {
    final error = await store.loginWithEmail(email, password);
    if (error == null && mounted) {
      setState(() {
        isLoggedIn = true;
        isAdminLogin = false;
      });
    }
    return error;
  }

  Future<String?> handleRegister(
    String name,
    String email,
    String password,
    String contact,
  ) async {
    final error = await store.registerUser(
      name: name,
      email: email,
      password: password,
      contact: contact,
    );
    if (error == null && mounted) {
      setState(() {
        isLoggedIn = true;
        isAdminLogin = false;
      });
    }
    return error;
  }

  void loginAdmin() {
    store.startAdminMode();
    setState(() {
      isLoggedIn = true;
      isAdminLogin = true;
    });
  }

  void logout() {
    store.signOut();
    setState(() {
      isLoggedIn = false;
      isAdminLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lost & Found App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: bgSlate,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryIndigo,
          primary: primaryIndigo,
          secondary: accentViolet,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 16,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primaryIndigo, width: 2),
          ),
        ),
      ),
      home:
          isLoggedIn
              ? AppShell(
                store: store,
                startIndex: isAdminLogin ? 4 : 0,
                isAdmin: isAdminLogin,
                onLogout: logout,
              )
              : LoginScreen(
                onUserLogin: handleUserLogin,
                onRegister: handleRegister,
                onAdminLogin: loginAdmin,
              ),
    );
  }
}
