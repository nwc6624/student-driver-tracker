import 'package:hive/hive.dart';

part 'driving_session.g.dart';

@HiveType(typeId: 1)
class DrivingSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String driverId;

  @HiveField(2)
  final Duration duration;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String location;

  @HiveField(5)
  final String? notes;

  DrivingSession({
    required this.id,
    required this.driverId,
    required this.duration,
    required this.date,
    required this.location,
    this.notes,
  });

  DrivingSession copyWith({
    Duration? duration,
    DateTime? date,
    String? location,
    String? notes,
  }) {
    return DrivingSession(
      id: id,
      driverId: driverId,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  double get hours => duration.inMinutes / 60.0;
}
