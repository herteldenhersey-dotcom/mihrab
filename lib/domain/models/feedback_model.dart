import 'package:equatable/equatable.dart';

import '../enums/feedback_category.dart';
import '../enums/feedback_delivery_status.dart';

/// A single feedback entry authored by the user.
class FeedbackItem extends Equatable {
  final String id;
  final FeedbackCategory category;
  final String message;
  final String? email;
  final DateTime createdAt;

  /// Delivery lifecycle of this item. See [FeedbackDeliveryStatus].
  ///
  /// NOTE: In V1 the most that can be reported is
  /// [FeedbackDeliveryStatus.handoffInitiated] (the `mailto:` intent was
  /// launched). Only a real backend can advance to
  /// [FeedbackDeliveryStatus.delivered].
  final FeedbackDeliveryStatus deliveryStatus;

  /// App version captured at authoring time (diagnostics).
  final String? appVersion;

  const FeedbackItem({
    required this.id,
    required this.category,
    required this.message,
    required this.createdAt,
    this.email,
    this.deliveryStatus = FeedbackDeliveryStatus.pending,
    this.appVersion,
  });

  FeedbackItem copyWith({
    String? id,
    FeedbackCategory? category,
    String? message,
    String? email,
    DateTime? createdAt,
    FeedbackDeliveryStatus? deliveryStatus,
    String? appVersion,
  }) {
    return FeedbackItem(
      id: id ?? this.id,
      category: category ?? this.category,
      message: message ?? this.message,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.key,
        'message': message,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'deliveryStatus': deliveryStatus.key,
        'appVersion': appVersion,
      };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        id: json['id'] as String,
        category: FeedbackCategory.fromKey(json['category'] as String? ?? ''),
        message: json['message'] as String? ?? '',
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        deliveryStatus: _readStatus(json),
        appVersion: json['appVersion'] as String?,
      );

  /// Reads the delivery status, falling back to the legacy `submitted` boolean
  /// (true -> handoffInitiated, false -> pending) for backward compatibility
  /// with items persisted by earlier builds.
  static FeedbackDeliveryStatus _readStatus(Map<String, dynamic> json) {
    final raw = json['deliveryStatus'];
    if (raw is String) return FeedbackDeliveryStatus.fromKey(raw);
    final legacy = json['submitted'];
    if (legacy is bool) {
      return legacy
          ? FeedbackDeliveryStatus.handoffInitiated
          : FeedbackDeliveryStatus.pending;
    }
    return FeedbackDeliveryStatus.pending;
  }

  @override
  List<Object?> get props =>
      [id, category, message, email, createdAt, deliveryStatus, appVersion];
}
