import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String status;
  final DateTime? trialEndsAt;

  SubscriptionModel({required this.status, this.trialEndsAt});

  factory SubscriptionModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionModel(
      status: map['status'] ?? '',
      trialEndsAt: (map['trialEndsAt'] as Timestamp?)?.toDate(),
    );
  }
}