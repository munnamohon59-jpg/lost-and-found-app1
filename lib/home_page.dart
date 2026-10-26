import 'package:flutter/material.dart';
import 'colors.dart';
import 'models.dart';
import 'app_store.dart';
import 'helpers.dart';

/* =========================================================
   3. HOME PAGE
   Feed = admin APPROVED posts (delivered soho — record hisebe thakbe)
   My Claims count = sudhu ACTIVE claims (delivered count hobe NA)
========================================================= */

class HomePage extends StatelessWidget {
  final AppStore store;
  final VoidCallback onLogout;
  final VoidCallback onOpenPost;

  const HomePage({
    super.key,
    required this.store,
    required this.onLogout,
    required this.onOpenPost,
  });

  @override
  Widget build(BuildContext context) {
    // Feed: admin approved posts (delivered post o thakbe — as it is)
    final approvedPosts =
        store.posts
            .where((p) => p.reviewStatus == PostReviewStatus.approved)
            .toList();

    // My Claims count: sudhu ACTIVE claim (delivered BADE)
    final activeClaimCount =
        store.claims
            .where(
              (c) =>
                  c.claimerId == store.currentUser.userId &&
                  (c.status == ClaimStatus.pending ||
                      c.status == ClaimStatus.approved),
            )
            .length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME, ${store.currentUser.name.toUpperCase()}',
                    style: const TextStyle(
                      color: primaryIndigo,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Lost & Found Feed',
                    style: TextStyle(
                      color: darkSlate,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: neonPink),
                tooltip: 'Logout',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        IdentityBanner(store: store),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _verticalStatCard(
                'Item Posts',
                approvedPosts.length.toString(),
                Icons.inventory_2_rounded,
                primaryIndigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _verticalStatCard(
                'My Claims',
                activeClaimCount.toString(),
                Icons.assignment_turned_in_rounded,
                accentViolet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        const Text(
          'RECENT ITEM POSTS',
          style: TextStyle(
            color: darkSlate,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),

        if (approvedPosts.isEmpty)
          emptyState(
            'No approved items yet. Admin will review new posts soon.',
            Icons.inventory_2_outlined,
            onOpenPost,
          )
        else
          ...approvedPosts.reversed.map(
            (post) => ModernItemCard(post: post, store: store),
          ),
      ],
    );
  }

  Widget _verticalStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 26),
              Text(
                count,
                style: const TextStyle(
                  color: darkSlate,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/* =========================================================
   4. E-COMMERCE STYLE ITEM CARD (WITH PICKED IMAGE SUPPORT)
========================================================= */

class ModernItemCard extends StatelessWidget {
  final ItemPost post;
  final AppStore store;

  const ModernItemCard({super.key, required this.post, required this.store});

  @override
  Widget build(BuildContext context) {
    final isLost = post.itemStatus == 'Lost';
    final canClaim =
        post.reviewStatus == PostReviewStatus.approved &&
        post.deliveryStatus == 'Open';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: darkSlate.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: _buildPostImage(),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: _badge(
                  post.itemStatus.toUpperCase(),
                  isLost ? neonPink : emeraldGreen,
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: _badge(post.category, Colors.black.withOpacity(0.65)),
              ),
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.itemName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: neonPink,
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            post.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // তারিখ এবং পোস্টারের নাম একসাথে দেখানো হচ্ছে
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 16,
                          color: primaryIndigo,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          formatDate(post.date),
                          style: const TextStyle(
                            color: primaryIndigo,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    statusBadge(
                      post.deliveryStatus,
                      post.deliveryStatus == 'Open'
                          ? primaryIndigo
                          : amberWarning,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (post.description.isNotEmpty) ...[
                  Text(
                    post.description,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF1F5F9), thickness: 1.2),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Posted by: ${post.posterName}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: darkSlate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        canClaim
                            ? () => showClaimSheet(context, store, post)
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          canClaim ? darkSlate : Colors.grey.shade300,
                      foregroundColor:
                          canClaim ? Colors.white : Colors.grey.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      canClaim
                          ? 'CLAIM THIS ITEM'
                          : post.deliveryStatus == 'Delivered'
                          ? 'ITEM DELIVERED'
                          : 'RESERVED',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // picked photo > network url > placeholder
  Widget _buildPostImage() {
    if (post.imageBytes != null) {
      return Image.memory(
        post.imageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (post.imageUrl.isNotEmpty) {
      return Image.network(
        post.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _badge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              color: Colors.grey,
              size: 36,
            ),
            SizedBox(height: 4),
            Text(
              'No Image Attached',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================================================
   IDENTITY BANNER
========================================================= */

class IdentityBanner extends StatelessWidget {
  final AppStore store;
  const IdentityBanner({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final status = store.currentUser.identityStatus;
    final isVerified = status == IdentityStatus.verified;
    final color = isVerified ? emeraldGreen : amberWarning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(
            isVerified ? Icons.verified_rounded : Icons.gpp_maybe_rounded,
            color: color,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'Verified Student Account'
                      : 'Identity Unverified',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: darkSlate,
                  ),
                ),
                Text(
                  isVerified
                      ? 'Full posting access granted.'
                      : 'Verify ID in Post tab to publish items.',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          statusBadge(status.name.toUpperCase(), color),
        ],
      ),
    );
  }
}
