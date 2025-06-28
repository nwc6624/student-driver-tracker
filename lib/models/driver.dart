import 'package:hive/hive.dart';

part 'driver.g.dart';

@HiveType(typeId: 0)
class Driver {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int? age;

  @HiveField(3)
  final double? totalHoursRequired;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final bool goalCompletedShown;

  Driver({
    required this.id,
    required this.name,
    this.age,
    this.totalHoursRequired,
    this.notes,
    required this.createdAt,
    this.goalCompletedShown = false,
  });

  Driver copyWith({
    String? name,
    int? age,
    double? totalHoursRequired,
    String? notes,
    bool? goalCompletedShown,
  }) {
    return Driver(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      totalHoursRequired: totalHoursRequired ?? this.totalHoursRequired,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      goalCompletedShown: goalCompletedShown ?? this.goalCompletedShown,
    );
  }
}
