import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomsPage extends StatefulWidget {
  const RoomsPage({super.key});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Filter States
  String? _selectedAvailability;
  String? _selectedType;
  String? _selectedBuilding;
  String? _selectedFloor;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Firestore Query
    // Using strict path: /artifacts/{appId}/public/data/{collectionName}
    const String appId = 'default-app-id';
    final Stream<QuerySnapshot> roomsStream = FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('rooms')
        .orderBy('createdAt', descending: true) // Optional: Show newest first
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            /* SEARCH BAR & FILTER */
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _query = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: const Icon(Icons.search),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _showFilterSheet,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
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
            ),

            /* ACTIVE FILTER INDICATOR */
            if (_hasActiveFilters())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Filters active',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _clearFilters,
                      child: const Text(
                        'Clear all',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),

            /* ROOM LIST STREAM */
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: roomsStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 1. Convert Firestore Docs to Room Objects
                  final allRooms = snapshot.data!.docs.map((doc) {
                    return Room.fromFirestore(doc);
                  }).toList();

                  // 2. Apply Client-Side Filtering
                  final filteredRooms = _filterRooms(allRooms, _query);

                  if (filteredRooms.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey),
                          SizedBox(height: 16),
                          Text("No rooms found", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  // 3. Group by Type
                  final groupedRooms = _groupRoomsByType(filteredRooms);

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: groupedRooms.length,
                    itemBuilder: (context, index) {
                      final entry = groupedRooms.entries.elementAt(index);
                      return RoomTypeCard(
                        type: entry.key,
                        rooms: entry.value,
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
      // 1. Text Search
      if (query.isNotEmpty) {
        final matchesSearch = room.name.toLowerCase().contains(query) ||
            room.type.toLowerCase().contains(query) ||
            room.building.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      // 2. Availability Filter
      if (_selectedAvailability != null) {
        final needsAvailable = _selectedAvailability == 'Available';
        if (room.isAvailable != needsAvailable) return false;
      }

      // 3. Type Filter
      if (_selectedType != null && room.type != _selectedType) return false;

      // 4. Building Filter
      if (_selectedBuilding != null && room.building != _selectedBuilding) {
        return false;
      }

      // 5. Floor Filter
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

  void _showFilterSheet() {
    // Note: In a real app with Firestore, getting unique values for filters
    // might require a separate aggregation query or iterating the current list.
    // For simplicity, we'll keep hardcoded lists or you can derive them from 'allRooms'
    // if you pass them into this method. Here I'll use standard lists.

    final types = ['Classroom', 'Laboratory', 'Meeting Room', 'Auditorium', 'Office'];
    final buildings = ['PTC Building', 'ITS Building', 'Main Building', 'Engineering', 'Science Wing'];
    final floors = ['Ground Floor', '1st Floor', '2nd Floor', '3rd Floor', '4th Floor'];

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
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Rooms',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          _clearFilters();
                          setModalState(() {}); // Update sheet UI
                          setState(() {}); // Update parent UI
                        },
                        child: const Text('Reset'),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildDropdown(
                    label: 'Availability',
                    value: _selectedAvailability,
                    items: ['Available', 'Occupied'],
                    onChanged: (val) {
                      setModalState(() => _selectedAvailability = val);
                      setState(() {});
                    },
                  ),
                  _buildDropdown(
                    label: 'Type',
                    value: _selectedType,
                    items: types,
                    onChanged: (val) {
                      setModalState(() => _selectedType = val);
                      setState(() {});
                    },
                  ),
                  _buildDropdown(
                    label: 'Building',
                    value: _selectedBuilding,
                    items: buildings,
                    onChanged: (val) {
                      setModalState(() => _selectedBuilding = val);
                      setState(() {});
                    },
                  ),
                  _buildDropdown(
                    label: 'Floor',
                    value: _selectedFloor,
                    items: floors,
                    onChanged: (val) {
                      setModalState(() => _selectedFloor = val);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
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
                      child: const Text(
                        'Done',
                        style: TextStyle(
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
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 6),
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
                child: Text(item),
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
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 5),
              child: Text(
                type,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Column(
              children: List.generate(rooms.length, (index) {
                final isLast = index == rooms.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: _RoomRow(
                    room: rooms[index],
                    colorScheme: colorScheme,
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
    final availabilityColor = room.isAvailable ? Colors.green : Colors.red;
    final availabilityLabel = room.isAvailable ? 'Available' : 'Occupied';

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
                      room.type,
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
                      // Display first few tags
                      ...room.tags.take(3).map((tag) => Container(
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
                      if (room.tags.length > 3)
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
                            '+${room.tags.length - 3}',
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

class Room {
  final String id;
  final String name;
  final String type;
  final String building;
  final String floor;
  final bool isAvailable;
  final List<RoomTag> tags;

  Room({
    required this.id,
    required this.name,
    required this.type,
    required this.building,
    required this.floor,
    required this.isAvailable,
    required this.tags,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse Features list strings to RoomTag objects
    List<RoomTag> parsedTags = [];
    if (data['features'] != null) {
      final featuresList = List<String>.from(data['features']);
      parsedTags = featuresList.map((featureName) {
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
      building: data['building'] ?? '',
      floor: data['floor'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      tags: parsedTags,
    );
  }
}

// Helper to map string features from DB to Icons
IconData _getIconForFeature(String feature) {
  switch (feature) {
    case 'Projector': return Icons.videocam;
    case 'Air-con': return Icons.ac_unit;
    case 'Whiteboard': return Icons.edit_square;
    case 'Smart TV': return Icons.tv;
    case 'WiFi': return Icons.wifi;
    case 'Computers': return Icons.computer;
    case 'Sound System': return Icons.speaker;
    case 'Laboratory Eqpt.': return Icons.science;
    default: return Icons.star_outline;
  }
}

class RoomTag {
  final IconData icon;
  final String label;

  RoomTag({
    required this.icon,
    required this.label,
  });
}