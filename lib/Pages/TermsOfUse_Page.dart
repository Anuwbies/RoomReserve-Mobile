import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({super.key});

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
                      'Terms of Use',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
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
                    _SectionTitle('1. Acceptance of Terms'),
                    _SectionText(
                      'By accessing or using RoomReserve, you acknowledge that you have read, '
                          'understood, and agree to comply with these Terms of Use. If you do not agree '
                          'with any part of these terms, you must discontinue use of the system.',
                    ),

                    _SectionTitle('2. Purpose of the System'),
                    _SectionText(
                      'RoomReserve is intended solely for campus facility reservation and utilization '
                          'monitoring. The system allows authorized users to request room bookings while '
                          'administrators manage approvals, scheduling, and reporting.',
                    ),

                    _SectionTitle('3. User Responsibilities'),
                    _SectionText(
                      'Users are responsible for providing accurate reservation details and for '
                          'using campus facilities in accordance with institutional policies. Any misuse, '
                          'false booking, or unauthorized access may result in suspension or termination '
                          'of system privileges.',
                    ),

                    _SectionTitle('4. Reservation and Approval Policy'),
                    _SectionText(
                      'All room reservation requests are subject to availability and administrative '
                          'approval. RoomReserve does not guarantee approval of requests and reserves the '
                          'right to cancel or modify bookings that violate institutional rules.',
                    ),

                    _SectionTitle('5. Limitation of Liability'),
                    _SectionText(
                      'RoomReserve is provided on an "as is" basis. The developers and administrators '
                          'are not liable for scheduling conflicts, denied reservations, or damages '
                          'resulting from misuse or reliance on system information.',
                    ),

                    _SectionTitle('6. Modifications to the Terms'),
                    _SectionText(
                      'These Terms of Use may be updated to reflect system changes or policy updates. '
                          'Continued use of RoomReserve after modifications constitutes acceptance of the '
                          'revised terms.',
                    ),

                    SizedBox(height: 16),

                    Center(
                      child: Text(
                        'Last updated: January 2026',
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
