import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import 'Booked_Page.dart';
import 'Rooms_Page.dart';

class BookedDetailsPage extends StatefulWidget {
  final Booking booking;

  const BookedDetailsPage({super.key, required this.booking});

  @override
  State<BookedDetailsPage> createState() => _BookedDetailsPageState();
}

class _BookedDetailsPageState extends State<BookedDetailsPage> {
  bool _isRoomDescriptionExpanded = false;
  bool _isFeaturesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

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
                      l10n.get('bookingDetails'),
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
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(widget.booking.roomId)
                    .snapshots(),
                builder: (context, snapshot) {
                  Room? room;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    room = Room.fromFirestore(snapshot.data!);
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20,20,20,0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(l10n.get('bookingStatus')),
                        const SizedBox(height: 12),
                        _buildStatusCard(widget.booking, l10n),
                        
                        const SizedBox(height: 24),
                        _buildSectionHeader(l10n.get('bookingDetails')),
                        const SizedBox(height: 12),
                        _buildReservationInfo(widget.booking, l10n, locale),

                        const SizedBox(height: 24),
                        _buildSectionHeader(l10n.get('roomDetails')),
                        const SizedBox(height: 12),
                        if (room != null) 
                          _buildRoomInfo(room, l10n, locale)
                        else if (snapshot.connectionState == ConnectionState.waiting)
                          const Center(child: CircularProgressIndicator())
                        else
                          _buildMinimalRoomInfo(widget.booking, l10n),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildStatusCard(Booking booking, AppLocalizations l10n) {
    final statusColor = _getStatusColor(booking.status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getStatusIcon(booking.status), color: statusColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get(booking.status.toLowerCase()),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationInfo(Booking booking, AppLocalizations l10n, String locale) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today_rounded, l10n.get('date'), DateFormat('EEEE, MMM d, yyyy', locale).format(booking.startTime)),
          const Divider(height: 24),
          _buildDetailRow(Icons.access_time_rounded, l10n.get('startTimeEnd'), '${DateFormat('hh:mm a', locale).format(booking.startTime)} - ${DateFormat('hh:mm a', locale).format(booking.endTime)}'),
          const Divider(height: 24),
          _buildDetailRow(Icons.timelapse_rounded, l10n.get('totalDuration'), _formatDuration(booking.durationMinutes, l10n)),
          const Divider(height: 24),
          
          // Purpose - 1 line ellipse
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.bookmark_outline_rounded, size: 20, color: Colors.blueGrey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.get('purpose'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      booking.purpose,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24),
          _buildDetailRow(Icons.history_rounded, l10n.get('requestDate'), DateFormat('MMM d, yyyy • hh:mm a', locale).format(booking.createdAt)),
        ],
      ),
    );
  }

  Widget _buildRoomInfo(Room room, AppLocalizations l10n, String locale) {
    final bool isDescriptionLong = room.description.length > 160;
    final String displayDescription = !_isRoomDescriptionExpanded && isDescriptionLong 
        ? "${room.description.substring(0, 150)}..." 
        : room.description;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              image: room.photoURL != null && room.photoURL!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(room.photoURL!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: room.photoURL == null || room.photoURL!.isEmpty
                ? Icon(Icons.meeting_room_rounded, color: colorScheme.primary, size: 48)
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            room.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${room.building} • ${_getLocalizedFloor(room.floor, l10n)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const Divider(height: 32),
          _buildDetailRow(Icons.category_outlined, l10n.get('type'), _getLocalizedRoomType(room.type, l10n)),
          const Divider(height: 24),
          _buildDetailRow(Icons.people_outline_rounded, l10n.get('capacity'), '${room.capacity}'),
          const Divider(height: 24),
          _buildDetailRow(Icons.access_time_filled_rounded, l10n.get('availability'), '${_formatTo12h(room.availability['startTime'], locale)} - ${_formatTo12h(room.availability['endTime'], locale)}'),
          if (room.description.isNotEmpty) ...[
            const Divider(height: 32),
            Text(
              l10n.get('info'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: isDescriptionLong ? () {
                setState(() {
                  _isRoomDescriptionExpanded = !_isRoomDescriptionExpanded;
                });
              } : null,
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.grey.shade700, height: 1.5, fontSize: 14, fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily),
                  children: [
                    TextSpan(text: displayDescription),
                    if (isDescriptionLong)
                      TextSpan(
                        text: _isRoomDescriptionExpanded ? " ${l10n.get('seeLess')}" : " ${l10n.get('seeMore')}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (room.tags.isNotEmpty) ...[
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.get('features'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (room.tags.length > 4)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isFeaturesExpanded = !_isFeaturesExpanded;
                      });
                    },
                    child: Text(
                      _isFeaturesExpanded ? l10n.get('seeLess') : l10n.get('seeMore'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_isFeaturesExpanded ? room.tags : room.tags.take(4))
                  .map((tag) => _buildFeatureChip(tag, l10n))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinimalRoomInfo(Booking booking, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking.roomName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.building} • ${_getLocalizedFloor(booking.floor, l10n)}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey.shade400),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureChip(RoomTag tag, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(tag.icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(
            l10n.getFeature(tag.label),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int minutes, AppLocalizations l10n) {
    if (minutes < 60) return "$minutes ${l10n.get('mins')}";
    int hours = minutes ~/ 60;
    int remainingMinutes = minutes % 60;
    String hoursText = hours == 1 ? "1 ${l10n.get('hour')}" : "$hours ${l10n.get('hours')}";
    if (remainingMinutes == 0) return hoursText;
    return "$hoursText • $remainingMinutes ${l10n.get('mins')}";
  }

  String _getLocalizedFloor(String floor, AppLocalizations l10n) {
    return l10n.getFloor(floor);
  }

  String _getLocalizedRoomType(String type, AppLocalizations l10n) {
    String key = type.toLowerCase().replaceAll(' ', '');
    String localized = l10n.get(key);
    if (localized == key) return type;
    return localized;
  }

  String _formatTo12h(String? timeStr, String locale) {
    if (timeStr == null || timeStr == 'N/A') return 'N/A';
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        final dt = DateTime(2024, 1, 1, hour, minute);
        return DateFormat('h:mm a', locale).format(dt);
      }
    } catch (e) {
      debugPrint('Error formatting time: $e');
    }
    return timeStr;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'declined': return Colors.red.shade900;
      case 'completed': return Colors.blueGrey;
      default: return Colors.blueGrey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Icons.hourglass_empty_rounded;
      case 'approved': return Icons.check_circle_outline_rounded;
      case 'cancelled': return Icons.cancel_outlined;
      case 'declined': return Icons.error_outline_rounded;
      case 'completed': return Icons.task_alt_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}
