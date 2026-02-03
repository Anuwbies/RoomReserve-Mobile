import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _getFormattedDate() {
    final now = DateTime.now();
    return DateFormat('EEEE, MMM d').format(now);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final String displayName = user.displayName?.split(' ')[0] ?? 'Student';

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
          return _buildNoOrgUI(displayName, user);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FD),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .where('organizationName', isEqualTo: organizationName)
                      .snapshots(),
                  builder: (context, bookingsSnapshot) {
                    if (bookingsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final allBookings = bookingsSnapshot.data?.docs ?? [];
                    
                    // Stats calculation
                    int pending = 0, approved = 0, rejected = 0, cancelled = 0;
                    for (var doc in allBookings) {
                      final data = doc.data() as Map<String, dynamic>;
                      final status = (data['status'] as String? ?? '').toLowerCase();
                      if (status == 'pending') {
                        pending++;
                      } else if (status == 'approved') {
                        approved++;
                      } else if (status == 'rejected') {
                        rejected++;
                      } else if (status == 'cancelled') {
                        cancelled++;
                      }
                    }

                    // Upcoming Reservations: First 4 approved bookings with startTime > now
                    final now = DateTime.now();
                    List<QueryDocumentSnapshot> upcomingDocs = [];
                    try {
                      final allApprovedFuture = allBookings.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final String status = (data['status'] as String? ?? '').toLowerCase();
                        final startTimestamp = data['startTime'] as Timestamp?;
                        if (startTimestamp == null) return false;
                        final startTime = startTimestamp.toDate();
                        return status == 'approved' && startTime.isAfter(now);
                      }).toList();

                      allApprovedFuture.sort((a, b) {
                        final aTime = (a['startTime'] as Timestamp).toDate();
                        final bTime = (b['startTime'] as Timestamp).toDate();
                        return aTime.compareTo(bTime);
                      });
                      
                      upcomingDocs = allApprovedFuture.take(4).toList();
                    } catch (e) {
                      debugPrint('Error finding upcoming: $e');
                    }

                    // Recent Activity: Sorted by createdAt descending
                    List<QueryDocumentSnapshot> recentActivities = List.from(allBookings);
                    recentActivities.sort((a, b) {
                      final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                      final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
                      return bTime.compareTo(aTime);
                    });
                    
                    final allRecentActivities = recentActivities;
                    final displayActivities = allRecentActivities.take(5).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(displayName, user),
                        const SizedBox(height: 32),
                        _buildStatsGrid(pending, approved, rejected, cancelled),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Upcoming Reservations'),
                        const SizedBox(height: 16),
                        _buildUpcomingReservationsSection(upcomingDocs),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Recent Activity'),
                            TextButton(
                              onPressed: () => _showAllTodayActivity(context, allRecentActivities),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecentActivityList(displayActivities),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAllTodayActivity(BuildContext context, List<QueryDocumentSnapshot> allActivities) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final todayActivities = allActivities.where((doc) {
      final createdAt = (doc['createdAt'] as Timestamp?)?.toDate();
      if (createdAt == null) return false;
      return createdAt.isAfter(todayStart);
    }).toList();

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
                    const Text(
                      "Today's Activity",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: todayActivities.isEmpty
                          ? const Center(child: Text("No activity recorded today", style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: todayActivities.length,
                              itemBuilder: (context, index) {
                                return _RecentActivityItem(doc: todayActivities[index]);
                              },
                            ),
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

  Widget _buildNoOrgUI(String displayName, User user) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayName, user),
              const Spacer(),
              const Center(
                child: Text(
                  "No organization selected.\nPlease update your profile to see data.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName, User? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getFormattedDate().toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                text: 'Hello, ',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.grey.shade800,
                ),
                children: [
                  TextSpan(
                    text: displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, color: Color(0xFF2563EB))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int pending, int approved, int rejected, int cancelled) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Pending',
            count: pending.toString(),
            color: Colors.orange,
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Approved',
            count: approved.toString(),
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Rejected',
            count: rejected.toString(),
            color: Colors.red,
            icon: Icons.remove_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Cancelled',
            count: cancelled.toString(),
            color: Colors.grey,
            icon: Icons.cancel_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildUpcomingReservationsSection(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text("No upcoming approved reservations", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (docs.length == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUpcomingReservationCard(docs[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingReservationCard(docs[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildUpcomingReservationCard(docs[2])),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingReservationCard(docs[3])),
            ],
          ),
        ],
      );
    } else if (docs.length == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUpcomingReservationCard(docs[0])),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingReservationCard(docs[1])),
            ],
          ),
          const SizedBox(height: 12),
          _buildUpcomingReservationCard(docs[2]),
        ],
      );
    } else {
      return Column(
        children: docs.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildUpcomingReservationCard(doc),
        )).toList(),
      );
    }
  }

  Widget _buildUpcomingReservationCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = (data['endTime'] as Timestamp).toDate();

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 200;
        
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: isSmall ? 80 : 120,
                  height: isSmall ? 80 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(isSmall ? 16.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _capitalize(data['status']),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmall ? 10 : 11,
                            ),
                          ),
                        ),
                        if (!isSmall) const Icon(Icons.more_horiz, color: Colors.white70, size: 18),
                      ],
                    ),
                    SizedBox(height: isSmall ? 12 : 16),
                    Text(
                      data['purpose'] ?? 'No Purpose',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['roomName']} • ${data['floor']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isSmall ? 12 : 13,
                      ),
                    ),
                    SizedBox(height: isSmall ? 12 : 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isSmall 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWhiteIconInfo(Icons.calendar_today, DateFormat('MMM d').format(startTime), size: 11),
                              const SizedBox(height: 4),
                              _buildWhiteIconInfo(Icons.access_time, '${DateFormat('HH:mm').format(startTime)}', size: 11),
                            ],
                          )
                        : Row(
                            children: [
                              _buildWhiteIconInfo(Icons.calendar_today, DateFormat('MMM d').format(startTime)),
                              const SizedBox(width: 12),
                              _buildWhiteIconInfo(Icons.access_time, '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}'),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildRecentActivityList(List<QueryDocumentSnapshot> activities) {
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text("No recent activity", style: TextStyle(color: Colors.grey))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _RecentActivityItem(doc: activities[index]);
      },
    );
  }

  Widget _buildWhiteIconInfo(IconData icon, String text, {double size = 13}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: size + 2),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: size,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- CUSTOM WIDGETS ----------------

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const _RecentActivityItem({required this.doc});

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    return '${diff.inDays} days ago';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] as String).toLowerCase();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    String title = 'Reservation ${_capitalize(status)}';
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    if (status == 'pending') {
      title = 'New Reservation';
      icon = Icons.add_rounded;
      color = Colors.blue;
    } else if (status == 'approved') {
      title = 'Booking Approved';
      icon = Icons.check_rounded;
      color = Colors.green;
    } else if (status == 'rejected') {
      title = 'Booking Rejected';
      icon = Icons.close_rounded;
      color = Colors.red;
    } else if (status == 'cancelled') {
      title = 'Booking Cancelled';
      icon = Icons.cancel_rounded;
      color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      _getTimeAgo(createdAt),
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['roomName']} • ${data['purpose']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}