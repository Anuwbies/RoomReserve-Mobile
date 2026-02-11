import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/fcm_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _notificationsEnabled = true;
  bool _showInApp = true;
  bool _enableSound = true;
  bool _enableVibration = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('fcm_enabled') ?? true;
      _showInApp = prefs.getBool('fcm_show_in_app') ?? true;
      _enableSound = prefs.getBool('fcm_enable_sound') ?? true;
      _enableVibration = prefs.getBool('fcm_enable_vibration') ?? true;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'fcm_enabled') _notificationsEnabled = value;
      if (key == 'fcm_show_in_app') _showInApp = value;
      if (key == 'fcm_enable_sound') _enableSound = value;
      if (key == 'fcm_enable_vibration') _enableVibration = value;
    });

    if (key == 'fcm_enabled' && value == true) {
      FCMService.initialize();
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
    }
  }

  /// TEST: Injects all possible notification types into Firestore for UI testing
  Future<void> _addSampleNotifications() async {
    if (user == null) return;
    final l10n = AppLocalizations.of(context);
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('notifications');

    final samples = [
      {
        'titleKey': 'notif_org_approved_title',
        'bodyKey': 'notif_org_approved_body',
        'type': 'organization',
      },
      {
        'titleKey': 'notif_org_declined_title',
        'bodyKey': 'notif_org_declined_body',
        'type': 'organization',
      },
      {
        'titleKey': 'notif_org_removed_title',
        'bodyKey': 'notif_org_removed_body',
        'type': 'organization',
      },
      {
        'titleKey': 'notif_booking_approved_title',
        'bodyKey': 'notif_booking_approved_body',
        'type': 'booking',
      },
      {
        'titleKey': 'notif_booking_declined_title',
        'bodyKey': 'notif_booking_declined_body',
        'type': 'booking',
      },
      {
        'titleKey': 'notif_booking_cancelled_title',
        'bodyKey': 'notif_booking_cancelled_body',
        'type': 'booking',
      },
      {
        'titleKey': 'notif_booking_completed_title',
        'bodyKey': 'notif_booking_completed_body',
        'type': 'booking',
      },
      {
        'titleKey': 'notif_upcoming_title',
        'bodyKey': 'notif_upcoming_body',
        'type': 'booking',
      },
      {
        'titleKey': 'notif_room_added_title',
        'bodyKey': 'notif_room_added_body',
        'type': 'room_added',
      },
    ];

    for (var sample in samples) {
      await collection.add({
        ...sample,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('sampleNotifAdded'), textAlign: TextAlign.center),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        ),
      );
    }
  }

  void _showSettingsSheet() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.get('notificationSettings'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwitchListTile(
                            title: Text(l10n.get('enableNotifications')),
                            subtitle: Text(l10n.get('enableNotificationsSubtitle')),
                            value: _notificationsEnabled,
                            onChanged: (val) async {
                              await _updateSetting('fcm_enabled', val);
                              setModalState(() {});
                            },
                          ),
                          const Divider(),
                          IgnorePointer(
                            ignoring: !_notificationsEnabled,
                            child: Opacity(
                              opacity: _notificationsEnabled ? 1.0 : 0.5,
                              child: Column(
                                children: [
                                  SwitchListTile(
                                    title: Text(l10n.get('showInAppNotifications')),
                                    subtitle: Text(l10n.get('showInAppNotificationsSubtitle')),
                                    value: _showInApp,
                                    onChanged: (val) async {
                                      await _updateSetting('fcm_show_in_app', val);
                                      setModalState(() {});
                                    },
                                  ),
                                  SwitchListTile(
                                    title: Text(l10n.get('enableNotificationSound')),
                                    value: _enableSound,
                                    onChanged: (val) async {
                                      await _updateSetting('fcm_enable_sound', val);
                                      setModalState(() {});
                                    },
                                  ),
                                  SwitchListTile(
                                    title: Text(l10n.get('enableNotificationVibration')),
                                    subtitle: Text(l10n.get('enableNotificationVibrationSubtitle')),
                                    value: _enableVibration,
                                    onChanged: (val) async {
                                      await _updateSetting('fcm_enable_vibration', val);
                                      setModalState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp, AppLocalizations l10n) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) {
      return l10n.get('justNow');
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.get('minsAgo')}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${l10n.get('hrsAgo')}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ${l10n.get('daysAgo')}';
    } else {
      return DateFormat.yMMMd().format(date);
    }
  }

  Widget _buildNotificationIcon(String type, String title) {
    IconData icon;
    Color color;

    final t = title.toLowerCase();

    switch (type) {
      case 'organization':
        icon = Icons.business_rounded;
        color = t.contains('approved') ? Colors.green : (t.contains('declined') || t.contains('removed') ? Colors.red : Colors.orange);
        break;
      case 'booking':
        icon = Icons.calendar_today_rounded;
        color = t.contains('approved')
            ? Colors.blue
            : (t.contains('declined')
                ? Colors.red
                : (t.contains('completed') ? Colors.teal : Colors.orange));
        break;
      case 'room_added':
        icon = Icons.meeting_room_rounded;
        color = Theme.of(context).primaryColor;
        break;
      case 'system':
        icon = Icons.info_outline_rounded;
        color = Colors.grey;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(l10n.get('login'))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
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
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Button to add samples
                  IconButton(
                    icon: const Icon(Icons.playlist_add_rounded, color: Colors.blue),
                    onPressed: _addSampleNotifications,
                    tooltip: 'Add Samples',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: _showSettingsSheet,
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user!.uid)
                    .collection('notifications')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('${l10n.get('somethingWentWrong')}: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet', 
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      
                      // Dynamic translation logic
                      String title = data['title'] as String? ?? 'Notification';
                      String body = data['body'] as String? ?? '';
                      
                      if (data.containsKey('titleKey')) {
                        title = l10n.get(data['titleKey']);
                      }
                      if (data.containsKey('bodyKey')) {
                        body = l10n.get(data['bodyKey']);
                      }

                      final type = data['type'] as String? ?? 'general';
                      final timestamp = data['createdAt'] as Timestamp?;
                      final isRead = data['read'] as bool? ?? false;

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (direction) {
                          doc.reference.delete();
                        },
                        child: GestureDetector(
                          onTap: () {
                            if (!isRead) {
                              _markAsRead(doc.id);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: !isRead 
                                  ? Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1.5)
                                  : Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNotificationIcon(type, title),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: !isRead ? FontWeight.bold : FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              margin: const EdgeInsets.only(left: 8),
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _formatTimestamp(timestamp, l10n),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}