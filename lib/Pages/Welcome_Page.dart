import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomreserve/Pages/Login_Page.dart';
import 'Register_Page.dart';
import '../l10n/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'lib/assets/images/campus_img.jpg',
                fit: BoxFit.cover,
              ),
            ),
            
            // Gradient Overlay for readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.8),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.3, 0.6, 0.9],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 12),

                  // Logo & Title Section - Padded
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 34.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // App Logo in Circle
                        Container(
                          width: 66,
                          height: 66,
                          padding: const EdgeInsets.fromLTRB(12,10,12,14),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'lib/assets/images/app logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'RoomReserve',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.get('appTagline'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Action Buttons - Padded
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F2937),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.get('login'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.8),
                              foregroundColor: const Color(0xFF1F2937),
                              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              l10n.get('register'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
