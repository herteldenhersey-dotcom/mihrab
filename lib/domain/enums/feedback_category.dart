/// User feedback categories.
enum FeedbackCategory {
  bug,
  suggestion,
  prayerTimeIssue,
  translation,
  other;

  String get key => name;

  static FeedbackCategory fromKey(String key) =>
      FeedbackCategory.values.firstWhere((e) => e.name == key,
          orElse: () => FeedbackCategory.other);
}
