import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'Rooms_Page.dart'; // For Room model

class ReservePage extends StatefulWidget {
  final Room room;

  const ReservePage({super.key, required this.room});

  @override
  State<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late int _durationMinutes;
  final TextEditingController _purposeController = TextEditingController();
  bool _timeError = false;

  @override
  void initState() {
    super.initState();
    // 1. Initialize Date: Find first valid date
    final List<int> allowedDays = (widget.room.availability['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];
    _selectedDate = _getInitialDate(allowedDays);

    // 2. Initialize Time: Check against min/max
    final startStr = widget.room.availability['startTime'] as String?;
    final minTime = _parseTime(startStr);
    
    // Default to current time or minTime if current is too early
    TimeOfDay initialTime = TimeOfDay.now();
    if (minTime != null) {
       double currentDouble = initialTime.hour + initialTime.minute / 60.0;
       double minDouble = minTime.hour + minTime.minute / 60.0;
       if (currentDouble < minDouble) {
         initialTime = minTime;
       }
    }
    _startTime = initialTime;
    
    // Default duration setup
    final minDuration = (widget.room.bookingRules['minDurationMinutes'] as int?) ?? 30;
    _durationMinutes = minDuration > 0 ? minDuration : 30;
  }

  bool _isTimeValid(TimeOfDay time) {
      final startStr = widget.room.availability['startTime'] as String?;
      final endStr = widget.room.availability['endTime'] as String?;
      final minTime = _parseTime(startStr);
      final maxTime = _parseTime(endStr);
      
      double pickedDouble = time.hour + time.minute / 60.0;
      double? minDouble = minTime != null ? minTime.hour + minTime.minute / 60.0 : null;
      double? maxDouble = maxTime != null ? maxTime.hour + maxTime.minute / 60.0 : null;

      if (minDouble != null && pickedDouble < minDouble) return false;
      if (maxDouble != null && pickedDouble > maxDouble) return false;
      return true;
  }

  // ... (dispose, _formatDuration, _parseTime, _getInitialDate remain same)

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return "${minutes}mins";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    String hoursText = hours == 1 ? "1hr" : "${hours}hrs";
    if (remainingMinutes == 0) return hoursText;
    return "$hoursText • ${remainingMinutes}mins";
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || timeStr == 'N/A') return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].split(' ')[0]);
        if (timeStr.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      debugPrint('Error parsing time: $e');
    }
    return null;
  }

  DateTime _getInitialDate(List<int> allowedDays) {
    DateTime date = DateTime.now();
    if (allowedDays.isEmpty) return date;
    int attempts = 0;
    while (!allowedDays.contains(date.weekday) && attempts < 365) {
      date = date.add(const Duration(days: 1));
      attempts++;
    }
    return date;
  }

  Future<void> _selectDate(BuildContext context) async {
    final int advanceDays = (widget.room.bookingRules['advanceBookingDays'] as int?) ?? 365;
    final DateTime lastDate = DateTime.now().add(Duration(days: advanceDays));
    final List<int> allowedDays = (widget.room.availability['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];

    DateTime initialDate = _selectedDate;
    // Check if current _selectedDate is valid (it should be from init, but good to be safe)
    if (allowedDays.isNotEmpty && !allowedDays.contains(initialDate.weekday)) {
       initialDate = _getInitialDate(allowedDays);
    }
    
    // Ensure initialDate is within range
    if (initialDate.isAfter(lastDate)) {
       initialDate = lastDate; 
    } else if (initialDate.isBefore(DateTime.now())) {
       initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: lastDate,
      selectableDayPredicate: (DateTime day) {
        if (allowedDays.isEmpty) return true;
        return allowedDays.contains(day.weekday);
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _timeError = !_isTimeValid(picked);
      });
    }
  }

  void _submitReservation() {
    if (_formKey.currentState!.validate()) {
      // Final availability check
      if (!_isTimeValid(_startTime)) {
          final startStr = widget.room.availability['startTime'] as String? ?? 'N/A';
          final endStr = widget.room.availability['endTime'] as String? ?? 'N/A';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected time is outside availability ($startStr - $endStr)')),
          );
          return;
      }
      
      final List<int> allowedDays = (widget.room.availability['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];
      if (allowedDays.isNotEmpty && !allowedDays.contains(_selectedDate.weekday)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected date is not available for this room')),
          );
          return;
      }

      // Calculate End Time
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));
      
      // Determine Status
      final bool requiresApproval = widget.room.bookingRules['requiresApproval'] == true;
      final String status = requiresApproval ? 'Pending' : 'Approved';

      // Log details
      debugPrint('--- Reservation Details ---');
      debugPrint('Room: ${widget.room.name}');
      debugPrint('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      debugPrint('Start Time: ${_startTime.format(context)}');
      debugPrint('Duration: $_durationMinutes minutes');
      debugPrint('End Time: ${DateFormat('HH:mm').format(endDateTime)}');
      debugPrint('Purpose: ${_purposeController.text}');
      debugPrint('Status: $status');
      debugPrint('---------------------------');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation Confirmed (Logged to Console)')),
      );
      
      // Navigate back or to a success page
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    // Build duration items
    final int maxDuration = (widget.room.bookingRules['maxDurationMinutes'] as int?) ?? 1440;
    final List<int> durationOptions = [15, 30, 45, 60, 90, 120, 180, 240, 480]
        .where((d) => d <= maxDuration)
        .toList();
        
    if (!durationOptions.contains(_durationMinutes)) {
      if (_durationMinutes <= maxDuration) {
        durationOptions.add(_durationMinutes);
        durationOptions.sort();
      } else {
         // Fallback if current duration exceeds max (shouldn't happen with init logic but safe)
         _durationMinutes = durationOptions.isNotEmpty ? durationOptions.last : maxDuration;
         if (!durationOptions.contains(_durationMinutes)) {
            durationOptions.add(_durationMinutes);
         }
      }
    }

    // Advance Booking Info
    final int advanceDays = (widget.room.bookingRules['advanceBookingDays'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Room'), 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.meeting_room, color: colorScheme.primary, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.room.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.room.building} • ${widget.room.floor}',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date Picker
              Text('Date', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 20),

              // Time Picker
              Text('Start Time', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.access_time),
                    errorText: _timeError ? 'Available: ${widget.room.availability['startTime'] ?? 'N/A'} - ${widget.room.availability['endTime'] ?? 'N/A'}' : null,
                  ),
                  child: Text(_startTime.format(context)),
                ),
              ),
              const SizedBox(height: 20),

              // Duration
              Text('Duration', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _durationMinutes,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: durationOptions.map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(_formatDuration(value)),
                  );
                }).toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    _durationMinutes = newValue!;
                  });
                },
                validator: (value) {
                   final min = widget.room.bookingRules['minDurationMinutes'] as int? ?? 0;
                   final max = widget.room.bookingRules['maxDurationMinutes'] as int? ?? 1440;
                   if (value! < min && min > 0) return 'Minimum duration is ${_formatDuration(min)}';
                   if (value > max && max > 0) return 'Maximum duration is ${_formatDuration(max)}';
                   return null;
                },
              ),
              const SizedBox(height: 20),

              // Purpose
              Text('Purpose', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _purposeController,
                decoration: const InputDecoration(
                  hintText: 'Meeting, Workshop, etc.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a purpose';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Reservation',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}