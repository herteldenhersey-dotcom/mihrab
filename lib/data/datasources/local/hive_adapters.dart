import 'package:hive/hive.dart';

import '../../../domain/enums/feedback_category.dart';
import '../../../domain/enums/feedback_delivery_status.dart';
import '../../../domain/models/feedback_model.dart';
import '../../../domain/models/mosque_model.dart';

/// A cached set of mosques for a location, with the time it was fetched.
class MosqueCacheEntry {
  final DateTime cachedAt;
  final List<Mosque> mosques;

  const MosqueCacheEntry({required this.cachedAt, required this.mosques});

  bool isFresh(Duration ttl) =>
      DateTime.now().difference(cachedAt) < ttl;
}

/// Hive type ids. Kept in one place to avoid collisions.
class HiveTypeIds {
  HiveTypeIds._();
  static const int mosque = 1;
  static const int feedbackItem = 2;
  static const int mosqueCacheEntry = 3;
}

/// Manual [TypeAdapter] for [Mosque].
///
/// Written by hand because the current stable toolchain cannot run
/// `hive_generator` (see pubspec.yaml note). Field order is stable; append
/// new fields at the end and bump nothing (Hive tolerates missing trailing
/// fields on read).
class MosqueAdapter extends TypeAdapter<Mosque> {
  @override
  final int typeId = HiveTypeIds.mosque;

  @override
  Mosque read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return Mosque(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      address: fields[4] as String?,
      distanceMeters: fields[5] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Mosque obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.distanceMeters);
  }
}

/// Manual [TypeAdapter] for [FeedbackItem].
class FeedbackItemAdapter extends TypeAdapter<FeedbackItem> {
  @override
  final int typeId = HiveTypeIds.feedbackItem;

  @override
  FeedbackItem read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return FeedbackItem(
      id: fields[0] as String,
      category: FeedbackCategory.fromKey(fields[1] as String),
      message: fields[2] as String,
      email: fields[3] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(fields[4] as int),
      deliveryStatus: _readStatus(fields[5]),
      appVersion: fields[6] as String?,
    );
  }

  /// Field 5 historically stored a `submitted` bool; newer records store the
  /// [FeedbackDeliveryStatus] key as a String. Read both for compatibility.
  static FeedbackDeliveryStatus _readStatus(Object? raw) {
    if (raw is String) return FeedbackDeliveryStatus.fromKey(raw);
    if (raw is bool) {
      return raw
          ? FeedbackDeliveryStatus.handoffInitiated
          : FeedbackDeliveryStatus.pending;
    }
    return FeedbackDeliveryStatus.pending;
  }

  @override
  void write(BinaryWriter writer, FeedbackItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.category.key)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.email)
      ..writeByte(4)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(5)
      ..write(obj.deliveryStatus.key)
      ..writeByte(6)
      ..write(obj.appVersion);
  }
}

/// Manual [TypeAdapter] for [MosqueCacheEntry].
class MosqueCacheEntryAdapter extends TypeAdapter<MosqueCacheEntry> {
  @override
  final int typeId = HiveTypeIds.mosqueCacheEntry;

  @override
  MosqueCacheEntry read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return MosqueCacheEntry(
      cachedAt: DateTime.fromMillisecondsSinceEpoch(fields[0] as int),
      mosques: (fields[1] as List).cast<Mosque>(),
    );
  }

  @override
  void write(BinaryWriter writer, MosqueCacheEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.cachedAt.millisecondsSinceEpoch)
      ..writeByte(1)
      ..write(obj.mosques);
  }
}

/// Registers all adapters exactly once. Safe to call multiple times.
void registerHiveAdapters() {
  if (!Hive.isAdapterRegistered(HiveTypeIds.mosque)) {
    Hive.registerAdapter(MosqueAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.feedbackItem)) {
    Hive.registerAdapter(FeedbackItemAdapter());
  }
  if (!Hive.isAdapterRegistered(HiveTypeIds.mosqueCacheEntry)) {
    Hive.registerAdapter(MosqueCacheEntryAdapter());
  }
}
