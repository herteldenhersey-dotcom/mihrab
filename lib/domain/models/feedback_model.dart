import 'package:equatable/equatable.dart';

import '../enums/feedback_category.dart';

/// A single feedback entry authored by the user.
class FeedbackItem extends Equatable {
  final String id;
  final FeedbackCategory category;
  final String message;
  final String? email;
  final DateTime createdAt;

  /// Whether this item has been successfully handed off (e.g. email sent /
  /// synced to a backend). In V1 this flips to true once the mail intent
  /// is launched.
  final bool submitted;

  /// App version captured at authoring time (diagnostics).
  final String? appVersion;

  const FeedbackItem({
    required this.id,
    required this.category,
    required this.message,
    required this.createdAt,
    this.email,
    this.submitted = false,
    this.appVersion,
  });

  FeedbackItem copyWith({
    String? id,
    FeedbackCategory? category,
    String? message,
    String? email,
    DateTime? createdAt,
    bool? submitted,
    String? appVersion,
  }) {
    return FeedbackItem(
      id: id ?? this.id,
      category: category ?? this.category,
      message: message ?? this.message,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      submitted: submitted ?? this.submitted,
      appVersion: appVersion ?? this.appVersion,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.key,
        'message': message,
        'email': email,
        'createdAt': createdAt.toIso8601String(),
        'submitted': submitted,
        'appVersion': appVersion,
      };

  factory FeedbackItem.fromJson(Map<String, dynamic> json) => FeedbackItem(
        id: json['id'] as String,
        category: FeedbackCategory.fromKey(json['category'] as String? ?? ''),
        message: json['message'] as String? ?? '',
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        submitted: json['submitted'] as bool? ?? false,
        appVersion: json['appVersion'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, category, message, email, createdAt, submitted, appVersion];
}
