import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InsertRoomPage extends StatefulWidget {
  const InsertRoomPage({super.key});

  @override
  State<InsertRoomPage> createState() => _InsertRoomPageState();
}

class _InsertRoomPageState extends State<InsertRoomPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Dropdown State
  String? _selectedType;
  String? _selectedBuilding;
  String? _selectedFloor;

  // Features/Tags State
  final List<String> _availableFeatures = [
    'Projector',
    'Air-con',
    'Whiteboard',
    'Smart TV',
    'WiFi',
    'Computers',
    'Sound System',
    'Laboratory Eqpt.'
  ];
  final List<String> _selectedFeatures = [];

  // Mock Data for Dropdowns
  final List<String> _roomTypes = [
    'Classroom',
    'Laboratory',
    'Meeting Room',
    'Auditorium',
    'Office'
  ];
  final List<String> _buildings = [
    'PTC Building',
    'ITS Building',
    'Main Building',
    'Engineering',
    'Science Wing'
  ];
  final List<String> _floors = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    '4th Floor'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _capacityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedBuilding == null || _selectedFloor == null || _selectedType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select building, floor, and type')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // 1. Ensure User is Authenticated
        final auth = FirebaseAuth.instance;
        User? user = auth.currentUser;
        if (user == null) {
          await auth.signInAnonymously();
          user = auth.currentUser;
        }

        // 2. Prepare Data
        final newRoomData = {
          'name': _nameController.text,
          'type': _selectedType,
          'building': _selectedBuilding,
          'floor': _selectedFloor,
          'capacity': _capacityController.text,
          'features': _selectedFeatures,
          'description': _descriptionController.text,
          'createdBy': user?.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'isAvailable': true, // Default to available
        };

        // 3. Write to Firestore
        // Using strict path: /artifacts/{appId}/public/data/{collectionName}
        // Ideally, appId is passed globally. We use a default here for the snippet.
        const String appId = 'default-app-id';

        await FirebaseFirestore.instance
            .collection('artifacts')
            .doc(appId)
            .collection('public')
            .doc('data')
            .collection('rooms')
            .add(newRoomData);

        if (!mounted) return;

        // 4. Success Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room "${newRoomData['name']}" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context); // Return to previous screen

      } catch (e) {
        debugPrint('Error saving room: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Add New Room',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Basic Details'),
                const SizedBox(height: 16),

                // Room Name
                _buildLabel('Room Name / Number'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'e.g. PTC 305',
                  validator: (val) => val == null || val.isEmpty ? 'Room name is required' : null,
                ),
                const SizedBox(height: 16),

                // Building and Floor Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Building'),
                          _buildDropdown(
                            value: _selectedBuilding,
                            hint: 'Select Building',
                            items: _buildings,
                            onChanged: (val) => setState(() => _selectedBuilding = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Floor'),
                          _buildDropdown(
                            value: _selectedFloor,
                            hint: 'Select Floor',
                            items: _floors,
                            onChanged: (val) => setState(() => _selectedFloor = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type and Capacity Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Room Type'),
                          _buildDropdown(
                            value: _selectedType,
                            hint: 'Select Type',
                            items: _roomTypes,
                            onChanged: (val) => setState(() => _selectedType = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Capacity'),
                          _buildTextField(
                            controller: _capacityController,
                            hint: '0',
                            keyboardType: TextInputType.number,
                            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Amenities & Features'),
                const SizedBox(height: 12),

                // Feature Chips
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _availableFeatures.map((feature) {
                    final isSelected = _selectedFeatures.contains(feature);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedFeatures.remove(feature);
                          } else {
                            _selectedFeatures.add(feature);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                          ),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.grey.shade100,
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(Icons.check, size: 16, color: Colors.white),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              feature,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade700,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 32),
                _buildSectionHeader('Additional Info'),
                const SizedBox(height: 12),

                _buildLabel('Description (Optional)'),
                _buildTextField(
                  controller: _descriptionController,
                  hint: 'Enter any additional details about the room rules, access requirements, etc.',
                  maxLines: 4,
                ),

                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      disabledBackgroundColor: Theme.of(context).primaryColor.withOpacity(0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Create Room',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          height: 24,
          width: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(
        hint,
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontSize: 15),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1.5),
        ),
      ),
    );
  }
}