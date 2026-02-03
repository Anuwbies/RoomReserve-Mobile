import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                      'About',
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
                    _SectionTitle('1. About the Application'),
                    _SectionText(
                      'RoomReserve is a campus facility booking and utilization monitoring system '
                          'designed to help educational institutions efficiently manage classrooms, '
                          'laboratories, conference rooms, and other shared facilities through a '
                          'centralized digital platform.',
                    ),

                    _SectionTitle('2. Purpose'),
                    _SectionText(
                      'The purpose of this application is to streamline the reservation process, '
                          'prevent scheduling conflicts, and improve overall facility utilization. '
                          'It aims to provide administrators, faculty, and authorized users with a '
                          'reliable and transparent room booking solution.',
                    ),

                    _SectionTitle('3. How It Works'),
                    _SectionText(
                      'Users can view available rooms in real time and submit reservation requests '
                          'based on their needs. Administrators review and approve bookings, while the '
                          'system tracks room usage, availability, and booking history for monitoring '
                          'and reporting purposes.',
                    ),

                    _SectionTitle('4. Project Background'),
                    _SectionText(
                      'RoomReserve is developed as part of an academic capstone project focusing on '
                          'information systems development, usability, and efficient resource '
                          'management within educational institutions.',
                    ),

                    _SectionTitle('5. Disclaimer'),
                    _SectionText(
                      'Room availability and booking status depend on system data and administrative '
                          'approval. Users are responsible for following institutional policies when '
                          'reserving and using campus facilities.',
                    ),

                    SizedBox(height: 16),

                    Center(
                      child: Text(
                        'Version 1.0.0',
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
          fontSize: 18,
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
