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
        copied['isBusinessProduct'] = true;
        products.add(copied);
      }
    }

    return products;
  }

  void addBusiness(Map<String, dynamic> business) {
    allBusinesses.add(Map<String, dynamic>.from(business));
    notifyListeners();
  }

  void updateBusiness(int index, Map<String, dynamic> business) {
    if (index >= 0 && index < allBusinesses.length) {
      allBusinesses[index] = Map<String, dynamic>.from(business);
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

