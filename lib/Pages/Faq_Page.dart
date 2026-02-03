import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                  Expanded(
                    child: Text(
                      l10n.get('faq'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
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
                  children: [
                    _SectionTitle(l10n.get('faq_sec1_title')),
                    _SectionText(l10n.get('faq_sec1_text')),

                    _SectionTitle(l10n.get('faq_sec2_title')),
                    _SectionText(l10n.get('faq_sec2_text')),

                    _SectionTitle(l10n.get('faq_sec3_title')),
                    _SectionText(l10n.get('faq_sec3_text')),

                    _SectionTitle(l10n.get('faq_sec4_title')),
                    _SectionText(l10n.get('faq_sec4_text')),

                    _SectionTitle(l10n.get('faq_sec5_title')),
                    _SectionText(l10n.get('faq_sec5_text')),

                    _SectionTitle(l10n.get('faq_sec6_title')),
                    _SectionText(l10n.get('faq_sec6_text')),

                    _SectionTitle(l10n.get('faq_sec7_title')),
                    _SectionText(l10n.get('faq_sec7_text')),

                    const SizedBox(height: 16),

                    Center(
                      child: Text(
                        l10n.get('needMoreHelp'),
                        style: const TextStyle(
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
