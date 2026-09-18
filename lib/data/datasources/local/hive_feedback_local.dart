import 'package:hive/hive.dart';

import '../../../domain/enums/feedback_delivery_status.dart';
import '../../../domain/models/feedback_model.dart';
import 'hive_boxes.dart';

/// Local persistence for feedback items (also acts as the offline queue).
class HiveFeedbackLocal {
  Box<FeedbackItem> get _box => Hive.box<FeedbackItem>(HiveBoxes.feedback);

  Future<void> save(FeedbackItem item) => _box.put(item.id, item);

  List<FeedbackItem> getAll() {
    final items = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Items that have NOT yet been handed off (still queued for delivery).
  List<FeedbackItem> getQueued() =>
      _box.values.where((f) => !f.deliveryStatus.isHandedOff).toList();

  /// Updates the delivery status of the item with [id].
  Future<void> updateStatus(String id, FeedbackDeliveryStatus status) async {
    final item = _box.get(id);
    if (item != null) {
      await _box.put(id, item.copyWith(deliveryStatus: status));
    }
  }
}
