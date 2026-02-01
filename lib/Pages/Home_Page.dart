import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName?.split(' ')[0] ?? 'Student';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD), // Slightly cleaner grey
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Section
                _buildHeader(displayName, user),

                const SizedBox(height: 32),

                // 2. Stats Overview
                _buildStatsGrid(),

                const SizedBox(height: 32),

                // 3. Upcoming Reservation
                _buildSectionTitle('Upcoming Reservation'),
                const SizedBox(height: 16),
                _buildUpcomingReservationCard(),

                const SizedBox(height: 32),

                // 4. Recent Activity
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Recent Activity'),
                    TextButton(
                      onPressed: () {},
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
                _buildRecentActivityList(),
              ],
            ),
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
                  fontFamily: 'Roboto', // Default flutter font
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
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2563EB).withOpacity(0.1),
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

  Widget _buildStatsGrid() {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: 'Pending',
            count: '2',
            color: Colors.orange,
            icon: Icons.hourglass_top_rounded,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Approved',
            count: '5',
            color: Colors.green,
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Rejected',
            count: '0',
            color: Colors.red,
            icon: Icons.remove_circle_outline_rounded,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _StatCard(
            title: 'Cancelled',
            count: '1',
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

  Widget _buildUpcomingReservationCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Background Circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // Card Content
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Text(
                        'Approved',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: Colors.white70),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Student Council Meeting',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PTC 305 • Classroom',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildWhiteIconInfo(Icons.calendar_today, 'Oct 24'),
                      Container(
                        height: 16,
                        width: 1,
                        color: Colors.white24,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      _buildWhiteIconInfo(Icons.access_time, '10:00 - 12:00'),
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

  Widget _buildRecentActivityList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _RecentActivityItem(index: index);
      },
    );
  }

  Widget _buildWhiteIconInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
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
        color: color.withOpacity(0.08), // Subtle tint background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Vertically center content
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally as well
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the row content
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
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  final int index;

  const _RecentActivityItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final titles = ['Booking Cancelled', 'New Reservation', 'Booking Approved'];
    final subtitles = [
      'PTC 306 • Thesis Defense',
      'ITS 200 • Workshop',
      'PTC 305 • Meeting'
    ];
    final times = ['2 mins ago', '2 hrs ago', '1 day ago'];
    final icons = [Icons.close_rounded, Icons.add_rounded, Icons.check_rounded];
    final colors = [Colors.red, Colors.blue, Colors.green];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors[index].withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icons[index], color: colors[index], size: 22),
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
                      titles[index],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      times[index],
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
                  subtitles[index],
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