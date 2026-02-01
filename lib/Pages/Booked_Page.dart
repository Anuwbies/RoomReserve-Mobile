import 'package:flutter/material.dart';

class BookedPage extends StatefulWidget {
  const BookedPage({super.key});

  @override
  State<BookedPage> createState() => _BookedPageState();
}

class _MinWidthTab extends StatelessWidget {
  final String text;

  const _MinWidthTab({required this.text});

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 50, // adjust to taste (80–100 works well)
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(text),
      ),
    );
  }
}

class _BookedPageState extends State<BookedPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Updated length to 5 for: All, Pending, Rejected, Cancelled, Approved
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            _MinWidthTab(text: 'All'),
            _MinWidthTab(text: 'Pending'),
            _MinWidthTab(text: 'Rejected'),
            _MinWidthTab(text: 'Cancelled'),
            _MinWidthTab(text: 'Approved'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            /* SEARCH BAR */
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search room or purpose...',
                  prefixIcon: const Icon(Icons.search),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            /* BOOKING LISTS */
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingList(null), // All
                  _buildBookingList(BookingStatus.pending),
                  _buildBookingList(BookingStatus.rejected),
                  _buildBookingList(BookingStatus.cancelled),
                  _buildBookingList(BookingStatus.approved),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(BookingStatus? statusFilter) {
    // 1. Filter by Search Query
    List<Booking> filtered = sampleBookings.where((booking) {
      final matchesSearch =
          booking.roomName.toLowerCase().contains(_query) ||
              booking.purpose.toLowerCase().contains(_query);
      return matchesSearch;
    }).toList();

    // 2. Filter by Tab Status
    if (statusFilter != null) {
      filtered = filtered.where((b) => b.status == statusFilter).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              "No bookings found",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return BookingCard(booking: filtered[index]);
      },
    );
  }
}

/* ===================== BOOKING CARD UI ===================== */

class BookingCard extends StatelessWidget {
  final Booking booking;

  const BookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _getStatusText(booking.status);

    return Card(
      elevation: 0, // Flat style with border looks cleaner for lists
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Room Name and Building
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.roomName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${booking.building} • ${booking.floor}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                // Status Chip
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // Date and Time Info
            _buildInfoRow(Icons.calendar_today, booking.date),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, '${booking.startTime} - ${booking.endTime}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.bookmark_outline, booking.purpose),

            // Optional: Action Buttons for Pending items
            if (booking.status == BookingStatus.pending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Logic to cancel booking
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cancel request sent")),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Cancel Request"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.approved:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.red.shade900;
      case BookingStatus.completed:
        return Colors.blueGrey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pending';
      case BookingStatus.approved:
        return 'Approved';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.completed:
        return 'Completed';
    }
  }
}

/* ===================== DATA MODELS & SAMPLE DATA ===================== */

enum BookingStatus { pending, approved, cancelled, rejected, completed }

class Booking {
  final String id;
  final String roomName;
  final String building;
  final String floor;
  final String date;
  final String startTime;
  final String endTime;
  final String purpose;
  final BookingStatus status;

  Booking({
    required this.id,
    required this.roomName,
    required this.building,
    required this.floor,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.status,
  });
}

final List<Booking> sampleBookings = [
  Booking(
    id: '101',
    roomName: 'PTC 305',
    building: 'PTC Building',
    floor: '3rd Floor',
    date: 'Oct 24, 2023',
    startTime: '10:00 AM',
    endTime: '12:00 PM',
    purpose: 'Student Council Meeting',
    status: BookingStatus.approved,
  ),
  Booking(
    id: '102',
    roomName: 'ITS 200',
    building: 'ITS Building',
    floor: '2nd Floor',
    date: 'Oct 25, 2023',
    startTime: '01:00 PM',
    endTime: '03:00 PM',
    purpose: 'Programming Workshop',
    status: BookingStatus.pending,
  ),
  Booking(
    id: '103',
    roomName: 'PTC 306',
    building: 'PTC Building',
    floor: '3rd Floor',
    date: 'Oct 26, 2023',
    startTime: '09:00 AM',
    endTime: '11:00 AM',
    purpose: 'Thesis Defense',
    status: BookingStatus.cancelled,
  ),
  Booking(
    id: '104',
    roomName: 'ITS 201',
    building: 'ITS Building',
    floor: '2nd Floor',
    date: 'Oct 20, 2023',
    startTime: '02:00 PM',
    endTime: '04:00 PM',
    purpose: 'System Testing',
    status: BookingStatus.completed,
  ),
  Booking(
    id: '105',
    roomName: 'Auditorium',
    building: 'Main Building',
    floor: '1st Floor',
    date: 'Oct 30, 2023',
    startTime: '08:00 AM',
    endTime: '05:00 PM',
    purpose: 'General Assembly',
    status: BookingStatus.pending,
  ),
];