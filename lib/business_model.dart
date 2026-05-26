import 'dart:collection';

import 'package:flutter/foundation.dart';

// Global list to store all businesses
final List<Map<String, dynamic>> allBusinesses = [];

class BusinessModel extends ChangeNotifier {
  BusinessModel._internal();

  static final BusinessModel instance = BusinessModel._internal();

  UnmodifiableListView<Map<String, dynamic>> get businesses =>
      UnmodifiableListView(allBusinesses);

  List<Map<String, dynamic>> getAllBusinesses() {
    return List<Map<String, dynamic>>.from(allBusinesses);
  }

  List<Map<String, dynamic>> getAllBusinessProducts() {
    final products = <Map<String, dynamic>>[];

    for (final business in allBusinesses) {
      final businessName = business['name'] as String? ?? '-';
      final businessCity = business['city'] as String? ?? '';
      final businessProvince = business['province'] as String? ?? '';
      final rawProducts = business['products'] as List? ?? [];

      for (final rawProduct in rawProducts) {
        if (rawProduct is! Map<String, dynamic>) continue;

        final copied = Map<String, dynamic>.from(rawProduct);
        copied['businessName'] = businessName;
        copied['businessCity'] = businessCity;
        copied['businessProvince'] = businessProvince;
        copied['businessVerificationStatus'] = business['verificationStatus'] ?? 'pending';
        copied['businessVerifiedAt'] = business['verifiedAt'];
        copied['isBusinessProduct'] = true;
        products.add(copied);
      }
    }

    return products;
  }

  Map<String, dynamic>? getBusinessByName(String name) {
    final target = name.trim();
    if (target.isEmpty) return null;

    for (final business in allBusinesses) {
      if ((business['name'] as String? ?? '').trim() == target) {
        return business;
      }
    }
    return null;
  }

  void addBusiness(Map<String, dynamic> business) {
    final copied = Map<String, dynamic>.from(business);
    copied['verificationStatus'] = copied['verificationStatus'] ?? 'pending';
    copied['verificationDocs'] = List<String>.from(copied['verificationDocs'] as List? ?? const []);
    copied['verificationRequestedAt'] = copied['verificationRequestedAt'] ?? DateTime.now().toIso8601String();
    copied['verifiedAt'] = copied['verifiedAt'];
    allBusinesses.add(copied);
    notifyListeners();
  }

  void requestVerification(int index, {List<String> documents = const []}) {
    if (index < 0 || index >= allBusinesses.length) return;

    final business = allBusinesses[index];
    final currentDocs = List<String>.from(business['verificationDocs'] as List? ?? const []);
    currentDocs.addAll(documents.where((doc) => doc.trim().isNotEmpty));

    business['verificationDocs'] = currentDocs;
    business['verificationStatus'] = 'pending';
    business['verificationRequestedAt'] = DateTime.now().toIso8601String();
    business['verifiedAt'] = null;
    notifyListeners();
  }

  void completeVerification(int index) {
    if (index < 0 || index >= allBusinesses.length) return;

    final business = allBusinesses[index];
    business['verificationStatus'] = 'verified';
    business['verifiedAt'] = DateTime.now().toIso8601String();
    notifyListeners();
  }

  String getVerificationLabel(Map<String, dynamic> business) {
    final status = (business['verificationStatus'] as String? ?? 'pending').toLowerCase();
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'processing':
        return 'Sedang diverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu verifikasi';
    }
  }

  bool isVerified(Map<String, dynamic> business) {
    return (business['verificationStatus'] as String? ?? 'pending').toLowerCase() == 'verified';
  }

  bool get hasVerifiedBusiness => allBusinesses.any(isVerified);

  void markVerificationProcessing(int index) {
    if (index < 0 || index >= allBusinesses.length) return;
    allBusinesses[index]['verificationStatus'] = 'processing';
    notifyListeners();
  }

  void updateBusiness(int index, Map<String, dynamic> business) {
    if (index >= 0 && index < allBusinesses.length) {
      final copied = Map<String, dynamic>.from(business);
      copied['verificationStatus'] = copied['verificationStatus'] ?? allBusinesses[index]['verificationStatus'] ?? 'pending';
      copied['verificationDocs'] = List<String>.from(copied['verificationDocs'] as List? ?? allBusinesses[index]['verificationDocs'] as List? ?? const []);
      copied['verificationRequestedAt'] = copied['verificationRequestedAt'] ?? allBusinesses[index]['verificationRequestedAt'];
      copied['verifiedAt'] = copied['verifiedAt'] ?? allBusinesses[index]['verifiedAt'];
      allBusinesses[index] = copied;
      notifyListeners();
    }
  }

  void deleteBusiness(int index) {
    if (index >= 0 && index < allBusinesses.length) {
      allBusinesses.removeAt(index);
      notifyListeners();
    }
  }

  void addReviewToBusinesses({
    required Set<String> businessNames,
    required Map<String, dynamic> review,
  }) {
    if (businessNames.isEmpty) return;

    for (final business in allBusinesses) {
      final businessName = (business['name'] as String? ?? '').trim();
      if (!businessNames.contains(businessName)) continue;

      final reviews = List<Map<String, dynamic>>.from(business['reviews'] as List? ?? []);
      reviews.add(Map<String, dynamic>.from(review));
      business['reviews'] = reviews;
    }

    notifyListeners();
  }

  Map<String, dynamic>? getBusinessAt(int index) {
    if (index >= 0 && index < allBusinesses.length) {
      return allBusinesses[index];
    }
    return null;
  }

  int get count => allBusinesses.length;
}

