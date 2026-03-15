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
  late Stream<QuerySnapshot> _existingBookingsStream;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _existingBookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('roomId', isEqualTo: widget.room.id)
        .snapshots();

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
    return l10n.getFloor(floor);
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
        SnackBar(
          content: Text(_timeErrorMessage!, textAlign: TextAlign.center),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

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
              setState(() {
                _isSubmitting = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.get('timeOverlap'), textAlign: TextAlign.center),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                ),
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
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.get('failedToBook')}: $e', textAlign: TextAlign.center),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('reservationConfirmed'), textAlign: TextAlign.center),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          ),
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

    final int minDuration = (widget.room.bookingRules['minDurationMinutes'] as int?) ?? 30;
    final int maxDuration = (widget.room.bookingRules['maxDurationMinutes'] as int?) ?? 1440;

    // Build duration options starting at min and ending at max
    final List<int> standardIntervals = [15, 30, 45, 60, 90, 120, 180, 240, 480, 720, 1440];
    final List<int> durationOptions = standardIntervals
        .where((d) => d > minDuration && d < maxDuration)
        .toList();

    // Add boundaries
    if (!durationOptions.contains(minDuration)) durationOptions.add(minDuration);
    if (!durationOptions.contains(maxDuration) && maxDuration >= minDuration) {
      durationOptions.add(maxDuration);
    }
    durationOptions.sort();

    // Ensure current selection is valid
    if (!durationOptions.contains(_durationMinutes)) {
      if (_durationMinutes < minDuration) {
        _durationMinutes = minDuration;
      } else if (_durationMinutes > maxDuration) {
        _durationMinutes = maxDuration;
      } else {
        // If it's in between but not in list, add it to avoid dropdown error
        durationOptions.add(_durationMinutes);
        durationOptions.sort();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Room Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                image: widget.room.photoURL != null && widget.room.photoURL!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(widget.room.photoURL!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: widget.room.photoURL == null || widget.room.photoURL!.isEmpty
                                  ? Icon(Icons.meeting_room_rounded, color: colorScheme.primary, size: 32)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.room.name,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: colorScheme.primary.withValues(alpha: 0.7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.room.building} • ${_getLocalizedFloor(widget.room.floor, l10n)}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.people_alt_rounded, size: 14, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${l10n.get('capacity')}: ${widget.room.capacity}',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Date Selection
                      _SectionHeader(title: l10n.get('date'), icon: Icons.calendar_today_rounded),
                      const SizedBox(height: 10),
                      _SelectionTile(
                        label: l10n.get('selectDate'),
                        value: DateFormat('EEEE, MMM d, yyyy', locale).format(_selectedDate),
                        onTap: () => _selectDate(context),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Time Selection
                      _SectionHeader(title: l10n.get('startTime'), icon: Icons.access_time_rounded),
                      const SizedBox(height: 10),
                      _SelectionTile(
                        label: l10n.get('selectTime'),
                        value: DateFormat('h:mm a', locale).format(DateTime(2024, 1, 1, _startTime.hour, _startTime.minute)),
                        onTap: () => _selectTime(context),
                        errorText: _timeErrorMessage,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Duration Selection
                      _SectionHeader(title: l10n.get('duration'), icon: Icons.timelapse_rounded),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: durationOptions.map((int value) {
                          final isSelected = _durationMinutes == value;
                          return ChoiceChip(
                            label: Text(_formatDuration(value, l10n)),
                            selected: isSelected,
                            onSelected: (bool selected) {
                              if (selected) {
                                setState(() {
                                  _durationMinutes = value;
                                });
                                _checkAvailability();
                              }
                            },
                            backgroundColor: Colors.white,
                            selectedColor: colorScheme.primary.withValues(alpha: 0.15),
                            checkmarkColor: colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? colorScheme.primary : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? colorScheme.primary : Colors.grey.shade200,
                                width: 1,
                              ),
                            ),
                            elevation: isSelected ? 2 : 0,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          );
                        }).toList(),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Purpose Input
                      _SectionHeader(title: l10n.get('purpose'), icon: Icons.description_rounded),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _purposeController,
                        maxLines: 3,
                        maxLength: 50,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: l10n.get('meetingWorkshop'),
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.all(18),
                          counterStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: colorScheme.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(color: Colors.red.shade200),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.get('enterPurpose');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            // Bottom Action Button
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
                  onPressed: _isSubmitting ? null : _submitReservation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
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
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        fontSize: 18,
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
      stream: _existingBookingsStream,
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
          physics: const ClampingScrollPhysics(),
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
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.grey.shade500,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final String? errorText;

  const _SelectionTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: errorText != null ? Colors.red.shade200 : Colors.grey.shade200,
                  width: errorText != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right_rounded, color: colorScheme.primary, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: Colors.red.shade700),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorText!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
