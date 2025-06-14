import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hive/hive.dart';
import '../models/driving_session.dart';
import '../utils/date_formatter.dart';

class DrivingCalendar extends StatefulWidget {
  final String driverId;
  final List<DrivingSession> sessions;
  final Function(DateTime) onDaySelected;

  const DrivingCalendar({
    Key? key,
    required this.driverId,
    required this.sessions,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<DrivingCalendar> createState() => _DrivingCalendarState();
}

class _DrivingCalendarState extends State<DrivingCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  final Set<DateTime> _markedDates = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _updateMarkedDates();
  }

  void _updateMarkedDates() {
    _markedDates.clear();
    for (var session in widget.sessions) {
      // Add the date part only (without time)
      final date = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
      );
      _markedDates.add(date);
    }
  }

  @override
  void didUpdateWidget(DrivingCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessions != widget.sessions) {
      _updateMarkedDates();
    }
  }

  bool _isLoggedDay(DateTime day) {
    return _markedDates.any((d) => isSameDay(d, day));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2000),
              lastDay: DateTime(2100),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              enabledDayPredicate: (day) {
                // Only allow selecting days with logs
                return _isLoggedDay(day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                if (_isLoggedDay(selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  widget.onDaySelected(selectedDay);
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                // Remove default today styling
                todayDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                // Style for selected day (must be a logged day)
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                // Style for days with logs
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                // Text style for today
                todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                // Text style for selected day
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                // Text style for days with logs
                defaultTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                // Text style for enabled days (with logs)
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                // Text style for disabled days (no logs)
                disabledTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
                titleTextFormatter: (date, locale) => DateFormatter.formatDateForDisplay(date),
              ),
              calendarBuilders: CalendarBuilders(
                // Custom day builder to show "Today" text and log indicators
                defaultBuilder: (context, day, focusedDay) {
                  final isToday = isSameDay(day, DateTime.now());
                  final hasSession = _markedDates.any((date) => isSameDay(date, day));
                  final isSelected = isSameDay(_selectedDay, day);

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Show "Today" text if it's today
                      if (isToday)
                        Positioned(
                          bottom: 2,
                          child: Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 8,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // Date text
                      Text(
                        DateFormatter.formatDay(day),
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? Theme.of(context).colorScheme.primary
                                  : hasSession
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                          fontWeight: isToday || hasSession ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  );
                },
                // Apply the same styling to other day types
                todayBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, true, _isLoggedDay(day));
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, isSameDay(day, today), true);
                },
                disabledBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, isSameDay(day, today), false);
                },
                outsideBuilder: (context, day, focusedDay) {
                  return _buildDayCell(context, day, isSameDay(day, today), false);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDayCell(BuildContext context, DateTime day, bool isToday, bool hasLogs) {
    final isSelected = isSameDay(_selectedDay, day);
    
    return GestureDetector(
      onTap: hasLogs 
          ? () {
              setState(() {
                _selectedDay = day;
                _focusedDay = day;
              });
              widget.onDaySelected(day);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
              : (hasLogs 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : null),
          borderRadius: BorderRadius.circular(8.0),
          border: isToday
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormatter.formatDay(day),
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (hasLogs 
                          ? Theme.of(context).colorScheme.onSurface 
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  fontSize: isToday ? 16 : 14,
                ),
              ),
              if (isToday)
                Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 8,
                    color: isSelected 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
