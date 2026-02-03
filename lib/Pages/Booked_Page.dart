import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'BookedDetails_Page.dart';
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
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.get('logOut'))), // Or appropriate localized login prompt
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.hasError) {
          return Scaffold(body: Center(child: Text('${l10n.get('somethingWentWrong')}: ${userSnapshot.error}')));
        }

        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final organizationName = userData?['organizationName'] as String?;

        if (organizationName == null || organizationName.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.get('booked'))),
            body: Center(child: Text(l10n.get('noOrgSelectedHome'))),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          appBar: AppBar(
            title: Text(
              l10n.get('booked'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
              tabs: [
                _MinWidthTab(text: l10n.get('all')),
                _MinWidthTab(text: l10n.get('pending')),
                _MinWidthTab(text: l10n.get('approved')),
                _MinWidthTab(text: l10n.get('completed')),
                _MinWidthTab(text: l10n.get('cancelled')),
                _MinWidthTab(text: l10n.get('rejected')),
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
                      hintText: l10n.get('search'),
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
                      _buildBookingStream(null, organizationName, l10n), // All
                      _buildBookingStream('Pending', organizationName, l10n),
                      _buildBookingStream('Approved', organizationName, l10n),
                      _buildBookingStream('Completed', organizationName, l10n),
                      _buildBookingStream('Cancelled', organizationName, l10n),
                      _buildBookingStream('Rejected', organizationName, l10n),
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

  Widget _buildBookingStream(String? statusFilter, String organizationName, AppLocalizations l10n) {
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
          return Center(child: Text('${l10n.get('somethingWentWrong')}: ${snapshot.error}'));
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
                  l10n.get('noRoomsFound'),
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
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookedDetailsPage(booking: bookings[index]),
                  ),
                );
              },
              child: BookingCard(booking: bookings[index]),
            );
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

  String _getLocalizedFloor(String floor, AppLocalizations l10n) {
    String f = floor.toLowerCase().replaceAll(' ', '');
    if (f.contains('ground')) return l10n.get('groundFloor');
    if (f.contains('1st')) return l10n.get('1stFloor');
    if (f.contains('2nd')) return l10n.get('2ndFloor');
    if (f.contains('3rd')) return l10n.get('3rdFloor');
    if (f.contains('4th')) return l10n.get('4thFloor');
    return floor;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _getStatusColor(booking.status);
    final statusText = l10n.get(booking.status.toLowerCase());
    final locale = Localizations.localeOf(context).toString();

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
                        '${booking.building} • ${_getLocalizedFloor(booking.floor, l10n)}',
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
            _buildInfoRow(Icons.calendar_today, DateFormat('MMM dd, yyyy', locale).format(booking.startTime)),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.access_time, '${DateFormat('hh:mm a', locale).format(booking.startTime)} - ${DateFormat('hh:mm a', locale).format(booking.endTime)}'),
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
                          SnackBar(content: Text(l10n.get('requestCancelled'))),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${l10n.get('somethingWentWrong')}: $e")),
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
                  child: Text(l10n.get('cancelRequest')),
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
  final String roomId;
  final String roomName;
  final String building;
  final String floor;
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;
  final String purpose;
  final String status;
  final DateTime createdAt;

  Booking({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.building,
    required this.floor,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.purpose,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking(
      id: doc.id,
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? 'Unknown Room',
      building: data['building'] ?? 'Unknown Building',
      floor: data['floor'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] ?? 0,
      purpose: data['purpose'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}