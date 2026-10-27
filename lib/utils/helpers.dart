// Shared lookup data: categories, item conditions, districts, statuses.

import 'package:flutter/material.dart';

class ItemCategory {
  final String id;
  final String name;
  final IconData icon;

  const ItemCategory(this.id, this.name, this.icon);
}

class AppCategories {
  AppCategories._();

  /// Categories from the Shareloop documentation (section 5.1).
  /// Keep ids in sync with backend/scripts/seed_categories.js.
  static const List<ItemCategory> all = [
    ItemCategory('books', 'Educational Books', Icons.menu_book_rounded),
    ItemCategory('school', 'School Supplies', Icons.school_outlined),
    ItemCategory('clothes', 'Clothes', Icons.checkroom_rounded),
    ItemCategory('shoes', 'Shoes', Icons.shopping_bag_outlined),
    ItemCategory('electronics', 'Electronics', Icons.devices_outlined),
    ItemCategory('household', 'Household Items', Icons.home_outlined),
    ItemCategory('other', 'Other', Icons.category_outlined),
  ];

  static ItemCategory byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => all.last);
}

class AppConditions {
  AppConditions._();

  /// Condition grading from the proposal: New, Good, Used.
  static const Map<String, String> labels = {
    'new': 'New',
    'good': 'Good',
    'used': 'Used',
  };

  static String label(String id) => labels[id] ?? 'Used';
}

class AppDistricts {
  AppDistricts._();

  static const List<String> all = [
    'Colombo', 'Gampaha', 'Kalutara', 'Kandy', 'Matale', 'Nuwara Eliya',
    'Galle', 'Matara', 'Hambantota', 'Jaffna', 'Kilinochchi', 'Mannar',
    'Vavuniya', 'Mullaitivu', 'Batticaloa', 'Ampara', 'Trincomalee',
    'Kurunegala', 'Puttalam', 'Anuradhapura', 'Polonnaruwa', 'Badulla',
    'Monaragala', 'Ratnapura', 'Kegalle',
  ];
}

class AppStatus {
  AppStatus._();

  static String label(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'donated':
        return 'Donated';
      case 'removed':
        return 'Removed';
      case 'open':
        return 'Open';
      case 'fulfilled':
        return 'Fulfilled';
      case 'closed':
        return 'Closed';
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
    }
    return status;
  }

  static Color color(String status) {
    switch (status) {
      case 'available':
      case 'accepted':
      case 'open':
        return const Color(0xFF2E7D32);
      case 'pending':
      case 'reserved':
        return const Color(0xFFF59E0B);
      case 'completed':
      case 'donated':
      case 'fulfilled':
        return const Color(0xFF1A73E8);
      case 'rejected':
      case 'cancelled':
      case 'removed':
      case 'closed':
        return const Color(0xFFBA1A1A);
    }
    return Colors.grey;
  }
}

class ReportReasons {
  ReportReasons._();

  static const Map<String, String> labels = {
    'spam': 'Spam or fake listing',
    'resell': 'Trying to sell / resell',
    'fraud': 'Fraud or scam',
    'inappropriate': 'Inappropriate content',
    'other': 'Other',
  };
}
