import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';

/* =========================================================
   STORE (Firebase Auth + Firestore LIVE + OTP AUTO-RENEW)
   OTP 30 min por automatic renew — 20 sec check interval
========================================================= */

class AppStore extends ChangeNotifier {
  final Random random = Random();
  final String adminId = 'ADMIN-001';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StreamSubscription? _postsSub;
  StreamSubscription? _claimsSub;
  StreamSubscription? _userSub;
  StreamSubscription? _identitySub;
  Timer? _otpRenewTimer;

  AppUser currentUser = AppUser(
    userId: 'USER-1001',
    name: 'Student User',
    email: '',
    password: '',
    contact: '01700000000',
  );

  final List<ItemPost> posts = [];
  final List<ClaimRequest> claims = [];

  List<Map<String, dynamic>> pendingIdentityUsers = [];

  /* ---------- LIVE LISTENERS + OTP TIMER ---------- */

  void _startListeners() {
    _stopListeners();

    if (currentUser.userId.isNotEmpty) {
      _userSub = _db
          .collection('users')
          .doc(currentUser.userId)
          .snapshots()
          .listen((doc) {
            if (!doc.exists || doc.data() == null) return;
            final data = doc.data()!;
            final s = (data['identityStatus'] ?? 'unverified').toString();
            final newStatus = IdentityStatus.values.firstWhere(
              (e) => e.name == s,
              orElse: () => IdentityStatus.unverified,
            );
            if (data['documentName'] != null) {
              currentUser.documentName = data['documentName'].toString();
            }
            if (data['documentPhotoBase64'] != null) {
              try {
                currentUser.documentPhotoBytes = base64Decode(
                  data['documentPhotoBase64'].toString(),
                );
              } catch (_) {}
            }
            if (newStatus != currentUser.identityStatus) {
              currentUser.identityStatus = newStatus;
              notifyListeners();
            }
          });
    }

    _identitySub = _db
        .collection('users')
        .where('identityStatus', isEqualTo: 'pending')
        .snapshots()
        .listen((snap) {
          pendingIdentityUsers =
              snap.docs.map((d) {
                final data = d.data();
                return {
                  'uid': d.id,
                  'name': (data['name'] ?? 'User').toString(),
                  'email': (data['email'] ?? '').toString(),
                  'contact': (data['contact'] ?? '').toString(),
                  'documentName': data['documentName']?.toString(),
                  'documentPhotoBase64':
                      data['documentPhotoBase64']?.toString(),
                };
              }).toList();
          notifyListeners();
        });

    _postsSub = _db.collection('posts').snapshots().listen((snap) {
      posts.clear();
      for (final doc in snap.docs) {
        try {
          posts.add(ItemPost.fromMap(doc.data()));
        } catch (_) {}
      }
      notifyListeners();
    });

    _claimsSub = _db.collection('claims').snapshots().listen((snap) {
      claims.clear();
      for (final doc in snap.docs) {
        try {
          claims.add(ClaimRequest.fromMap(doc.data()));
        } catch (_) {}
      }
      notifyListeners();
    });

    _startOtpAutoRenew();
  }

  void _stopListeners() {
    _postsSub?.cancel();
    _postsSub = null;
    _claimsSub?.cancel();
    _claimsSub = null;
    _userSub?.cancel();
    _userSub = null;
    _identitySub?.cancel();
    _identitySub = null;
    _otpRenewTimer?.cancel();
    _otpRenewTimer = null;
  }

  /* ---------- OTP AUTO-RENEW (30 min por automatic notun OTP) ---------- */

  void _startOtpAutoRenew() {
    _otpRenewTimer?.cancel();
    _otpRenewTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (currentUser.userId.isEmpty) return;
      final expiredClaims =
          claims
              .where(
                (c) =>
                    c.claimerId == currentUser.userId &&
                    c.status == ClaimStatus.approved &&
                    isOtpExpired(c),
              )
              .toList();
      for (final c in expiredClaims) {
        await autoRenewExpiredOtp(c);
      }
    });
  }

  Future<void> autoRenewExpiredOtp(ClaimRequest claim) async {
    if (claim.status != ClaimStatus.approved) return;
    if (!isOtpExpired(claim)) return;

    final otpCode = (1000 + random.nextInt(9000)).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 30));

    try {
      await _db.collection('claims').doc(claim.requestId).update({
        'otpCode': otpCode,
        'otpExpiry': Timestamp.fromDate(expiry),
      });
      claim.otpCode = otpCode;
      claim.otpExpiry = expiry;
      notifyListeners();
    } catch (_) {}
  }

  /* ---------- AUTH: REGISTER ---------- */

  Future<String?> registerUser({
    required String name,
    required String email,
    required String password,
    required String contact,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      currentUser = AppUser(
        userId: uid,
        name: name,
        email: email,
        password: password,
        contact: contact,
      );

      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'contact': contact,
        'identityStatus': 'unverified',
        'documentName': null,
        'documentPhotoBase64': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _startListeners();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'This email is already registered. Please login.';
      }
      if (e.code == 'weak-password') {
        return 'Password must be at least 6 characters.';
      }
      if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      }
      return e.message ?? 'Registration failed.';
    } catch (e) {
      return 'Registration failed: $e';
    }
  }

  /* ---------- AUTH: LOGIN ---------- */

  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        final user = AppUser(
          userId: uid,
          name: (data['name'] ?? 'User').toString(),
          email: email,
          password: '',
          contact: (data['contact'] ?? '').toString(),
        );
        final statusStr = (data['identityStatus'] ?? 'unverified').toString();
        user.identityStatus = IdentityStatus.values.firstWhere(
          (s) => s.name == statusStr,
          orElse: () => IdentityStatus.unverified,
        );
        if (data['documentName'] != null) {
          user.documentName = data['documentName'].toString();
        }
        if (data['documentPhotoBase64'] != null) {
          try {
            user.documentPhotoBytes = base64Decode(
              data['documentPhotoBase64'].toString(),
            );
          } catch (_) {}
        }
        currentUser = user;
      } else {
        final name = email.split('@').first;
        currentUser = AppUser(
          userId: uid,
          name: name,
          email: email,
          password: '',
          contact: '',
        );
        await _db.collection('users').doc(uid).set({
          'name': name,
          'email': email,
          'contact': '',
          'identityStatus': 'unverified',
          'documentName': null,
          'documentPhotoBase64': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _startListeners();
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return 'No account found with this email/password.';
      }
      if (e.code == 'wrong-password') {
        return 'Incorrect password.';
      }
      if (e.code == 'invalid-email') {
        return 'Invalid email address.';
      }
      return e.message ?? 'Login failed.';
    } catch (e) {
      return 'Login failed: $e';
    }
  }

  /* ---------- AUTH: LOGOUT ---------- */

  void signOut() {
    _stopListeners();
    posts.clear();
    claims.clear();
    pendingIdentityUsers.clear();
    currentUser = AppUser(
      userId: '',
      name: 'User',
      email: '',
      password: '',
      contact: '',
    );
    notifyListeners();
    _auth.signOut();
  }

  /* ---------- ADMIN MODE ---------- */

  Future<void> startAdminMode() async {
    _startListeners();
    notifyListeners();
  }

  /* ---------- ID VERIFICATION ---------- */

  void attachDocument(Uint8List bytes, String fileName) {
    currentUser.documentName = fileName;
    currentUser.documentPhotoBytes = bytes;
    notifyListeners();
  }

  void removeIdDocument() {
    currentUser.documentName = null;
    currentUser.documentPhotoBytes = null;
    notifyListeners();
  }

  Future<void> submitIdentityRequest() async {
    if (currentUser.documentPhotoBytes == null) return;
    currentUser.identityStatus = IdentityStatus.pending;
    notifyListeners();
    try {
      await _db.collection('users').doc(currentUser.userId).update({
        'identityStatus': 'pending',
        'documentName': currentUser.documentName,
        'documentPhotoBase64': base64Encode(currentUser.documentPhotoBytes!),
      });
    } catch (_) {}
  }

  Future<void> approveIdentityFor(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'identityStatus': 'verified',
      });
    } catch (_) {}
  }

  Future<void> rejectIdentityFor(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'identityStatus': 'rejected',
      });
    } catch (_) {}
  }

  /* ---------- POSTS ---------- */

  Future<String?> createPost({
    required String itemName,
    required String category,
    required String itemStatus,
    required DateTime date,
    required String location,
    required String imageUrl,
    required Uint8List? imageBytes,
    required String description,
  }) async {
    if (imageBytes != null) {
      final b64 = base64Encode(imageBytes);
      if (b64.length > 900000) {
        return 'Photo is too large. Please try a different photo.';
      }
    }

    final id = 'ITEM-${DateTime.now().millisecondsSinceEpoch}';
    final post = ItemPost(
      itemId: id,
      userId: currentUser.userId,
      posterName: currentUser.name,
      posterContact: currentUser.contact,
      itemName: itemName,
      category: category,
      itemStatus: itemStatus,
      date: date,
      location: location,
      imageUrl: imageUrl,
      imageBytes: imageBytes,
      description: description,
    );

    try {
      await _db.collection('posts').doc(id).set(post.toMap());
    } catch (e) {
      return 'Could not save post: $e';
    }

    notifyListeners();
    return null;
  }

  Future<void> approvePost(ItemPost post) async {
    post.reviewStatus = PostReviewStatus.approved;
    notifyListeners();
    try {
      await _db.collection('posts').doc(post.itemId).update({
        'reviewStatus': 'approved',
      });
    } catch (_) {}
  }

  Future<void> rejectPost(ItemPost post) async {
    post.reviewStatus = PostReviewStatus.rejected;
    notifyListeners();
    try {
      await _db.collection('posts').doc(post.itemId).update({
        'reviewStatus': 'rejected',
      });
    } catch (_) {}
  }

  ItemPost? getPost(String itemId) {
    try {
      return posts.firstWhere((post) => post.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  /* ---------- CLAIMS (Firestore LIVE) ---------- */

  Future<String?> submitClaim({
    required ItemPost post,
    required String name,
    required String email,
    required String contact,
    required String proof,
  }) async {
    if (post.reviewStatus != PostReviewStatus.approved) {
      return 'Item is pending admin review.';
    }
    if (post.deliveryStatus != 'Open') {
      return 'Item already reserved/delivered.';
    }
    final already = claims.any(
      (c) =>
          c.itemId == post.itemId &&
          c.claimerId == currentUser.userId &&
          (c.status == ClaimStatus.pending || c.status == ClaimStatus.approved),
    );
    if (already) {
      return 'You already have an active claim for this item.';
    }

    final id = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
    final claim = ClaimRequest(
      requestId: id,
      itemId: post.itemId,
      claimerId: currentUser.userId,
      claimerName: name,
      claimerEmail: email,
      claimerContact: contact,
      proof: proof,
      requestDate: DateTime.now(),
    );

    try {
      await _db.collection('claims').doc(id).set(claim.toMap());
    } catch (e) {
      return 'Could not send claim: $e';
    }
    return null;
  }

  List<ClaimRequest> claimsForItem(String itemId) {
    final result = claims.where((c) => c.itemId == itemId).toList();
    result.sort((a, b) => a.requestDate.compareTo(b.requestDate));
    return result;
  }

  bool isFirstPendingClaim(ClaimRequest claim) {
    final pending =
        claimsForItem(
          claim.itemId,
        ).where((c) => c.status == ClaimStatus.pending).toList();
    return pending.isNotEmpty && pending.first.requestId == claim.requestId;
  }

  Future<AppResult> approveClaim(ClaimRequest claim) async {
    final post = getPost(claim.itemId);
    if (post == null) {
      return AppResult(success: false, message: 'Post not found.');
    }
    if (post.deliveryStatus != 'Open') {
      return AppResult(success: false, message: 'Item already assigned.');
    }
    if (!isFirstPendingClaim(claim)) {
      return AppResult(
        success: false,
        message: 'Approve earliest claim first.',
      );
    }

    final otpCode = (1000 + random.nextInt(9000)).toString();
    final expiry = DateTime.now().add(const Duration(minutes: 30));

    try {
      await _db.collection('claims').doc(claim.requestId).update({
        'status': 'approved',
        'otpCode': otpCode,
        'otpExpiry': Timestamp.fromDate(expiry),
      });
      await _db.collection('posts').doc(post.itemId).update({
        'deliveryStatus': 'Reserved',
      });
    } catch (e) {
      return AppResult(success: false, message: 'Approve failed: $e');
    }

    claim.status = ClaimStatus.approved;
    claim.otpCode = otpCode;
    claim.otpExpiry = expiry;
    post.deliveryStatus = 'Reserved';
    notifyListeners();

    return AppResult(
      success: true,
      message: 'Claim Approved! OTP sent to claimer.',
      otp: otpForClaim(claim),
    );
  }

  bool isOtpExpired(ClaimRequest claim) {
    if (claim.otpCode == null) return true;
    if (claim.otpExpiry == null) return true;
    return DateTime.now().isAfter(claim.otpExpiry!);
  }

  Future<void> rejectClaim(ClaimRequest claim) async {
    claim.status = ClaimStatus.rejected;
    notifyListeners();
    try {
      await _db.collection('claims').doc(claim.requestId).update({
        'status': 'rejected',
      });
    } catch (_) {}
  }

  OtpRecord? otpForClaim(ClaimRequest claim) {
    if (claim.otpCode == null || claim.otpExpiry == null) return null;
    return OtpRecord(
      otpId: 'OTP-${claim.requestId}',
      requestId: claim.requestId,
      verificationCode: claim.otpCode!,
      expiryTime: claim.otpExpiry!,
    );
  }

  Future<AppResult> verifyOtpAndDeliver({
    required String itemId,
    required String enteredOtp,
  }) async {
    ClaimRequest? approvedClaim;
    try {
      approvedClaim = claims.firstWhere(
        (c) => c.itemId == itemId && c.status == ClaimStatus.approved,
      );
    } catch (_) {}

    if (approvedClaim == null) {
      return AppResult(
        success: false,
        message: 'No approved claim for this item.',
      );
    }
    if (approvedClaim.otpCode == null) {
      return AppResult(success: false, message: 'OTP record missing.');
    }
    if (approvedClaim.otpExpiry != null &&
        DateTime.now().isAfter(approvedClaim.otpExpiry!)) {
      return AppResult(
        success: false,
        message:
            'OTP has expired. A new one arrives automatically in a moment.',
      );
    }
    if (enteredOtp != approvedClaim.otpCode) {
      return AppResult(success: false, message: 'Invalid OTP code entered.');
    }

    try {
      await _db.collection('claims').doc(approvedClaim.requestId).update({
        'status': 'delivered',
        'otpCode': null,
        'otpExpiry': null,
      });
      await _db.collection('posts').doc(itemId).update({
        'deliveryStatus': 'Delivered',
      });
    } catch (e) {
      return AppResult(success: false, message: 'Delivery update failed: $e');
    }

    final post = getPost(itemId);
    if (post != null) post.deliveryStatus = 'Delivered';
    approvedClaim.status = ClaimStatus.delivered;
    notifyListeners();

    return AppResult(
      success: true,
      message: 'Handover complete! Item marked delivered.',
    );
  }
}
