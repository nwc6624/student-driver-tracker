import 'package:hive/hive.dart';

part 'driving_session.g.dart';

@HiveType(typeId: 1)
class DrivingSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String driverId;

  @HiveField(2)
  final int durationMinutes;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String location;

  @HiveField(5)
  final String? notes;

  @HiveField(6)
  final String? weatherConditions;

  DrivingSession({
    required this.id,
    required this.driverId,
    required this.durationMinutes,
    required this.date,
    required this.location,
    this.notes,
    this.weatherConditions,
  });

  Duration get duration => Duration(minutes: durationMinutes);

  DrivingSession copyWith({
    int? durationMinutes,
    DateTime? date,
    String? location,
    String? notes,
    String? weatherConditions,
  }) {
    return DrivingSession(
      id: id,
      driverId: driverId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      weatherConditions: weatherConditions ?? this.weatherConditions,
    );
  }

  double get hours => durationMinutes / 60.0;
}
