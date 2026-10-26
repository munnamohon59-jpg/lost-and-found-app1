import 'dart:convert';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'app_store.dart';
import 'helpers.dart';

/* =========================================================
   ADMIN CONSOLE (5th tab — admin only)
   1. ID verify  2. Post review  3. Claim review
========================================================= */

class AdminPage extends StatelessWidget {
  final AppStore store;
  final VoidCallback onLogout;

  const AdminPage({super.key, required this.store, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final pendingUsers = store.pendingIdentityUsers;
    final pendingPosts =
        store.posts
            .where((p) => p.reviewStatus == PostReviewStatus.pending)
            .toList();
    final pendingClaims =
        store.claims.where((c) => c.status == ClaimStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [darkSlate, Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.admin_panel_settings_rounded,
                color: neonPink,
                size: 40,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN CONSOLE',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'View → Approve / Reject',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              statusBadge('ADMIN', emeraldGreen),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Logout',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ============ 1. IDENTITY VERIFICATIONS ============
        _adminSectionTitle(
          '1. IDENTITY VERIFICATIONS (${pendingUsers.length})',
        ),
        if (pendingUsers.isEmpty)
          _emptyMini('No pending ID documents.')
        else
          ...pendingUsers.map(
            (u) => Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                    children: [
                      Expanded(
                        child: Text(
                          (u['name'] ?? 'User').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _viewBtn('VIEW ID', () => _showIdReviewSheet(context, u)),
                    ],
                  ),
                  Text(
                    'Email: ${u['email']}',
                    style: const TextStyle(color: primaryIndigo, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          'REJECT',
                          Colors.red,
                          () => store.rejectIdentityFor(
                            (u['uid'] ?? '').toString(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          'APPROVE',
                          emeraldGreen,
                          () => store.approveIdentityFor(
                            (u['uid'] ?? '').toString(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),

        // ============ 2. PENDING ITEM POSTS ============
        _adminSectionTitle('2. PENDING ITEM POSTS (${pendingPosts.length})'),
        if (pendingPosts.isEmpty)
          _emptyMini('No pending item posts.')
        else
          ...pendingPosts.map(
            (post) => Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                    children: [
                      Expanded(
                        child: Text(
                          post.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _viewBtn(
                        'VIEW POST',
                        () => _showPostReviewSheet(context, post),
                      ),
                    ],
                  ),
                  Text(
                    '${post.itemStatus} • ${post.category} • ${post.location}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    'Posted by: ${post.posterName} • ${formatDate(post.date)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          'REJECT',
                          Colors.red,
                          () => store.rejectPost(post),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          'APPROVE POST',
                          primaryIndigo,
                          () => store.approvePost(post),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),

        // ============ 3. CLAIM REQUESTS ============
        _adminSectionTitle('3. CLAIM REQUESTS (${pendingClaims.length})'),
        if (pendingClaims.isEmpty)
          _emptyMini('No pending claim requests.')
        else
          ...pendingClaims.map((claim) {
            final post = store.getPost(claim.itemId);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                    children: [
                      Expanded(
                        child: Text(
                          'Claim: ${post?.itemName ?? 'Unknown'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      _viewBtn(
                        'VIEW CLAIM',
                        () => _showClaimReviewSheet(context, claim, post),
                      ),
                    ],
                  ),
                  Text(
                    'Claimer: ${claim.claimerName} • ${claim.claimerContact}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn(
                          'REJECT',
                          Colors.red,
                          () => store.rejectClaim(claim),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionBtn(
                          'APPROVE + OTP',
                          emeraldGreen,
                          () async {
                            final res = await store.approveClaim(claim);
                            if (!context.mounted) return;
                            showAppMessage(
                              context,
                              res.message,
                              success: res.success,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  /* ================= VIEW SHEETS ================= */

  void _showIdReviewSheet(BuildContext context, Map<String, dynamic> u) {
    final photoB64 = (u['documentPhotoBase64'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
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
                  'ID CARD VERIFICATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: darkSlate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${u['name']} • ${u['email']}',
                  style: const TextStyle(
                    color: primaryIndigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 320,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: bgSlate,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child:
                      photoB64.isNotEmpty
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.memory(
                              base64Decode(photoB64),
                              fit: BoxFit.contain,
                              errorBuilder:
                                  (_, __, ___) => const Center(
                                    child: Text(
                                      'Photo load kora jay nai',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                            ),
                          )
                          : const Center(
                            child: Text(
                              'No photo attached',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          store.rejectIdentityFor((u['uid'] ?? '').toString());
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'REJECT',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          store.approveIdentityFor((u['uid'] ?? '').toString());
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'APPROVE',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  void _showPostReviewSheet(BuildContext context, ItemPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => DraggableScrollableSheet(
            initialChildSize: 0.85,
            maxChildSize: 0.95,
            minChildSize: 0.5,
            builder:
                (ctx, scrollCtrl) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text(
                        'REVIEW ITEM POST',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: darkSlate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${post.itemStatus} • ${post.category}',
                        style: const TextStyle(
                          color: primaryIndigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: bgSlate,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child:
                            post.imageBytes != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    post.imageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : const Center(
                                  child: Text(
                                    'No photo',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),

                      _reviewRow('Item Name', post.itemName),
                      _reviewRow('Status', post.itemStatus),
                      _reviewRow('Category', post.category),
                      _reviewRow('Location', post.location),
                      _reviewRow('Date', formatDate(post.date)),
                      _reviewRow('Posted by', post.posterName),
                      if (post.posterContact.isNotEmpty)
                        _reviewRow('Contact', post.posterContact),
                      if (post.description.isNotEmpty)
                        _reviewRow('Description', post.description),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                store.rejectPost(post);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'REJECT',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                store.approvePost(post);
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryIndigo,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'APPROVE POST',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  void _showClaimReviewSheet(
    BuildContext context,
    ClaimRequest claim,
    ItemPost? post,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Container(
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
                  'REVIEW CLAIM REQUEST',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: darkSlate,
                  ),
                ),
                const SizedBox(height: 16),
                if (post != null)
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: bgSlate,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child:
                        post.imageBytes != null
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                post.imageBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const Center(
                              child: Text(
                                'No item photo',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                  ),
                const SizedBox(height: 16),
                _reviewRow('Item', post?.itemName ?? 'Unknown'),
                _reviewRow('Claimer Name', claim.claimerName),
                _reviewRow('Claimer Email', claim.claimerEmail),
                _reviewRow('Proof of Ownership', '"${claim.proof}"'),
                _reviewRow('Request Date', formatDate(claim.requestDate)),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Claimer Contact',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          claim.claimerContact,
                          style: const TextStyle(
                            color: darkSlate,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          store.rejectClaim(claim);
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'REJECT',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final res = await store.approveClaim(claim);
                          if (!ctx.mounted) return;
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
                          'APPROVE + OTP',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkSlate,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ================= SMALL WIDGETS ================= */

  Widget _viewBtn(String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.visibility_rounded, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryIndigo,
        side: const BorderSide(color: primaryIndigo, width: 1.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }

  Widget _adminSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: darkSlate,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
      ),
    );
  }

  Widget _emptyMini(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.grey,
          fontStyle: FontStyle.italic,
          fontSize: 12,
        ),
      ),
    );
  }
}
