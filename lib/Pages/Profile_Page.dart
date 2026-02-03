import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:roomreserve/Pages/Welcome_Page.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

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
    final l10n = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.get('logoutConfirmationTitle')),
          content: Text(l10n.get('logoutConfirmationMessage')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.get('cancel'), style: const TextStyle(color: Colors.grey)),
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
              child: Text(l10n.get('logOut')),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (mounted) _logout(context);
    }
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
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
              Text(
                AppLocalizations.of(context).get('language'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Divider(),
              _LanguageItem(locale: const Locale('en'), name: 'English'),
              _LanguageItem(locale: const Locale('ja'), name: 'Japanese'),
            ],
          ),
        );
      },
    );
  }

  void _syncOrganizationName(String userId, String? userOrg, String? memberOrg, String? status) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final isApproved = status == 'approved';
      final currentOrg = userOrg ?? '';
      
      if (isApproved) {
        if (memberOrg != null && currentOrg != memberOrg) {
          // Sync: User is approved but user doc doesn't match
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'organizationName': memberOrg,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        if (currentOrg.isNotEmpty) {
          // Sync: User is NOT approved (pending/kicked/left) but has org name in user doc
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'organizationName': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> _confirmLeaveOrCancel(BuildContext context, String? membershipId, String? status) async {
    if (membershipId == null) return;
    
    final isPending = status == 'pending';
    final isKicked = status == 'kicked';
    final isDeclined = status == 'declined';
    
    String title = 'Leave Organization?';
    String message = 'Are you sure you want to leave this organization?';
    String actionLabel = 'Leave';

    if (isPending) {
      title = 'Cancel Request?';
      message = 'Are you sure you want to cancel your membership request?';
      actionLabel = 'Cancel Request';
    } else if (isKicked) {
      title = 'Dismiss Notification?';
      message = 'You have been removed from this organization. Dismiss this notice?';
      actionLabel = 'Dismiss';
    } else if (isDeclined) {
      title = 'Dismiss Notification?';
      message = 'Your membership request was declined. Dismiss this notice?';
      actionLabel = 'Dismiss';
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No', style: TextStyle(color: Colors.grey)),
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
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('memberships').doc(membershipId).update({
          'status': isPending ? 'cancelled' : 'left', // Kicked/Declined -> Left (to clear from view)
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(isPending ? 'Request cancelled' : (isKicked || isDeclined ? 'Notification dismissed' : 'Left organization'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _selectOrganization(User user) async {
    final l10n = AppLocalizations.of(context);
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
              Text(
                l10n.get('selectOrganization'),
                style: const TextStyle(
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
                            Text(
                              l10n.get('noRoomsFound'), // Reusing noRoomsFound or similar logic
                              style: const TextStyle(color: Colors.grey),
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
                            try {
                              final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
                              final docSnapshot = await userDoc.get();
                              String userName = user.displayName ?? 'Guest';

                              // If user doc exists, try to get the name from there as it might be more up to date than Auth
                              if (docSnapshot.exists) {
                                final data = docSnapshot.data() as Map<String, dynamic>;
                                if (data.containsKey('name')) {
                                  userName = data['name'];
                                }
                              }

                              // Check for existing membership
                              final existingQuery = await FirebaseFirestore.instance
                                  .collection('memberships')
                                  .where('userId', isEqualTo: user.uid)
                                  .where('organizationName', isEqualTo: orgName)
                                  .limit(1)
                                  .get();

                              if (existingQuery.docs.isNotEmpty) {
                                // Update existing
                                await existingQuery.docs.first.reference.update({
                                  'status': 'pending',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                  'name': userName,
                                });
                              } else {
                                // Create membership request
                                await FirebaseFirestore.instance.collection('memberships').add({
                                  'joinedAt': FieldValue.serverTimestamp(),
                                  'organizationName': orgName,
                                  'role': 'member',
                                  'status': 'pending',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                  'name': userName,
                                  'userId': user.uid,
                                });
                              }

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Membership request sent. Status: Pending')),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to send request: $e')),
                                );
                              }
                            }
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
    final l10n = AppLocalizations.of(context);
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
        title: Text(
          l10n.get('myProfile'),
          style: const TextStyle(
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
        builder: (context, userSnapshot) {
          if (userSnapshot.hasError) {
            return Center(child: Text('Error: ${userSnapshot.error}'));
          }

          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('memberships')
                .where('userId', isEqualTo: user.uid)
                .where('status', whereIn: ['pending', 'approved', 'kicked', 'declined'])
                .limit(1)
                .snapshots(),
            builder: (context, membershipSnapshot) {
              // Fix flicker: Show loading if connecting
              if (membershipSnapshot.connectionState == ConnectionState.waiting) {
                 return const Center(child: CircularProgressIndicator());
              }

              String? orgName;
              String? status;
              String? membershipId;

              if (membershipSnapshot.hasData && membershipSnapshot.data!.docs.isNotEmpty) {
                final doc = membershipSnapshot.data!.docs.first;
                final data = doc.data() as Map<String, dynamic>;
                orgName = data['organizationName'];
                status = data['status'];
                membershipId = doc.id;
              }
              
              // Sync user.organizationName with membership status
              final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
              final userOrg = userData?['organizationName'] as String?;
              _syncOrganizationName(user.uid, userOrg, orgName, status);

              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // 1. Header Section
                    _ProfileHeader(
                      photoUrl: photoUrl,
                      displayName: displayName,
                      email: email,
                      organizationName: orgName,
                      membershipStatus: status,
                      onSelectOrganization: () => _selectOrganization(user),
                      onLeaveOrCancel: () => _confirmLeaveOrCancel(context, membershipId, status),
                    ),

                    const SizedBox(height: 24),

                    // 2. Menu Section: General
                    _ProfileSection(
                      title: l10n.get('general'),
                      children: [
                        _ProfileMenuItem(
                          icon: Icons.notifications_none_rounded,
                          iconColor: Colors.orange,
                          title: l10n.get('notifications'),
                          onTap: () {},
                        ),
                        _ProfileMenuItem(
                          icon: Icons.language_rounded,
                          iconColor: Colors.purple,
                          title: l10n.get('language'),
                          trailingText: _getLanguageName(Localizations.localeOf(context).languageCode),
                          onTap: () => _showLanguageSelector(context),
                          isLast: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // 3. Menu Section: Support & Legal
                    _ProfileSection(
                      title: l10n.get('supportLegal'),
                      children: [
                        _ProfileMenuItem(
                          icon: Icons.description_outlined,
                          iconColor: Colors.blue,
                          title: l10n.get('termsOfUse'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const TermsOfUsePage()),
                          ),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.lock_outline_rounded,
                          iconColor: Colors.teal,
                          title: l10n.get('privacyPolicy'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyPage()),
                          ),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.help_outline_rounded,
                          iconColor: Colors.indigo,
                          title: l10n.get('faq'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FaqPage()),
                          ),
                        ),
                        _ProfileMenuItem(
                          icon: Icons.info_outline_rounded,
                          iconColor: Colors.grey.shade700,
                          title: l10n.get('aboutApp'),
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
                          child: Text(
                            l10n.get('logOut'),
                            style: const TextStyle(
                              color: _kDangerColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fil': return 'Filipino';
      case 'ja': return 'Japanese';
      case 'ko': return 'Korean';
      default: return 'English';
    }
  }
}

// ---------------- CUSTOM WIDGETS ----------------

class _LanguageItem extends StatelessWidget {
  final Locale locale;
  final String name;

  const _LanguageItem({required this.locale, required this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      onTap: () {
        context.read<LocaleProvider>().setLocale(locale);
        Navigator.pop(context);
      },
      trailing: Localizations.localeOf(context).languageCode == locale.languageCode
          ? const Icon(Icons.check, color: Colors.blue)
          : null,
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String? photoUrl;
  final String displayName;
  final String email;
  final String? organizationName;
  final String? membershipStatus;
  final VoidCallback onSelectOrganization;
  final VoidCallback onLeaveOrCancel;

  const _ProfileHeader({
    required this.photoUrl,
    required this.displayName,
    required this.email,
    required this.organizationName,
    required this.membershipStatus,
    required this.onSelectOrganization,
    required this.onLeaveOrCancel,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasOrg = organizationName != null && organizationName!.isNotEmpty;
    final bool isPending = membershipStatus == 'pending';
    final bool isKicked = membershipStatus == 'kicked';
    final bool isDeclined = membershipStatus == 'declined';
    final l10n = AppLocalizations.of(context);

    String statusText = "";
    Color statusColor = _kPrimaryColor;
    Color bgColor = _kPrimaryColor.withOpacity(0.08);
    Color borderColor = _kPrimaryColor.withOpacity(0.1);

    if (hasOrg) {
      if (isPending) {
        statusText = " (Pending)";
        statusColor = Colors.orange.shade800;
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
      } else if (isKicked) {
        statusText = " (Kicked)";
        statusColor = _kDangerColor;
        bgColor = Colors.red.shade50;
        borderColor = _kDangerColor.withOpacity(0.3);
      } else if (isDeclined) {
        statusText = " (Declined)";
        statusColor = _kDangerColor;
        bgColor = Colors.red.shade50;
        borderColor = _kDangerColor.withOpacity(0.3);
      }
    } else {
      statusColor = _kDangerColor;
      bgColor = Colors.red.shade50;
      borderColor = _kDangerColor.withOpacity(0.3);
    }

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
          onTap: hasOrg ? onLeaveOrCancel : onSelectOrganization,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!hasOrg) ...[
                  const Icon(Icons.add_business_rounded, size: 16, color: _kDangerColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  hasOrg ? "$organizationName$statusText" : l10n.get('selectOrganization'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (hasOrg) ...[
                  const SizedBox(width: 6),
                  Icon(
                    isPending ? Icons.close_rounded : (isKicked || isDeclined ? Icons.delete_outline : Icons.logout_rounded),
                    size: 16,
                    color: statusColor,
                  ),
                ],
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
