/// Delivery lifecycle of a [FeedbackItem].
///
/// This replaces the previous misleading `submitted` boolean. Opening a
/// `mailto:` intent does NOT prove an e-mail was actually sent, so V1 can only
/// honestly report [handoffInitiated]. A real backend (REST/Firebase/Supabase)
/// added later can advance an item to [delivered] once the server confirms
/// receipt.
enum FeedbackDeliveryStatus {
  /// Created and persisted locally, but no delivery attempt has been made yet
  /// (e.g. queued while offline).
  pending,

  /// A delivery handoff was initiated — in V1 the `mailto:` intent was
  /// launched. This does NOT guarantee the message was actually sent.
  handoffInitiated,

  /// Delivery confirmed by a real backend. Not reachable in V1 (no backend);
  /// reserved for future REST/Firebase/Supabase implementations.
  delivered,

  /// A delivery attempt failed (e.g. no mail client, backend error). The item
  /// stays queued so it can be retried.
  failed;

  String get key => name;

  static FeedbackDeliveryStatus fromKey(String key) =>
      FeedbackDeliveryStatus.values.firstWhere(
        (e) => e.name == key,
        orElse: () => FeedbackDeliveryStatus.pending,
      );

  /// True once a handoff has been initiated or delivery confirmed — i.e. the
  /// item no longer needs to sit in the outgoing queue.
  bool get isHandedOff =>
      this == FeedbackDeliveryStatus.handoffInitiated ||
      this == FeedbackDeliveryStatus.delivered;
}
