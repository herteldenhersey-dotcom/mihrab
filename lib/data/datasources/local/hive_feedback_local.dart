import 'package:hive/hive.dart';

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

  List<FeedbackItem> getUnsubmitted() =>
      _box.values.where((f) => !f.submitted).toList();

  Future<void> markSubmitted(String id) async {
    final item = _box.get(id);
    if (item != null) {
      await _box.put(id, item.copyWith(submitted: true));
    }
  }
}
