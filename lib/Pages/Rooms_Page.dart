import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Import for Timer
import 'RoomDetails_Page.dart'; // Import Details Page
import '../l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase
  await Firebase.initializeApp();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RoomsPage(),
  ));
}

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late Stream<DocumentSnapshot> _userStream;
  Timer? _debounce; // Timer for debounce

  // Filter States
  String? _selectedAvailability;
  String? _selectedType;
  String? _selectedBuilding;
  String? _selectedFloor;

  @override
  void initState() {
    super.initState();
    _signInAnonymously();
    _initUserStream();
  }

  void _initUserStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
    } else {
      _userStream = const Stream.empty();
    }
  }

  Future<void> _signInAnonymously() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _initUserStream();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Cancel timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, userDocSnapshot) {
          if (userDocSnapshot.hasError) {
            return Center(
                child: Text('Error loading profile: ${userDocSnapshot.error}'));
          }

          if (userDocSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData =
              userDocSnapshot.data?.data() as Map<String, dynamic>?;
          final organizationName = userData?['organizationName'] as String?;

          return Column(
            children: [
              /* SEARCH BAR & FILTER */
              Container(
                color: Colors.white,
                padding: EdgeInsets.fromLTRB(16, topPadding + 14, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (organizationName != null && organizationName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Text(
                          organizationName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) _debounce!.cancel();
                              _debounce = Timer(const Duration(milliseconds: 1000), () {
                                setState(() {
                                  _query = value.trim().toLowerCase();
                                });
                              });
                            },
                            decoration: InputDecoration(
                              hintText: l10n.get('search'),
                              prefixIcon: const Icon(Icons.search),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF5F6FA),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _showFilterSheet(
                            types: [], 
                            buildings: [], 
                            floors: [],
                          ),
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F6FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.tune,
                              color: _hasActiveFilters()
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              /* ACTIVE FILTER INDICATOR */
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        l10n.get('filtersActive'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Text(
                          l10n.get('clearAll'),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),

              /* MAIN CONTENT */
              Expanded(
                child: _buildRoomList(context, organizationName),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoomList(BuildContext context, String? organizationName) {
    final l10n = AppLocalizations.of(context);

    if (organizationName == null || organizationName.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                l10n.get('noOrgSelected'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.get('selectOrgPrompt'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('organizationName', isEqualTo: organizationName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRooms = snapshot.data!.docs.map((doc) {
          return Room.fromFirestore(doc);
        }).toList();

        final filteredRooms = _filterRooms(allRooms, _query);
        final groupedRooms = _groupRoomsByType(filteredRooms);

        if (filteredRooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off,
                    size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(l10n.get('noRoomsFound'),
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: groupedRooms.length,
          itemBuilder: (context, index) {
            final entry =
                groupedRooms.entries.elementAt(index);
            return RoomTypeCard(
              type: entry.key,
              rooms: entry.value,
            );
          },
        );
      },
    );
  }

  /* ===================== LOGIC ===================== */

  bool _hasActiveFilters() {
    return _selectedAvailability != null ||
        _selectedType != null ||
        _selectedBuilding != null ||
        _selectedFloor != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedAvailability = null;
      _selectedType = null;
      _selectedBuilding = null;
      _selectedFloor = null;
    });
  }

  List<Room> _filterRooms(List<Room> rooms, String query) {
    return rooms.where((room) {
      if (query.isNotEmpty) {
        final matchesSearch = room.name.toLowerCase().contains(query) ||
            room.type.toLowerCase().contains(query) ||
            room.building.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      if (_selectedAvailability != null) {
        final l10n = AppLocalizations.of(context);
        final needsAvailable = _selectedAvailability == l10n.get('available');
        if (room.isAvailable != needsAvailable) return false;
      }

      if (_selectedType != null && room.type != _selectedType) return false;

      if (_selectedBuilding != null && room.building != _selectedBuilding) {
        return false;
      }

      if (_selectedFloor != null && room.floor != _selectedFloor) return false;

      return true;
    }).toList();
  }

  Map<String, List<Room>> _groupRoomsByType(List<Room> rooms) {
    final Map<String, List<Room>> grouped = {};
    for (final room in rooms) {
      grouped.putIfAbsent(room.type, () => []).add(room);
    }
    return grouped;
  }

  /* ===================== UI HELPERS ===================== */

  void _showFilterSheet({
    required List<String> types,
    required List<String> buildings,
    required List<String> floors,
  }) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                MediaQuery.of(context).viewInsets.bottom +25,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.get('filterRooms'),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          setModalState(() {});
                          setState(() {});
                        },
                        child: Text(l10n.get('reset')),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  _buildDropdown(
                    label: l10n.get('availability'),
                    value: _selectedAvailability,
                    items: [l10n.get('available'), l10n.get('occupied')],
                    onChanged: (val) {
                      setModalState(() => _selectedAvailability = val);
                      setState(() {});
                    },
                  ),
                  _buildDropdown(
                    label: l10n.get('type'),
                    value: _selectedType,
                    items: types,
                    capitalizeItems: true,
                    onChanged: (val) {
                      setModalState(() => _selectedType = val);
                      setState(() {});
                    },
                  ),
                  _buildDropdown(
                    label: l10n.get('building'),
                    value: _selectedBuilding,
                    items: buildings,
                    capitalizeItems: false,
                    onChanged: (val) {
                      setModalState(() => _selectedBuilding = val);
                      setState(() {});
                    },
                  ),
                  _buildDropdown(
                    label: l10n.get('floor'),
                    value: _selectedFloor,
                    items: floors,
                    capitalizeItems: false,
                    onChanged: (val) {
                      setModalState(() => _selectedFloor = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        l10n.get('done'),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool capitalizeItems = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            hint: Text('Select $label'),
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(capitalizeItems ? capitalizeFirst(item) : item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/* ===================== TYPE CARD ===================== */

class RoomTypeCard extends StatelessWidget {
  final String type;
  final List<Room> rooms;

  const RoomTypeCard({
    super.key,
    required this.type,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 5),
              child: Text(
                capitalizeFirst(type),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              children: List.generate(rooms.length, (index) {
                final isLast = index == rooms.length - 1;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RoomDetailsPage(room: rooms[index]),
                      ),
                    );
                  },
                  behavior: HitTestBehavior.opaque, // Ensures the entire row is clickable
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                    child: _RoomRow(
                      room: rooms[index],
                      colorScheme: colorScheme,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== ROOM ROW ===================== */

class _RoomRow extends StatelessWidget {
  final Room room;
  final ColorScheme colorScheme;

  const _RoomRow({
    required this.room,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.shade400;
    final l10n = AppLocalizations.of(context);
    final availabilityColor = room.isAvailable ? Colors.green : Colors.red;
    final availabilityLabel = room.isAvailable ? l10n.get('available') : l10n.get('occupied');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 74,
          width: 74,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.meeting_room,
            size: 32,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 74,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      capitalizeFirst(room.type),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${room.building} • ${room.floor}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: availabilityColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          availabilityLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: availabilityColor,
                          ),
                        ),
                      ),
                      // Display first 1 tag only
                      ...room.tags.take(1).map((tag) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tag.icon,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      )),
                      // If more than 1 tag, show remaining count
                      if (room.tags.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: borderColor),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${room.tags.length - 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/* ===================== DATA MODELS ===================== */

String capitalizeFirst(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class Room {
  final String id;
  final String name;
  final String type;
  final String building;
  final String floor;
  final bool isAvailable;
  final List<RoomTag> tags;
  final String description;
  final int capacity;
  final Map<String, dynamic> bookingRules;
  final Map<String, dynamic> availability;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.building,
    required this.floor,
    required this.isAvailable,
    required this.tags,
    required this.description,
    required this.capacity,
    required this.bookingRules,
    required this.availability,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 1. Parse Location (Map)
    final location = data['location'] as Map<String, dynamic>? ?? {};
    final building = location['building'] as String? ?? 'Unknown';
    final floor = location['floor'] as String? ?? '';

    // 2. Parse Status (String)
    // "available" -> true, "maintenance"/"occupied" -> false
    final status = (data['status'] as String? ?? '').toLowerCase();
    final isAvailable = status == 'available';

    // 3. Parse Tags (Array of Strings)
    List<RoomTag> parsedTags = [];
    if (data['tags'] != null) {
      final tagsList = List<String>.from(data['tags']);
      parsedTags = tagsList.map((featureName) {
        return RoomTag(
          label: featureName,
          icon: _getIconForFeature(featureName),
        );
      }).toList();
    }

    return Room(
      id: doc.id,
      name: data['name'] ?? 'Unknown Room',
      type: data['type'] ?? 'General',
      building: building,
      floor: floor,
      isAvailable: isAvailable,
      tags: parsedTags,
      description: data['description'] ?? '',
      capacity: data['capacity'] ?? 0,
      bookingRules: data['bookingRules'] as Map<String, dynamic>? ?? {},
      availability: data['availability'] as Map<String, dynamic>? ?? {},
    );
  }
}

// Helper to map string features from DB to Icons
IconData _getIconForFeature(String feature) {
  final f = feature.toLowerCase();
  if (f.contains('projector')) return Icons.videocam;
  if (f.contains('ac') || f.contains('air-con')) return Icons.ac_unit;
  if (f.contains('whiteboard')) return Icons.edit_square;
  if (f.contains('tv')) return Icons.tv;
  if (f.contains('wifi')) return Icons.wifi;
  if (f.contains('computer') || f.contains('pc')) return Icons.computer;
  if (f.contains('sound') || f.contains('speaker')) return Icons.speaker;
  if (f.contains('lab') || f.contains('equipment')) return Icons.science;
  return Icons.star_outline;
}

class RoomTag {
  final IconData icon;
  final String label;

  RoomTag({
    required this.icon,
    required this.label,
  });
}