import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final List<int> allowedDays = (widget.room
        .availability['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];
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
    final minDuration = (widget.room
        .bookingRules['minDurationMinutes'] as int?) ?? 30;
    _durationMinutes = minDuration > 0 ? minDuration : 30;
  }

  bool _isTimeValid(TimeOfDay time) {
    final startStr = widget.room.availability['startTime'] as String?;
    final endStr = widget.room.availability['endTime'] as String?;
    final minTime = _parseTime(startStr);
    final maxTime = _parseTime(endStr);

    double pickedDouble = time.hour + time.minute / 60.0;
    double? minDouble = minTime != null
        ? minTime.hour + minTime.minute / 60.0
        : null;
    double? maxDouble = maxTime != null
        ? maxTime.hour + maxTime.minute / 60.0
        : null;

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
    final int advanceDays = (widget.room
        .bookingRules['advanceBookingDays'] as int?) ?? 365;
    final DateTime lastDate = DateTime.now().add(Duration(days: advanceDays));
    final List<int> allowedDays = (widget.room
        .availability['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];

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

  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      // Final availability check
      if (!_isTimeValid(_startTime)) {
        final startStr = widget.room.availability['startTime'] as String? ??
            'N/A';
        final endStr = widget.room.availability['endTime'] as String? ?? 'N/A';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Selected time is outside availability ($startStr - $endStr)')),
        );
        return;
      }

      final List<int> allowedDays = (widget.room
          .availability['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];
      if (allowedDays.isNotEmpty &&
          !allowedDays.contains(_selectedDate.weekday)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Selected date is not available for this room')),
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
      final endDateTime = startDateTime.add(
          Duration(minutes: _durationMinutes));

      // Determine Status
      final bool requiresApproval = widget.room
          .bookingRules['requiresApproval'] == true;
      final String status = requiresApproval ? 'Pending' : 'Approved';

      // Fetch User Details
      String userName = 'Unknown';
      String organization = 'None';
      String createdAt = 'N/A';
      String updatedAt = 'N/A';

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users')
              .doc(user.uid)
              .get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            userName = data['name'] ?? user.displayName ?? 'Unknown';
            organization = data['organizationName'] ?? 'None';
            createdAt =
                (data['createdAt'] as Timestamp?)?.toDate().toString() ?? 'N/A';
            updatedAt =
                (data['updatedAt'] as Timestamp?)?.toDate().toString() ?? 'N/A';
          }
        }
      } catch (e) {
        debugPrint('Error fetching user details: $e');
      }

      // Log details
      debugPrint('--- Reservation Details ---');
      debugPrint('Room: ${widget.room.name}');
      debugPrint('Building: ${widget.room.building}');
      debugPrint('Floor: ${widget.room.floor}');
      debugPrint('Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}');
      debugPrint('Start Time: ${_startTime.format(context)}');
      debugPrint('Duration: $_durationMinutes minutes');
      debugPrint('End Time: ${DateFormat('HH:mm').format(endDateTime)}');
      debugPrint('Purpose: ${_purposeController.text}');
      debugPrint('Status: $status');
      debugPrint('User: $userName');
      debugPrint('Organization: $organization');
      debugPrint('User CreatedAt: $createdAt');
      debugPrint('User UpdatedAt: $updatedAt');
      debugPrint('---------------------------');

      // Check for overlapping reservations
      try {
        final startOfDay = DateTime(
            startDateTime.year, startDateTime.month, startDateTime.day);
        final endOfDay = DateTime(
            startDateTime.year, startDateTime.month, startDateTime.day, 23, 59,
            59);

        // Query only by roomId to avoid composite index requirement
        final existingBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('roomId', isEqualTo: widget.room.id)
            .get();

        for (var doc in existingBookings.docs) {
          final data = doc.data();
          if (data['status'] == 'cancelled' || data['status'] == 'rejected')
            continue;

          final existingStart = (data['startTime'] as Timestamp).toDate();
          final existingEnd = (data['endTime'] as Timestamp).toDate();

          // Filter by date first (client-side)
          if (existingStart.isBefore(startOfDay) ||
              existingStart.isAfter(endOfDay)) {
            // If multi-day bookings are allowed, this logic needs to be more complex.
            // Assuming single-day bookings for now based on current UI.
            // If not, we just check overlap directly.
            // Let's just check overlap directly for robustness against any date.
          }

          // Overlap check: (StartA < EndB) && (EndA > StartB)
          // Use isBefore/isAfter logic strictly.
          // Note: isBefore is exclusive. 9:00 is not before 9:00.
          // New: 9:01 - 10:00. Existing: 7:30 - 9:00.
          // StartA (9:01) < EndB (9:00) -> False. No overlap.
          // New: 9:00 - 10:00. Existing: 7:30 - 9:00.
          // StartA (9:00) < EndB (9:00) -> False. No overlap.

          if (startDateTime.isBefore(existingEnd) &&
              endDateTime.isAfter(existingStart)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Room already reserved for this time')),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking overlaps: $e');
        // Optionally handle error, maybe proceed or block. Blocking is safer.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error checking availability: $e')),
          );
        }
        return;
      }

      // Insert into Firestore
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('bookings').add({
            'roomId': widget.room.id,
            'roomName': widget.room.name,
            'building': widget.room.building,
            'floor': widget.room.floor,
            'userId': user.uid,
            'userName': userName,
            'organizationName': organization,
            'startTime': Timestamp.fromDate(startDateTime),
            'endTime': Timestamp.fromDate(endDateTime),
            'durationMinutes': _durationMinutes,
            'purpose': _purposeController.text,
            'status': status,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('Error inserting booking: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to book room: $e')),
          );
        }
        return; // Don't close page if failed
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation Confirmed')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    // Build duration items
    final int maxDuration = (widget.room
        .bookingRules['maxDurationMinutes'] as int?) ?? 1440;
    final List<int> durationOptions = [15, 30, 45, 60, 90, 120, 180, 240, 480]
        .where((d) => d <= maxDuration)
        .toList();

    if (!durationOptions.contains(_durationMinutes)) {
      if (_durationMinutes <= maxDuration) {
        durationOptions.add(_durationMinutes);
        durationOptions.sort();
      } else {
        // Fallback if current duration exceeds max (shouldn't happen with init logic but safe)
        _durationMinutes =
        durationOptions.isNotEmpty ? durationOptions.last : maxDuration;
        if (!durationOptions.contains(_durationMinutes)) {
          durationOptions.add(_durationMinutes);
        }
      }
    }

    // Advance Booking Info
    final int advanceDays = (widget.room
        .bookingRules['advanceBookingDays'] as int?) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserve Room'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _showExistingReservations(context),
            tooltip: 'View Existing Reservations',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                          Icon(Icons.meeting_room, color: colorScheme.primary,
                              size: 40),
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
                    Text('Date', style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
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
                    Text('Start Time', style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.access_time),
                          errorText: _timeError ? 'Available: ${widget.room
                              .availability['startTime'] ?? 'N/A'} - ${widget.room
                              .availability['endTime'] ?? 'N/A'}' : null,
                        ),
                        child: Text(_startTime.format(context)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Duration
                    Text('Duration', style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
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
                        final min = widget.room
                            .bookingRules['minDurationMinutes'] as int? ?? 0;
                        final max = widget.room
                            .bookingRules['maxDurationMinutes'] as int? ?? 1440;
                        if (value! < min && min > 0)
                          return 'Minimum duration is ${_formatDuration(min)}';
                        if (value > max && max > 0)
                          return 'Maximum duration is ${_formatDuration(max)}';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Purpose
                    Text('Purpose', style: Theme
                        .of(context)
                        .textTheme
                        .titleMedium),
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
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Container for Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
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
            ),
          ),
        ],
      ),
    );
  }

    void _showExistingReservations(BuildContext context) {

      showModalBottomSheet(

        context: context,

        isScrollControlled: true,

        shape: const RoundedRectangleBorder(

          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

        ),

        builder: (context) {

          return DraggableScrollableSheet(

            initialChildSize: 0.6,

            minChildSize: 0.4,

            maxChildSize: 0.9,

            expand: false,

            builder: (context, scrollController) {

              return Padding(

                padding: const EdgeInsets.all(20.0),

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    const Text(

                      'Existing Reservations',

                      style: TextStyle(

                        fontSize: 20,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const SizedBox(height: 16),

                    Expanded(

                      child: _buildExistingReservationsList(scrollController),

                    ),

                  ],

                ),

              );

            },

          );

        },

      );

    }

  

    Widget _buildExistingReservationsList(ScrollController scrollController) {

      return StreamBuilder<QuerySnapshot>(

        stream: FirebaseFirestore.instance

            .collection('bookings')

            .where('roomId', isEqualTo: widget.room.id)

            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {

            return const Text('Error loading reservations');

          }

  

          if (snapshot.connectionState == ConnectionState.waiting) {

            return const Center(child: CircularProgressIndicator());

          }

  

          final docs = snapshot.data?.docs ?? [];

          

          // Filter and sort client-side

          final now = DateTime.now();

          final validBookings = docs.where((doc) {

            final data = doc.data() as Map<String, dynamic>;

            if (data['status'] == 'cancelled' || data['status'] == 'rejected') return false;

            

            final endTimestamp = data['endTime'] as Timestamp?;

            if (endTimestamp == null) return false;

            

            return endTimestamp.toDate().isAfter(now); 

          }).toList();

  

          validBookings.sort((a, b) {

            final startA = (a['startTime'] as Timestamp).toDate();

            final startB = (b['startTime'] as Timestamp).toDate();

            return startA.compareTo(startB);

          });

  

          if (validBookings.isEmpty) {

            return const Center(

              child: Text('No upcoming reservations found.', style: TextStyle(color: Colors.grey)),

            );

          }

  

          return ListView.builder(

            controller: scrollController,

            itemCount: validBookings.length,

            itemBuilder: (context, index) {

              final data = validBookings[index].data() as Map<String, dynamic>;

              final start = (data['startTime'] as Timestamp).toDate();

              final end = (data['endTime'] as Timestamp).toDate();

  

              return Card(

                margin: const EdgeInsets.only(bottom: 12),

                elevation: 0,

                color: Colors.grey.shade100,

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                child: ListTile(

                  leading: const Icon(Icons.access_time_rounded, color: Colors.blueGrey),

                  title: Text(

                    DateFormat('EEEE, MMM d').format(start),

                    style: const TextStyle(fontWeight: FontWeight.w600),

                  ),

                  subtitle: Text(

                    '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',

                    style: TextStyle(color: Colors.grey.shade700),

                  ),

                ),

              );

            },

          );

        },

      );

    }
}