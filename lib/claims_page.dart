import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'app_store.dart';
import 'helpers.dart';

/* =========================================================
   6. CLAIMS (my ACTIVE claims only)
   OTP expired hole automatic notun OTP ashe (20 sec er moddhe)
========================================================= */

class RequestsPage extends StatelessWidget {
  final AppStore store;
  const RequestsPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final myClaims =
        store.claims
            .where(
              (c) =>
                  c.claimerId == store.currentUser.userId &&
                  c.status != ClaimStatus.delivered,
            )
            .toList()
          ..sort((a, b) => b.requestDate.compareTo(a.requestDate));

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'MY ACTIVITY',
          style: TextStyle(
            color: primaryIndigo,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const Text(
          'Claim Requests',
          style: TextStyle(
            color: darkSlate,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),

        if (myClaims.isEmpty)
          emptyState(
            'No active claim requests yet.',
            Icons.assignment_outlined,
            null,
          )
        else
          ...myClaims.map((claim) {
            final post = store.getPost(claim.itemId);
            final otp = store.otpForClaim(claim);
            final isApproved = claim.status == ClaimStatus.approved;
            final otpExpired = store.isOtpExpired(claim);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
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
                          post?.itemName ?? 'Unknown Item',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      statusBadge(
                        claim.status.name.toUpperCase(),
                        claimColor(claim.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Proof: "${claim.proof}"',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                  if (isApproved) ...[
                    const SizedBox(height: 4),
                    Text(
                      otpExpired
                          ? '⏳ OTP expired — a new one arrives automatically...'
                          : 'OTP valid until ${formatDate(otp!.expiryTime)}',
                      style: TextStyle(
                        color: otpExpired ? Colors.grey : amberWarning,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!otpExpired) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Step 1: Call the item owner & fix a meeting place.\nStep 2: Meet & show your Digital Pass PIN.\nStep 3: Owner verifies PIN → item is yours!',
                          style: TextStyle(
                            color: darkSlate,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 14),

                  if (isApproved && otp != null && !otpExpired) ...[
                    if (post != null && post.posterContact.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () => callNumber(post.posterContact),
                          icon: const Icon(Icons.phone_rounded, size: 18),
                          label: const Text(
                            'CALL ITEM OWNER',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: emeraldGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    if (post != null && post.posterContact.isNotEmpty)
                      const SizedBox(height: 4),
                    if (post != null && post.posterContact.isNotEmpty)
                      Center(
                        child: Text(
                          'Owner: ${post.posterName} • ${post.posterContact}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (post != null && post.posterContact.isNotEmpty)
                      const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        TicketOtpScreen(otp: otp, post: post!),
                              ),
                            ),
                        icon: const Icon(Icons.qr_code_rounded, size: 18),
                        label: const Text(
                          'VIEW DIGITAL PASS & OTP',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryIndigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }
}

class TicketOtpScreen extends StatelessWidget {
  final OtpRecord otp;
  final ItemPost post;

  const TicketOtpScreen({super.key, required this.otp, required this.post});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkSlate,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryIndigo, accentViolet],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VERIFIED HANDOVER PASS',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              post.itemName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      const Text(
                        'SHOW THIS PIN TO THE ITEM OWNER AT YOUR MEETING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: bgSlate,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryIndigo.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Text(
                          otp.verificationCode,
                          style: const TextStyle(
                            color: primaryIndigo,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PASS ID',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                otp.otpId,
                                style: const TextStyle(
                                  color: darkSlate,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'VALID TILL',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                formatDate(otp.expiryTime),
                                style: const TextStyle(
                                  color: darkSlate,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
