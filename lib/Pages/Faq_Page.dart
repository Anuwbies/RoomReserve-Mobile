import 'package:flutter/material.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // Header: Back button + centered title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new),
                  ),
                  const Expanded(
                    child: Text(
                      'FAQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
                padding:
                const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _SectionTitle('1. What is RoomReserve?'),
                    _SectionText(
                      'RoomReserve is a campus facility booking and utilization monitoring system '
                          'that allows authorized users to reserve classrooms, laboratories, and other '
                          'shared spaces in an organized and centralized manner.',
                    ),

                    _SectionTitle('2. Who can use the system?'),
                    _SectionText(
                      'The system is intended for school administrators, faculty, staff, and other '
                          'authorized users. Access and permissions depend on the user role assigned by '
                          'the institution.',
                    ),

                    _SectionTitle('3. How do I book a room?'),
                    _SectionText(
                      'Users can view available rooms in real time and submit a reservation request '
                          'by selecting the desired room, date, and time. All bookings may require '
                          'administrative approval.',
                    ),

                    _SectionTitle('4. Can I edit or cancel a reservation?'),
                    _SectionText(
                      'Yes. Users may edit or cancel their reservation requests before approval. '
                          'Once approved, changes may be subject to administrative policies.',
                    ),

                    _SectionTitle('5. How does the approval process work?'),
                    _SectionText(
                      'Administrators review reservation requests to avoid conflicts and ensure '
                          'proper use of facilities. Users are notified once their request is approved '
                          'or rejected.',
                    ),

                    _SectionTitle('6. Does the system show real-time availability?'),
                    _SectionText(
                      'Yes. Room availability is updated based on approved bookings, allowing users '
                          'to see which rooms are free or occupied at a given time.',
                    ),

                    _SectionTitle('7. Is my information secure?'),
                    _SectionText(
                      'The system applies standard security measures to protect user data and '
                          'reservation records. Access is restricted based on user roles.',
                    ),

                    SizedBox(height: 16),

                    Center(
                      child: Text(
                        'Need more help? Contact the system administrator.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;

  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Colors.black87,
      ),
    );
  }
}
