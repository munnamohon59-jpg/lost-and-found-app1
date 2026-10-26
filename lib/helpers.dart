import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'colors.dart';
import 'models.dart';
import 'app_store.dart';

/* =========================================================
   BOTTOM SHEETS & HELPERS (shared across pages)
========================================================= */

// Phone dialer khule — CLAIMER owner ke call korbe meeting fix korte
Future<void> callNumber(String phone) async {
  if (kIsWeb) return; // web e dialer nai — phone e kaj korbe
  try {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (_) {}
}

void showClaimSheet(BuildContext context, AppStore store, ItemPost post) {
  final nameCtrl = TextEditingController(text: store.currentUser.name);
  final emailCtrl = TextEditingController(text: store.currentUser.email);
  final phoneCtrl = TextEditingController(text: '01');
  final proofCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SUBMIT CLAIM PROOF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: darkSlate,
                  ),
                ),
                Text(
                  'Item: ${post.itemName}',
                  style: const TextStyle(
                    color: primaryIndigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Your Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'Contact Phone (01XXXXXXXXX)',
                  ).copyWith(counterText: ''),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: proofCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Proof of Ownership (Unique identifiers)',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (proofCtrl.text.trim().isEmpty) {
                        showAppMessage(
                          context,
                          'Proof of ownership required',
                          success: false,
                        );
                        return;
                      }
                      if (!isValidBdPhone(phoneCtrl.text.trim())) {
                        showAppMessage(
                          context,
                          'Valid 11-digit BD number din (01XXXXXXXXX)',
                          success: false,
                        );
                        return;
                      }
                      final error = await store.submitClaim(
                        post: post,
                        name: nameCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        contact: phoneCtrl.text.trim(),
                        proof: proofCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      if (error != null) {
                        showAppMessage(context, error, success: false);
                      } else {
                        showAppMessage(
                          context,
                          'Claim request sent to Admin!',
                          success: true,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryIndigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'SEND CLAIM TO ADMIN',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

void showOtpInputSheet(BuildContext context, AppStore store, ItemPost post) {
  final otpCtrl = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_person_rounded,
                  size: 44,
                  color: primaryIndigo,
                ),
                const SizedBox(height: 10),
                const Text(
                  'VERIFY RECEIVER PIN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: darkSlate,
                  ),
                ),
                const Text(
                  'Enter the 4-digit PIN the claimer is showing you.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 14,
                    color: primaryIndigo,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    filled: true,
                    fillColor: bgSlate,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      final res = await store.verifyOtpAndDeliver(
                        itemId: post.itemId,
                        enteredOtp: otpCtrl.text.trim(),
                      );
                      Navigator.pop(ctx);
                      showAppMessage(
                        context,
                        res.message,
                        success: res.success,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'CONFIRM HANDOVER',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

Widget statusBadge(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget emptyState(String msg, IconData icon, VoidCallback? onAction) {
  return Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        Icon(icon, size: 50, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          msg,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        if (onAction != null) ...[
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'CREATE FIRST POST',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
        ],
      ],
    ),
  );
}

// তারিখ সুন্দর করে ফরম্যাট করার ফাংশন
String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

// BD phone validation: 11 digit, 01 start, sob operator (GP/Robi/BL/TT/Airtel)
// 013-017 GP, 018 Robi, 014/019 Banglalink, 015 Teletalk, 016 Airtel
bool isValidBdPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  return RegExp(r'^01[3-9]\d{8}$').hasMatch(digits);
}

void showAppMessage(BuildContext context, String msg, {required bool success}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: success ? darkSlate : neonPink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          Icon(
            success ? Icons.check_circle : Icons.error,
            color: success ? emeraldGreen : Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

Color claimColor(ClaimStatus s) {
  switch (s) {
    case ClaimStatus.approved:
      return emeraldGreen;
    case ClaimStatus.rejected:
      return neonPink;
    case ClaimStatus.delivered:
      return primaryIndigo;
    default:
      return amberWarning;
  }
}
