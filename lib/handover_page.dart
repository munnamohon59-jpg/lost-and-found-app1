import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'app_store.dart';
import 'helpers.dart';

/* =========================================================
   7. HANDOVER (owner side)
   Claimer call kore meeting fix kore → meet e PIN dekhay
   → OWNER ei page e PIN verify kore deliver kore
========================================================= */

class HandoverPage extends StatelessWidget {
  final AppStore store;
  const HandoverPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    // Sudhu oi post gular handover dekhabe JE POST korse EI user
    final myHandovers =
        store.claims.where((c) {
          if (c.status != ClaimStatus.approved &&
              c.status != ClaimStatus.delivered) {
            return false;
          }
          final post = store.getPost(c.itemId);
          return post != null && post.userId == store.currentUser.userId;
        }).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'OWNER CONTROLS',
          style: TextStyle(
            color: primaryIndigo,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const Text(
          'Verify Handover',
          style: TextStyle(
            color: darkSlate,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),

        if (myHandovers.isEmpty)
          emptyState(
            'No approved handovers ready yet.',
            Icons.handshake_outlined,
            null,
          )
        else
          ...myHandovers.map((claim) {
            final post = store.getPost(claim.itemId);
            final isDelivered = claim.status == ClaimStatus.delivered;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post?.itemName ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      statusBadge(
                        isDelivered ? 'DELIVERED' : 'OTP READY',
                        isDelivered ? emeraldGreen : amberWarning,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Claimer: ${claim.claimerName}\nContact: ${claim.claimerContact}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (!isDelivered) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: amberWarning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'The claimer will CALL you to fix a meeting.\nAt the meeting, they will show a 4-digit PIN.\nVerify that PIN below to complete handover.',
                        style: TextStyle(
                          color: darkSlate,
                          fontSize: 11,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (!isDelivered)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => showOtpInputSheet(context, store, post!),
                        icon: const Icon(Icons.dialpad_rounded, size: 18),
                        label: const Text(
                          'VERIFY PIN & DELIVER',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
