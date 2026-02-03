import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
          minWidth: 40,
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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please log in to view your bookings")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Scaffold(body: Center(child: Text('Error: ${userSnapshot.error}')));
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final organizationName = userData?['organizationName'] as String?;

        if (organizationName == null || organizationName.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Bookings')),
            body: const Center(child: Text("No organization selected. Please update your profile.")),
          );
        }

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
                _MinWidthTab(text: 'Approved'),
                _MinWidthTab(text: 'Completed'),
                _MinWidthTab(text: 'Cancelled'),
                _MinWidthTab(text: 'Rejected'),
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
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 1000), () {
                        setState(() {
                          _query = value.trim().toLowerCase();
                        });
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
                      _buildBookingStream(null, organizationName), // All
                      _buildBookingStream('Pending', organizationName),
                      _buildBookingStream('Approved', organizationName),
                      _buildBookingStream('Completed', organizationName),
                      _buildBookingStream('Cancelled', organizationName),
                      _buildBookingStream('Rejected', organizationName),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildBookingStream(String? statusFilter, String organizationName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    // Query filtered by userId and organizationName
    Query query = FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('organizationName', isEqualTo: organizationName);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading bookings: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        
        // Convert to objects and apply client-side filtering for Search and Status (if needed)
        List<Booking> bookings = docs.map((doc) => Booking.fromFirestore(doc)).toList();

        // 1. Filter by status (case-insensitive check if needed, but Firestore usually matches exact)
        if (statusFilter != null) {
          bookings = bookings.where((b) => b.status.toLowerCase() == statusFilter.toLowerCase()).toList();
        }

        // 2. Filter by search query
        if (_query.isNotEmpty) {
          bookings = bookings.where((b) {
            return b.roomName.toLowerCase().contains(_query) ||
                   b.purpose.toLowerCase().contains(_query);
          }).toList();
        }

        // 3. Sort by status priority then by startTime descending
        final statusPriority = {
          'pending': 0,
          'approved': 1,
          'completed': 2,
          'cancelled': 3,
          'rejected': 4,
        };

        bookings.sort((a, b) {
          int pA = statusPriority[a.status.toLowerCase()] ?? 5;
          int pB = statusPriority[b.status.toLowerCase()] ?? 5;
          if (pA != pB) return pA.compareTo(pB);
          return b.startTime.compareTo(a.startTime);
        });

        if (bookings.isEmpty) {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return BookingCard(booking: bookings[index]);
          },
        );
      },
    );
  }
}

/* ===================== BOOKING CARD UI ===================== */

class BookingCard extends StatelessWidget {
  final Booking booking;

  const BookingCard({super.key, required this.booking});

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final statusText = _capitalize(booking.status);

    return Card(
      elevation: 0,
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
                Expanded(
                  child: Column(
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
                ),
                // Status Chip
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.2)),
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
            _buildInfoRow(Icons.calendar_today, DateFormat('MMM dd, yyyy').format(booking.startTime)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, '${DateFormat('hh:mm a').format(booking.startTime)} - ${DateFormat('hh:mm a').format(booking.endTime)}'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.bookmark_outline, booking.purpose),

            // Optional: Action Buttons for Pending items
            if (booking.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).update({
                        'status': 'cancelled',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Booking cancelled")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to cancel: $e")),
                        );
                      }
                    }
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red.shade900;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }
}

/* ===================== DATA MODELS ===================== */

class Booking {
  final String id;
  final String roomName;
  final String building;
  final String floor;
  final DateTime startTime;
  final DateTime endTime;
  final String purpose;
  final String status;

  Booking({
    required this.id,
    required this.roomName,
    required this.building,
    required this.floor,
    required this.startTime,
    required this.endTime,
    required this.purpose,
    required this.status,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      roomName: data['roomName'] ?? 'Unknown Room',
      building: data['building'] ?? 'Unknown Building',
      floor: data['floor'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'Pending',
    );
  }
}