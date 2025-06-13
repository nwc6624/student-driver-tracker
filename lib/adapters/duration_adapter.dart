import 'package:hive/hive.dart';

/// Hive adapter for `Duration` since Hive does not provide one out-of-the-box.
///
/// We store the duration in micro-seconds (the native representation used by
/// `Duration`) so it is loss-less and easy to reconstruct.
///
/// Make sure the `typeId` **does not** clash with any of your other adapters.
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 99; // pick a high, unused id

  @override
  Duration read(BinaryReader reader) {
    final int us = reader.readInt(); // micro-seconds
    return Duration(microseconds: us);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
