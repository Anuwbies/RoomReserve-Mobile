import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                      'Privacy Policy',
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
                    _SectionTitle('1. Information We Collect'),
                    _SectionText(
                      'RoomReserve may collect basic personal information such as your name, '
                          'email address, and user role when you create an account or access the system. '
                          'Reservation details, booking history, and room usage data are also recorded '
                          'to support system functionality.',
                    ),

                    _SectionTitle('2. How We Use Your Information'),
                    _SectionText(
                      'Collected information is used to manage room reservations, verify user '
                          'authorization, process approvals, generate utilization reports, and improve '
                          'overall system performance and reliability.',
                    ),

                    _SectionTitle('3. Data Storage and Security'),
                    _SectionText(
                      'Reasonable administrative and technical measures are applied to protect '
                          'stored data from unauthorized access, alteration, or disclosure. While '
                          'security practices are implemented, no digital system can guarantee absolute '
                          'data security.',
                    ),

                    _SectionTitle('4. Sharing of Information'),
                    _SectionText(
                      'Personal information and reservation records are not sold or shared with '
                          'third parties, except when required by institutional policies, system '
                          'operations, or applicable laws and regulations.',
                    ),

                    _SectionTitle('5. Third-Party Services'),
                    _SectionText(
                      'RoomReserve may integrate third-party services for authentication, hosting, '
                          'or analytics. These services operate under their own privacy policies and are '
                          'used only to support core system functions.',
                    ),

                    _SectionTitle('6. User Rights and Responsibilities'),
                    _SectionText(
                      'Users may request access to or correction of their personal information '
                          'through system administrators. Users are responsible for ensuring the '
                          'accuracy of submitted reservation details.',
                    ),

                    _SectionTitle('7. Changes to This Policy'),
                    _SectionText(
                      'This Privacy Policy may be updated to reflect system improvements or policy '
                          'changes. Continued use of RoomReserve after updates signifies acceptance of '
                          'the revised policy.',
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
