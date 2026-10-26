import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

/* =========================================================
   MODELS (Firestore serialization soho)
========================================================= */

enum IdentityStatus { unverified, pending, verified, rejected }

enum PostReviewStatus { pending, approved, rejected }

enum ClaimStatus { pending, approved, rejected, delivered }

class AppUser {
  String userId, name, email, password, contact;
  String? documentName;
  Uint8List? documentPhotoBytes;
  IdentityStatus identityStatus;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.password,
    required this.contact,
    this.documentName,
    this.documentPhotoBytes,
    this.identityStatus = IdentityStatus.unverified,
  });
}

class ItemPost {
  final String itemId,
      userId,
      posterName,
      posterContact,
      itemName,
      category,
      itemStatus,
      location,
      imageUrl,
      description;
  final DateTime date;
  final Uint8List? imageBytes;
  PostReviewStatus reviewStatus;
  String deliveryStatus;

  ItemPost({
    required this.itemId,
    required this.userId,
    required this.posterName,
    this.posterContact = '',
    required this.itemName,
    required this.category,
    required this.itemStatus,
    required this.date,
    required this.location,
    required this.imageUrl,
    this.imageBytes,
    required this.description,
    this.reviewStatus = PostReviewStatus.pending,
    this.deliveryStatus = 'Open',
  });

  factory ItemPost.fromMap(Map<String, dynamic> map) {
    return ItemPost(
      itemId: (map['itemId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      posterName: (map['posterName'] ?? '').toString(),
      posterContact: (map['posterContact'] ?? '').toString(),
      itemName: (map['itemName'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      itemStatus: (map['itemStatus'] ?? 'Lost').toString(),
      location: (map['location'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      date:
          map['date'] is Timestamp
              ? (map['date'] as Timestamp).toDate()
              : DateTime.now(),
      imageBytes:
          map['imageBase64'] != null
              ? base64Decode(map['imageBase64'].toString())
              : null,
      reviewStatus: PostReviewStatus.values.firstWhere(
        (s) => s.name == (map['reviewStatus'] ?? 'pending'),
        orElse: () => PostReviewStatus.pending,
      ),
      deliveryStatus: (map['deliveryStatus'] ?? 'Open').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'userId': userId,
      'posterName': posterName,
      'posterContact': posterContact,
      'itemName': itemName,
      'category': category,
      'itemStatus': itemStatus,
      'location': location,
      'imageUrl': imageUrl,
      'description': description,
      'date': Timestamp.fromDate(date),
      'imageBase64': imageBytes != null ? base64Encode(imageBytes!) : null,
      'reviewStatus': reviewStatus.name,
      'deliveryStatus': deliveryStatus,
    };
  }
}

class ClaimRequest {
  final String requestId,
      itemId,
      claimerId,
      claimerName,
      claimerEmail,
      claimerContact,
      proof;
  final DateTime requestDate;
  ClaimStatus status;
  String? otpCode;
  DateTime? otpExpiry;

  ClaimRequest({
    required this.requestId,
    required this.itemId,
    required this.claimerId,
    required this.claimerName,
    required this.claimerEmail,
    required this.claimerContact,
    required this.proof,
    required this.requestDate,
    this.status = ClaimStatus.pending,
    this.otpCode,
    this.otpExpiry,
  });

  factory ClaimRequest.fromMap(Map<String, dynamic> map) {
    return ClaimRequest(
      requestId: (map['requestId'] ?? '').toString(),
      itemId: (map['itemId'] ?? '').toString(),
      claimerId: (map['claimerId'] ?? '').toString(),
      claimerName: (map['claimerName'] ?? '').toString(),
      claimerEmail: (map['claimerEmail'] ?? '').toString(),
      claimerContact: (map['claimerContact'] ?? '').toString(),
      proof: (map['proof'] ?? '').toString(),
      requestDate:
          map['requestDate'] is Timestamp
              ? (map['requestDate'] as Timestamp).toDate()
              : DateTime.now(),
      status: ClaimStatus.values.firstWhere(
        (s) => s.name == (map['status'] ?? 'pending'),
        orElse: () => ClaimStatus.pending,
      ),
      otpCode: map['otpCode']?.toString(),
      otpExpiry:
          map['otpExpiry'] is Timestamp
              ? (map['otpExpiry'] as Timestamp).toDate()
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'itemId': itemId,
      'claimerId': claimerId,
      'claimerName': claimerName,
      'claimerEmail': claimerEmail,
      'claimerContact': claimerContact,
      'proof': proof,
      'requestDate': Timestamp.fromDate(requestDate),
      'status': status.name,
      'otpCode': otpCode,
      'otpExpiry': otpExpiry != null ? Timestamp.fromDate(otpExpiry!) : null,
    };
  }
}

class OtpRecord {
  final String otpId, requestId, verificationCode;
  final DateTime expiryTime;

  OtpRecord({
    required this.otpId,
    required this.requestId,
    required this.verificationCode,
    required this.expiryTime,
  });
}

class AppResult {
  final bool success;
  final String message;
  final OtpRecord? otp;

  AppResult({required this.success, required this.message, this.otp});
}
