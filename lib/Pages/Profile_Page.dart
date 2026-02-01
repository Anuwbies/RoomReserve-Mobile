import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:roomreserve/Pages/Welcome_Page.dart';

// Assuming these pages exist based on your provided code
import 'About_Page.dart';
import 'Faq_Page.dart';
import 'PrivacyPolicy_Page.dart';
import 'TermsOfUse_Page.dart';

// Moved constants to top-level
const Color _kBackgroundColor = Color(0xFFF3F4F6); // Soft grey bg
const Color _kSurfaceColor = Colors.white;
const Color _kPrimaryColor = Color(0xFF2563EB); // Royal Blue
const Color _kDangerColor = Color(0xFFEF4444); // Red

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _logout(BuildContext context) async {
    try {
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomePage()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Log out'),
          content:
          const Text('Are you sure you want to log out of your account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kDangerColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (mounted) _logout(context);
    }
  }

  Future<void> _selectOrganization(User user) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Organization',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kDangerColor, // Reddish Title
                ),
              ),
              const SizedBox(height: 10),
              const Divider(color: _kDangerColor, thickness: 1, indent: 20, endIndent: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('organizations')
                      .orderBy('name')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(child: Text("Error loading organizations"));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: _kDangerColor),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business_outlined, size: 48, color: Colors.red.shade200),
                            const SizedBox(height: 10),
                            const Text(
                              "No organizations found.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: docs.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final String orgName = data['name'] ?? docs[index].id;

                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _kDangerColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_rounded, color: _kDangerColor, size: 20),
                          ),
                          title: Text(
                            orgName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                          onTap: () async {
                            final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                            final docSnapshot = await userDoc.get();

                            if (docSnapshot.exists) {
                              // Just update organization and timestamp
                              await userDoc.update({
                                'organization': orgName,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            } else {
                              // If doc missing, create with ALL standard fields (same as Register Page)
                              await userDoc.set({
                                'name': user.displayName ?? 'Guest',
                                'email': user.email,
                                'role': 'student',
                                'organization': orgName,
                                'isActive': true,
                                'isEmailVerified': user.emailVerified,
                                'createdAt': FieldValue.serverTimestamp(),
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            }

                            if (mounted) Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String? photoUrl = user?.photoURL;
    final String displayName = user?.displayName ?? 'Guest User';
    final String email = user?.email ?? 'No email linked';

    // Guard: If no user is logged in, show simple UI
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: _kBackgroundColor,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Get Data from Firestore
          final userData = snapshot.data?.data() as Map<String, dynamic>?;
          final String organization = userData?['organization'] ?? '';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // 1. Header Section
                _ProfileHeader(
                  photoUrl: photoUrl,
                  displayName: displayName,
                  email: email,
                  organization: organization,
                  onSelectOrganization: () => _selectOrganization(user),
                ),

                const SizedBox(height: 24),

                // 2. Menu Section: General
                _ProfileSection(
                  title: "General",
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.notifications_none_rounded,
                      iconColor: Colors.orange,
                      title: 'Notifications',
                      onTap: () {},
                    ),
                    _ProfileMenuItem(
                      icon: Icons.language_rounded,
                      iconColor: Colors.purple,
                      title: 'Language',
                      trailingText: 'English',
                      onTap: () {},
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 3. Menu Section: Support & Legal
                _ProfileSection(
                  title: "Support & Legal",
                  children: [
                    _ProfileMenuItem(
                      icon: Icons.description_outlined,
                      iconColor: Colors.blue,
                      title: 'Terms of Use',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TermsOfUsePage()),
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconColor: Colors.teal,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PrivacyPolicyPage()),
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: Colors.indigo,
                      title: 'FAQ',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FaqPage()),
                      ),
                    ),
                    _ProfileMenuItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.grey.shade700,
                      title: 'About App',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      ),
                      isLast: true,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _showLogoutConfirmation(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          color: _kDangerColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- CUSTOM WIDGETS ----------------

class _ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final String organization;
  final VoidCallback onSelectOrganization;

  const _ProfileHeader({
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.organization,
    required this.onSelectOrganization,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasOrg = organization.isNotEmpty;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? SvgPicture.asset(
                  'lib/assets/images/profile.svg',
                  width: 60,
                  height: 60,
                  colorFilter: const ColorFilter.mode(
                    Colors.grey,
                    BlendMode.srcIn,
                  ),
                )
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: _kPrimaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.edit,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),

        // Organization Pill
        GestureDetector(
          onTap: hasOrg ? null : onSelectOrganization, // Allow selection if blank
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: hasOrg
                  ? _kPrimaryColor.withOpacity(0.08)
                  : Colors.red.shade50, // Reddish bg if empty
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: hasOrg
                    ? _kPrimaryColor.withOpacity(0.1)
                    : _kDangerColor.withOpacity(0.3), // Reddish border if empty
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasOrg) ...[
                  const Icon(Icons.add_business_rounded, size: 16, color: _kDangerColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  hasOrg ? organization : "Select Organization",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasOrg ? _kPrimaryColor : _kDangerColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final String? trailingText;
  final bool isLast;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.trailingText,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : const BorderRadius.vertical(
            top: Radius.circular(16)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (trailingText != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        trailingText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                indent: 70,
                thickness: 0.5,
                color: Colors.grey.shade200,
              ),
          ],
        ),
      ),
    );
  }
}