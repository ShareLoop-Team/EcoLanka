// Pickup & delivery options — Open/Closed (OCP) + Liskov Substitution (LSP).
//
// The request flow only knows the HandoverMethod abstraction. To add a new
// partner (e.g. Uber Connect), create a new class and add it to
// HandoverMethods.all — no change to the request controller or screens.

import 'package:flutter/material.dart';

abstract class HandoverMethod {
  const HandoverMethod();

  /// Stored in requests/{id}.handoverMethod.
  String get id;
  String get title;
  String get description;
  IconData get icon;

  /// Advice shown to both people once this method is chosen.
  List<String> safetyTips();
}

class DirectHandover extends HandoverMethod {
  const DirectHandover();

  @override
  String get id => 'direct';
  @override
  String get title => 'Direct handover';
  @override
  String get description => 'Meet in person at an agreed safe place.';
  @override
  IconData get icon => Icons.handshake_outlined;
  @override
  List<String> safetyTips() => const [
        'Meet in a busy public place during daylight.',
        'Check the item together before accepting it.',
        'Bring a friend if you can.',
      ];
}

class CourierDelivery extends HandoverMethod {
  const CourierDelivery();

  @override
  String get id => 'courier';
  @override
  String get title => 'Courier delivery';
  @override
  String get description => 'Send it by a standard courier — good between districts.';
  @override
  IconData get icon => Icons.local_shipping_outlined;
  @override
  List<String> safetyTips() => const [
        'Agree who pays the courier fee before sending.',
        'Share the tracking number in your messages.',
        'Pack fragile items carefully.',
      ];
}

class OnDemandDelivery extends HandoverMethod {
  const OnDemandDelivery();

  @override
  String get id => 'on_demand';
  @override
  String get title => 'PickMe Flash / on-demand';
  @override
  String get description => 'Fast door-to-door delivery within the same city.';
  @override
  IconData get icon => Icons.delivery_dining_outlined;
  @override
  List<String> safetyTips() => const [
        'The person booking the ride pays for it unless agreed otherwise.',
        'Share the rider details with each other.',
        'Use for small items within the same city.',
      ];
}

class HandoverMethods {
  HandoverMethods._();

  static const List<HandoverMethod> all = [
    DirectHandover(),
    CourierDelivery(),
    OnDemandDelivery(),
  ];

  static List<String> get ids => all.map((m) => m.id).toList();

  static HandoverMethod? byId(String? id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return null;
  }
}
