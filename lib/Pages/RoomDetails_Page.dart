import 'package:flutter/material.dart';
import 'package:ntp/ntp.dart';
import 'package:intl/intl.dart';
import 'Rooms_Page.dart'; // Import to access the Room and RoomTag classes
import 'Reserve_Page.dart';
import '../l10n/app_localizations.dart';

class RoomDetailsPage extends StatefulWidget {
  final Room room;

  const RoomDetailsPage({super.key, required this.room});

  @override
  State<RoomDetailsPage> createState() => _RoomDetailsPageState();
}

class _RoomDetailsPageState extends State<RoomDetailsPage> {
  bool _isDescriptionExpanded = false;
  late DateTime _now;
  bool _isOnlineTime = false;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _syncTime();
  }

  Future<void> _syncTime() async {
    try {
      final ntpTime = await NTP.now();
      if (mounted) {
        setState(() {
          _now = ntpTime;
          _isOnlineTime = true;
        });
      }
    } catch (e) {
      debugPrint('NTP sync failed: $e');
    }
  }

  String _formatDuration(int minutes, AppLocalizations l10n) {
    if (minutes < 60) return "$minutes mins";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    String hoursText = hours == 1 ? "1hr" : "${hours}hrs";
    if (remainingMinutes == 0) return hoursText;
    return "$hoursText • ${remainingMinutes}mins";
  }

  String _getDayName(int day, BuildContext context) {
    final date = DateTime(2024, 1, day);
    final locale = Localizations.localeOf(context).languageCode;
    return DateFormat('EEE', locale).format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final room = widget.room;
    final colorScheme = Theme.of(context).colorScheme;
    final isAvailable = room.isAvailable;
    final statusColor = isAvailable ? Colors.green : Colors.red;
    final statusText = isAvailable ? l10n.get('available') : l10n.get('occupied');

    final avail = room.availability;
    final startTime = avail['startTime'] as String? ?? 'N/A';
    final endTime = avail['endTime'] as String? ?? 'N/A';
    final daysList = (avail['daysOfWeek'] as List<dynamic>?)?.cast<int>() ?? [];
    final daysString = daysList.map((d) => _getDayName(d, context)).join(' • ');

    final rules = room.bookingRules;
    final minDuration = rules['minDurationMinutes'] ?? 0;
    final maxDuration = rules['maxDurationMinutes'] ?? 0;
    final advanceDays = rules['advanceBookingDays'] ?? 0;
    final requiresApproval = rules['requiresApproval'] == true;

    final bool isDescriptionLong = room.description.length > 120;
    final String displayDescription = !_isDescriptionExpanded && isDescriptionLong 
        ? "${room.description.substring(0, 110)}..." 
        : room.description;

    final locale = Localizations.localeOf(context).toString();
    final formattedDate = DateFormat('EEEE, MMM d • HH:mm', locale).format(_now);

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
                      room.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.15),
                            colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.meeting_room_rounded,
                          size: 80,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.1),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 22,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary.withOpacity(0.8),
                              ),
                            ),
                          ),
                          if (_isOnlineTime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.get('live'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                room.name,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  capitalizeFirst(room.type),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvailable ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (room.description.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: isDescriptionLong ? () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        } : null,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade700,
                              height: 1.6,
                              fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
                            ),
                            children: [
                              TextSpan(text: displayDescription),
                              if (isDescriptionLong)
                                TextSpan(
                                  text: _isDescriptionExpanded ? " ${l10n.get('seeLess')}" : " ${l10n.get('seeMore')}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    _SectionHeader(title: l10n.get('info')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _InfoItem(
                              icon: Icons.business_rounded,
                              label: l10n.get('building'),
                              value: room.building,
                            ),
                            VerticalDivider(width: 30, color: Colors.grey.shade200),
                            _InfoItem(
                              icon: Icons.layers_rounded,
                              label: l10n.get('floor'),
                              value: room.floor,
                            ),
                            VerticalDivider(width: 30, color: Colors.grey.shade200),
                            _InfoItem(
                              icon: Icons.people_outline_rounded,
                              label: l10n.get('capacity'),
                              value: "${room.capacity}",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(title: l10n.get('availability')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.access_time_filled_rounded, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  "$startTime - $endTime",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (daysString.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Divider(height: 1, color: Colors.grey.shade100),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calendar_month_rounded, color: Colors.purple, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    daysString,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(title: l10n.get('bookingRules')),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _RuleRow(label: l10n.get('minDuration'), value: _formatDuration(minDuration, l10n)),
                          Divider(color: Colors.grey.shade100),
                          _RuleRow(label: l10n.get('maxDuration'), value: _formatDuration(maxDuration, l10n)),
                          Divider(color: Colors.grey.shade100),
                          _RuleRow(label: l10n.get('advanceBooking'), value: "$advanceDays ${l10n.get('days')}"),
                          Divider(color: Colors.grey.shade100),
                          _RuleRow(
                            label: l10n.get('approvalRequired'),
                            value: requiresApproval ? l10n.get('yes') : l10n.get('no'),
                            valueColor: requiresApproval ? Colors.orange.shade700 : Colors.green.shade600,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (room.tags.isNotEmpty) ...[
                      _SectionHeader(title: l10n.get('features')),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: room.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(tag.icon, size: 16, color: Colors.grey.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  tag.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
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
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isAvailable
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReservePage(room: room),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isAvailable ? l10n.get('reserveRoom') : l10n.get('currentlyUnavailable'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blueGrey, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _RuleRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}