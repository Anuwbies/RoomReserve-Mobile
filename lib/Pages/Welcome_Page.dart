import 'package:flutter/material.dart';
import 'package:roomreserve/Pages/Login_Page.dart';
import 'Register_Page.dart';
import '../l10n/app_localizations.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top image section
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(80),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/assets/images/room key.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom content section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.autorenew,
                          color: Colors.blue,
                          size: 28,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // App name
                    const Text(
                      'RoomReserve',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.get('login'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
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
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.get('register'),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16),
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
