import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import 'BookedDetails_Page.dart';
import 'Booked_Page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _getLocalizedFloor(String floor, AppLocalizations l10n) {
    String f = floor.toLowerCase().replaceAll(' ', '');
    if (f.contains('ground')) return l10n.get('groundFloor');
    if (f.contains('1st')) return l10n.get('1stFloor');
    if (f.contains('2nd')) return l10n.get('2ndFloor');
    if (f.contains('3rd')) return l10n.get('3rdFloor');
    if (f.contains('4th')) return l10n.get('4thFloor');
    return floor;
  }

  String _getFormattedDate(BuildContext context) {
    final now = DateTime.now();
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('EEEE, MMM d', locale).format(now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text(l10n.get('logOut')))); // Or appropriate login prompt
    }

    final String displayName = user.displayName?.split(' ')[0] ?? l10n.get('student');

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
          return _buildNoOrgUI(displayName, user, l10n);
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
                        _buildHeader(displayName, user, l10n),
                        const SizedBox(height: 32),
                        _buildStatsGrid(pending, approved, rejected, cancelled, l10n),
                        const SizedBox(height: 32),
                        _buildSectionTitle(l10n.get('upcomingReservations')),
                        const SizedBox(height: 16),
                        _buildUpcomingReservationsSection(upcomingDocs, l10n),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle(l10n.get('recentActivity')),
                            TextButton(
                              onPressed: () => _showAllTodayActivity(context, allRecentActivities, l10n),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(l10n.get('seeAll'), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRecentActivityList(displayActivities, l10n),
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

  void _showAllTodayActivity(BuildContext context, List<QueryDocumentSnapshot> allActivities, AppLocalizations l10n) {
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
                    Text(
                      l10n.get('todaysActivity'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: todayActivities.isEmpty
                          ? Center(child: Text(l10n.get('noActivityToday'), style: const TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: todayActivities.length,
                              itemBuilder: (context, index) {
                                return _RecentActivityItem(doc: todayActivities[index], l10n: l10n);
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

  Widget _buildNoOrgUI(String displayName, User user, AppLocalizations l10n) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(displayName, user, l10n),
              const Spacer(),
              Center(
                child: Text(
                  l10n.get('noOrgSelectedHome'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String displayName, User? user, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getFormattedDate(context).toUpperCase(),
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
                text: l10n.get('hello'),
                style: TextStyle(
                  fontSize: 20,
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
                  if (Localizations.localeOf(context).languageCode == 'ja')
                    TextSpan(
                      text: l10n.get('student'),
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade800,
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

  Widget _buildStatsGrid(int pending, int approved, int rejected, int cancelled, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: l10n.get('pending'),
            count: pending.toString(),
            color: Colors.orange,
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: l10n.get('approved'),
            count: approved.toString(),
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: l10n.get('rejected'),
            count: rejected.toString(),
            color: Colors.red,
            icon: Icons.remove_circle_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: l10n.get('cancelled'),
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

  Widget _buildUpcomingReservationsSection(List<QueryDocumentSnapshot> docs, AppLocalizations l10n) {
    if (docs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Center(
          child: Text(l10n.get('noUpcomingApproved'), style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (docs.length == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUpcomingReservationCard(docs[0], l10n, index: 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingReservationCard(docs[1], l10n, index: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildUpcomingReservationCard(docs[2], l10n, index: 2)),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingReservationCard(docs[3], l10n, index: 3)),
            ],
          ),
        ],
      );
    } else if (docs.length == 3) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildUpcomingReservationCard(docs[0], l10n, index: 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildUpcomingReservationCard(docs[1], l10n, index: 1)),
            ],
          ),
          const SizedBox(height: 12),
          _buildUpcomingReservationCard(docs[2], l10n, index: 2),
        ],
      );
    } else {
      return Column(
        children: List.generate(docs.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildUpcomingReservationCard(docs[i], l10n, index: i),
        )),
      );
    }
  }

  Widget _buildUpcomingReservationCard(QueryDocumentSnapshot doc, AppLocalizations l10n, {int index = 0}) {
    final data = doc.data() as Map<String, dynamic>;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = (data['endTime'] as Timestamp).toDate();
    final locale = Localizations.localeOf(context).toString();

    // Define Color Variants
    final gradients = [
      [const Color(0xFF2563EB), const Color(0xFF1D4ED8)], // Royal Blue
      [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Indigo
      [const Color(0xFF0D9488), const Color(0xFF0F766E)], // Teal
      [const Color(0xFF059669), const Color(0xFF047857)], // Emerald
    ];
    
    final selectedGradient = gradients[index % gradients.length];
    final baseColor = selectedGradient[0];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 200;
        
        // Dynamic decorative configurations based on isSmall
        final decorations = [
          // Variant 0
          [
            Positioned(top: isSmall ? -15 : -20, right: isSmall ? -15 : -20, child: _CircularDecoration(size: isSmall ? 70 : 140, alpha: 0.1)),
            Positioned(bottom: isSmall ? -20 : -30, left: isSmall ? -10 : -10, child: _CircularDecoration(size: isSmall ? 50 : 100, alpha: 0.05)),
          ],
          // Variant 1
          [
            Positioned(top: isSmall ? -20 : -30, left: isSmall ? -15 : -20, child: _CircularDecoration(size: isSmall ? 60 : 120, alpha: 0.08)),
            Positioned(bottom: isSmall ? -15 : -20, right: isSmall ? -10 : -10, child: _CircularDecoration(size: isSmall ? 75 : 150, alpha: 0.06)),
          ],
          // Variant 2
          [
            Positioned(top: isSmall ? -25 : -40, left: isSmall ? 10 : 20, child: _CircularDecoration(size: isSmall ? 45 : 90, alpha: 0.07)),
            Positioned(bottom: isSmall ? 5 : 10, right: isSmall ? -25 : -40, child: _CircularDecoration(size: isSmall ? 80 : 160, alpha: 0.09)),
          ],
          // Variant 3
          [
            Positioned(top: isSmall ? -35 : -60, left: isSmall ? 20 : 40, child: _CircularDecoration(size: isSmall ? 65 : 130, alpha: 0.1)),
            Positioned(bottom: isSmall ? -25 : -40, left: isSmall ? -15 : -20, child: _CircularDecoration(size: isSmall ? 55 : 110, alpha: 0.05)),
          ],
        ];

        final selectedDecoration = decorations[index % decorations.length];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookedDetailsPage(booking: Booking.fromFirestore(doc)),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selectedGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                ...selectedDecoration,
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
                              l10n.get(data['status'].toString().toLowerCase()),
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
                        data['purpose'] ?? l10n.get('noPurpose'),
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
                        '${data['roomName']} • ${_getLocalizedFloor(data['floor'] ?? '', l10n)}',
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
                                _buildWhiteIconInfo(Icons.calendar_today, DateFormat('MMM d', locale).format(startTime), size: 11),
                                const SizedBox(height: 4),
                                _buildWhiteIconInfo(Icons.access_time, DateFormat('hh:mm a', locale).format(startTime), size: 11),
                              ],
                            )
                          : Row(
                              children: [
                                _buildWhiteIconInfo(Icons.calendar_today, DateFormat('MMM d', locale).format(startTime)),
                                const SizedBox(width: 12),
                                _buildWhiteIconInfo(Icons.access_time, '${DateFormat('hh:mm a', locale).format(startTime)} - ${DateFormat('hh:mm a', locale).format(endTime)}'),
                              ],
                            ),
                      ),
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

  Widget _buildRecentActivityList(List<QueryDocumentSnapshot> activities, AppLocalizations l10n) {
    if (activities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text(l10n.get('noRecentActivity'), style: const TextStyle(color: Colors.grey))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        return _RecentActivityItem(doc: activities[index], l10n: l10n);
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final AppLocalizations l10n;

  const _RecentActivityItem({required this.doc, required this.l10n});

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${l10n.get('minsAgo')}';
    if (diff.inHours < 24) return '${diff.inHours} ${l10n.get('hrsAgo')}';
    return '${diff.inDays} ${l10n.get('daysAgo')}';
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = (data['status'] as String).toLowerCase();
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    
    String title = '${l10n.get('reservationStatus')} ${l10n.get(status)}';
    IconData icon = Icons.info_outline;
    Color color = Colors.blue;

    if (status == 'pending') {
      title = l10n.get('newReservation');
      icon = Icons.add_rounded;
      color = Colors.blue;
    } else if (status == 'approved') {
      title = l10n.get('bookingApproved');
      icon = Icons.check_rounded;
      color = Colors.green;
    } else if (status == 'rejected') {
      title = l10n.get('bookingRejected');
      icon = Icons.close_rounded;
      color = Colors.red;
    } else if (status == 'cancelled') {
      title = l10n.get('bookingCancelled');
      icon = Icons.cancel_rounded;
      color = Colors.grey;
    } else if (status == 'completed') {
      title = l10n.get('bookingCompleted');
      icon = Icons.done_all_rounded;
      color = Colors.blueGrey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookedDetailsPage(booking: Booking.fromFirestore(doc)),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
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
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    '${data['roomName']} • ${_getLocalizedFloorRecent(data['floor'] ?? '', l10n)} • ${data['purpose'] ?? l10n.get('noPurpose')}',
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
      ),
    );
  }

  String _getLocalizedFloorRecent(String floor, AppLocalizations l10n) {
    String f = floor.toLowerCase().replaceAll(' ', '');
    if (f.contains('ground')) return l10n.get('groundFloor');
    if (f.contains('1st')) return l10n.get('1stFloor');
    if (f.contains('2nd')) return l10n.get('2ndFloor');
    if (f.contains('3rd')) return l10n.get('3rdFloor');
    if (f.contains('4th')) return l10n.get('4thFloor');
    return floor;
  }
}

class _CircularDecoration extends StatelessWidget {
  final double size;
  final double alpha;

  const _CircularDecoration({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}