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
  String? _timeErrorMessage;

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
    
    // Initial async check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAvailability();
    });
  }

  String? _getTimeError(TimeOfDay time, {int? durationMinutes}) {
    final l10n = AppLocalizations.of(context);
    final startStr = widget.room.availability['startTime'] as String?;
    final endStr = widget.room.availability['endTime'] as String?;
    final minTime = _parseTime(startStr);
    final maxTime = _parseTime(endStr);

    double startDouble = time.hour + time.minute / 60.0;
    double? minDouble = minTime != null ? minTime.hour + minTime.minute / 60.0 : null;
    double? maxDouble = maxTime != null ? maxTime.hour + maxTime.minute / 60.0 : null;

    final availabilityRange = '${l10n.get('availability')}: ${startStr ?? 'N/A'} - ${endStr ?? 'N/A'}';

    if (minDouble != null && startDouble < minDouble) return availabilityRange;
    
    if (durationMinutes != null) {
      double endDouble = startDouble + (durationMinutes / 60.0);
      if (maxDouble != null && endDouble > maxDouble) return availabilityRange;
    } else {
      if (maxDouble != null && startDouble >= maxDouble) return availabilityRange;
    }

    // Prevent past reservations
    final now = DateTime.now();
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
    
    if (selectedDateTime.isBefore(now.subtract(const Duration(minutes: 1)))) {
      return l10n.get('timeInPast');
    }
    
    return null;
  }

  Future<void> _checkAvailability() async {
    final l10n = AppLocalizations.of(context);
    
    // 1. Basic time rules check
    String? basicError = _getTimeError(_startTime, durationMinutes: _durationMinutes);
    if (basicError != null) {
      setState(() {
        _timeErrorMessage = basicError;
      });
      return;
    }

    setState(() {
      _timeErrorMessage = null;
    });

    // 2. Async Overlap check
    try {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));

      final existingBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: widget.room.id)
          .get();

      for (var doc in existingBookings.docs) {
        final data = doc.data();
        final String status = (data['status'] as String).toLowerCase();
        if (status == 'cancelled' || status == 'declined' || status == 'completed') continue;

        final existingStart = (data['startTime'] as Timestamp).toDate();
        final existingEnd = (data['endTime'] as Timestamp).toDate();

        if (startDateTime.isBefore(existingEnd) && endDateTime.isAfter(existingStart)) {
          if (mounted) {
            setState(() {
              _timeErrorMessage = l10n.get('timeOverlap');
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking live availability: $e');
    }
  }

  @override
  void dispose() {
    _purposeController.dispose();
    super.dispose();
  }

  String _getLocalizedFloor(String floor, AppLocalizations l10n) {
    String f = floor.toLowerCase().replaceAll(' ', '');
    if (f.contains('ground')) return l10n.get('groundFloor');
    if (f.contains('1st')) return l10n.get('1stFloor');
    if (f.contains('2nd')) return l10n.get('2ndFloor');
    if (f.contains('3rd')) return l10n.get('3rdFloor');
    if (f.contains('4th')) return l10n.get('4thFloor');
    return floor;
  }

  String _formatDuration(int minutes, AppLocalizations l10n) {
    if (minutes < 60) return "$minutes ${l10n.get('mins')}";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    String hoursText =
        hours == 1 ? "1 ${l10n.get('hour')}" : "$hours ${l10n.get('hours')}";
    if (remainingMinutes == 0) return hoursText;
    return "$hoursText • $remainingMinutes ${l10n.get('mins')}";
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
    if (allowedDays.isNotEmpty && !allowedDays.contains(initialDate.weekday)) {
      initialDate = _getInitialDate(allowedDays);
    }

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
      _checkAvailability();
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
      });
      _checkAvailability();
    }
  }

  Future<void> _submitReservation() async {
    final l10n = AppLocalizations.of(context);
    
    // Final UI check
    if (_timeErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_timeErrorMessage!)),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _startTime.hour,
        _startTime.minute,
      );
      final endDateTime = startDateTime.add(Duration(minutes: _durationMinutes));

      final bool requiresApproval = widget.room.bookingRules['requiresApproval'] == true;
      final String status = requiresApproval ? 'pending' : 'approved';

      String userName = 'Unknown';
      String organization = 'None';

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            final data = userDoc.data()!;
            userName = data['name'] ?? user.displayName ?? 'Unknown';
            organization = data['organizationName'] ?? 'None';
          }
        }
      } catch (e) {
        debugPrint('Error fetching user details: $e');
      }

      // Re-verify overlap before final submission to be absolutely sure
      try {
        final existingBookings = await FirebaseFirestore.instance
            .collection('bookings')
            .where('roomId', isEqualTo: widget.room.id)
            .get();

        for (var doc in existingBookings.docs) {
          final data = doc.data();
          final String s = (data['status'] as String).toLowerCase();
          if (s == 'cancelled' || s == 'declined' || s == 'completed') continue;

          final existingStart = (data['startTime'] as Timestamp).toDate();
          final existingEnd = (data['endTime'] as Timestamp).toDate();

          if (startDateTime.isBefore(existingEnd) && endDateTime.isAfter(existingStart)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.get('timeOverlap'))),
              );
            }
            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking overlaps: $e');
      }

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
            'upcomingNotifSent': false,
          });
        }
      } catch (e) {
        debugPrint('Error inserting booking: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.get('failedToBook')}: $e')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.get('reservationConfirmed'))),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final int maxDuration = (widget.room.bookingRules['maxDurationMinutes'] as int?) ?? 1440;
    final List<int> durationOptions = [15, 30, 45, 60, 90, 120, 180, 240, 480]
        .where((d) => d <= maxDuration)
        .toList();

    if (!durationOptions.contains(_durationMinutes)) {
      if (_durationMinutes <= maxDuration) {
        durationOptions.add(_durationMinutes);
        durationOptions.sort();
      } else {
        _durationMinutes = durationOptions.isNotEmpty ? durationOptions.last : maxDuration;
        if (!durationOptions.contains(_durationMinutes)) {
          durationOptions.add(_durationMinutes);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  Expanded(
                    child: Text(
                      l10n.get('reserveRoom'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () => _showExistingReservations(context),
                    tooltip: l10n.get('existingReservations'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.meeting_room_rounded, color: colorScheme.primary, size: 30),
                            ),
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
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.room.building} • ${_getLocalizedFloor(widget.room.floor, l10n)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(title: l10n.get('date')),
                      const SizedBox(height: 5),
                      _SelectionTile(
                        label: l10n.get('selectDate'),
                        value: DateFormat('EEEE, MMM d, yyyy', locale).format(_selectedDate),
                        icon: Icons.calendar_today_rounded,
                        onTap: () => _selectDate(context),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(title: l10n.get('startTime')),
                      const SizedBox(height: 5),
                      _SelectionTile(
                        label: l10n.get('selectTime'),
                        value: DateFormat('h:mm a', locale).format(DateTime(2024, 1, 1, _startTime.hour, _startTime.minute)),
                        icon: Icons.access_time_rounded,
                        onTap: () => _selectTime(context),
                        errorText: _timeErrorMessage,
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(title: l10n.get('duration')),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<int>(
                            value: _durationMinutes,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              icon: Icon(Icons.timelapse_rounded, color: Colors.blueGrey),
                            ),
                            items: durationOptions.map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(_formatDuration(value, l10n)),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                _durationMinutes = newValue!;
                              });
                              _checkAvailability();
                            },
                            validator: (value) {
                              final min = widget.room.bookingRules['minDurationMinutes'] as int? ?? 0;
                              final max = widget.room.bookingRules['maxDurationMinutes'] as int? ?? 1440;
                              if (value! < min && min > 0) return 'Min: ${_formatDuration(min, l10n)}';
                              if (value > max && max > 0) return 'Max: ${_formatDuration(max, l10n)}';
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionHeader(title: l10n.get('purpose')),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _purposeController,
                        maxLines: 3,
                        maxLength: 50,
                        decoration: InputDecoration(
                          hintText: l10n.get('meetingWorkshop'),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.get('enterPurpose');
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.get('confirmReservation'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExistingReservations(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.get('existingReservations'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _buildExistingReservationsList(scrollController, l10n),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildExistingReservationsList(ScrollController scrollController, AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('roomId', isEqualTo: widget.room.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(l10n.get('somethingWentWrong')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final now = DateTime.now();
        final validBookings = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final String status = (data['status'] as String).toLowerCase();
          // Exclude cancelled, declined, and completed bookings.
          if (status == 'cancelled' || status == 'declined' || status == 'completed') return false;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade200),
                const SizedBox(height: 16),
                Text(l10n.get('noUpcomingReservations'),
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: validBookings.length,
          itemBuilder: (context, index) {
            final data = validBookings[index].data() as Map<String, dynamic>;
            final start = (data['startTime'] as Timestamp).toDate();
            final end = (data['endTime'] as Timestamp).toDate();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.access_time_filled_rounded, color: Colors.blueGrey, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d', locale).format(start),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('h:mm a', locale).format(start)} - ${DateFormat('h:mm a', locale).format(end)}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;

  const _SelectionTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null ? Colors.red.shade200 : Colors.grey.shade200,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blueGrey, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              errorText!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
