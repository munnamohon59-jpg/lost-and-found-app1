import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'helpers.dart';

// Admin credentials (sudhu tomar jana)
const String kAdminEmail = 'munnamohon59@gmail.com';
const String kAdminPassword = 'Munni@20033';

/* =========================================================
   1. LOGIN + REGISTER SCREEN
========================================================= */

class LoginScreen extends StatefulWidget {
  final Future<String?> Function(String email, String password) onUserLogin;
  final Future<String?> Function(
    String name,
    String email,
    String password,
    String contact,
  )
  onRegister;
  final VoidCallback onAdminLogin;

  const LoginScreen({
    super.key,
    required this.onUserLogin,
    required this.onRegister,
    required this.onAdminLogin,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final contactController = TextEditingController();

  bool hidePassword = true;
  bool isRegisterMode = false;
  bool isBusy = false;

  /* ---------- ADMIN LOGIN DIALOG ---------- */

  void openAdminLogin() {
    final adminEmailCtrl = TextEditingController();
    final adminPassCtrl = TextEditingController();
    bool hideAdminPass = true;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogCtx) => StatefulBuilder(
            builder:
                (dialogCtx, setDialogState) => AlertDialog(
                  backgroundColor: darkSlate,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, color: neonPink),
                      SizedBox(width: 10),
                      Text(
                        'ADMIN LOGIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: adminEmailCtrl,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.emailAddress,
                        decoration: _glassInput(
                          'Admin Email',
                          Icons.email_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: adminPassCtrl,
                        obscureText: hideAdminPass,
                        style: const TextStyle(color: Colors.white),
                        decoration: _glassInput(
                          'Admin Password',
                          Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              hideAdminPass
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white54,
                            ),
                            onPressed:
                                () => setDialogState(
                                  () => hideAdminPass = !hideAdminPass,
                                ),
                          ),
                        ),
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError!,
                          style: const TextStyle(
                            color: neonPink,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final email = adminEmailCtrl.text.trim();
                        final pass = adminPassCtrl.text;
                        if (email == kAdminEmail && pass == kAdminPassword) {
                          Navigator.pop(dialogCtx);
                          widget.onAdminLogin();
                        } else {
                          setDialogState(
                            () =>
                                dialogError =
                                    'Invalid admin email or password!',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonPink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'LOGIN',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  /* ---------- USER LOGIN / REGISTER ---------- */

  Future<void> handleSubmit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showAppMessage(
        context,
        'Please enter Email and Password',
        success: false,
      );
      return;
    }

    if (isRegisterMode) {
      final name = nameController.text.trim();
      final contact = contactController.text.trim();
      if (name.isEmpty || contact.isEmpty) {
        showAppMessage(
          context,
          'Name and Contact Number required',
          success: false,
        );
        return;
      }
      if (password.length < 6) {
        showAppMessage(
          context,
          'Password must be at least 6 characters',
          success: false,
        );
        return;
      }
      if (!isValidBdPhone(contact)) {
        showAppMessage(
          context,
          'Enter a valid 11-digit BD number (01XXXXXXXXX)',
          success: false,
        );
        return;
      }
      setState(() => isBusy = true);
      final error = await widget.onRegister(name, email, password, contact);
      if (!mounted) return;
      setState(() => isBusy = false);
      if (error != null) showAppMessage(context, error, success: false);
    } else {
      setState(() => isBusy = true);
      final error = await widget.onUserLogin(email, password);
      if (!mounted) return;
      setState(() => isBusy = false);
      if (error != null) showAppMessage(context, error, success: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkSlate,
      body: Stack(
        children: [
          Positioned(
            top: -80,
            left: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryIndigo.withOpacity(0.5), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [neonPink.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [primaryIndigo, accentViolet],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryIndigo.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.travel_explore_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'LOST & FOUND',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'COMMUNITY RECOVERY PORTAL',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 36),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isRegisterMode
                                      ? 'CREATE NEW ACCOUNT'
                                      : 'WELCOME BACK',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 18),

                                if (isRegisterMode) ...[
                                  TextField(
                                    controller: nameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: _glassInput(
                                      'Full Name',
                                      Icons.person_outline,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                ],
                                TextField(
                                  controller: emailController,
                                  style: const TextStyle(color: Colors.white),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _glassInput(
                                    'Email Address',
                                    Icons.email_outlined,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: passwordController,
                                  obscureText: hidePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _glassInput(
                                    'Password',
                                    Icons.lock_outline,
                                    suffix: IconButton(
                                      icon: Icon(
                                        hidePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white54,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () => hidePassword = !hidePassword,
                                          ),
                                    ),
                                  ),
                                ),
                                if (isRegisterMode) ...[
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: contactController,
                                    style: const TextStyle(color: Colors.white),
                                    keyboardType: TextInputType.phone,
                                    maxLength: 11,
                                    decoration: _glassInput(
                                      'Contact Number (01XXXXXXXXX)',
                                      Icons.phone_outlined,
                                    ).copyWith(counterText: ''),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    onPressed: isBusy ? null : handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryIndigo,
                                      foregroundColor: Colors.white,
                                      elevation: 8,
                                      shadowColor: primaryIndigo.withOpacity(
                                        0.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child:
                                        isBusy
                                            ? const SizedBox(
                                              height: 22,
                                              width: 22,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                            : Text(
                                              isRegisterMode
                                                  ? 'CREATE ACCOUNT'
                                                  : 'LOGIN AS USER',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed:
                                      isBusy
                                          ? null
                                          : () => setState(
                                            () =>
                                                isRegisterMode =
                                                    !isRegisterMode,
                                          ),
                                  child: Text(
                                    isRegisterMode
                                        ? 'Already have an account? Login'
                                        : 'New here? Create an account',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Secret admin entry (choto link)
                                TextButton.icon(
                                  onPressed: openAdminLogin,
                                  icon: const Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: Colors.white38,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Admin Login',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _glassInput(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.white70, size: 22),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.black.withOpacity(0.25),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryIndigo, width: 2),
      ),
    );
  }
}
