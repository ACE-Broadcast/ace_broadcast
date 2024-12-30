import 'package:flutter/material.dart';
import 'package:post_ace/screens/theme_selection.dart';
import 'package:post_ace/screens/selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  final bool isAdmin;
  final Function(int) onNavigationChanged;
  final int selectedIndex;
  final PageController pageController;

  const ProfilePage({
    super.key,
    required this.isAdmin,
    required this.onNavigationChanged,
    required this.selectedIndex,
    required this.pageController,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  bool isEditingSkills = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  static const Map<String, String> _defaultValues = {
    'Email': 'xyz@example.com',
    'Branch': 'Computer Engineering',
    'Skills': 'Flutter, Dart, Firebase',
  };

  final Map<String, TextEditingController> _controllers = {
    'Email': TextEditingController(),
    'Branch':
        TextEditingController(), // Just left as it is if decided to edit it

    'Skills': TextEditingController(), // this is in use
  };

  @override
  void initState() {
    super.initState();
    _defaultValues.forEach((key, value) {
      _controllers[key]?.text = value;
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleEditToggle() {
    setState(() {
      if (isEditing) {
        // TODO: Uploading the changes to the database
      }
      isEditing = !isEditing;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });
        // TODO: Upload image to storage and update user profile
        // 1. Upload image to Firebase Storage
        // 2. Get download URL
        // 3. Update user profile with new image URL
        // 4. Save URL to SharedPreferences for offline access
      }
    } catch (e) {
      // TODO: Handle error - show snackbar or toast
      print('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 60.0, 20.0, 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 60),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey[200]
                          : Theme.of(context).colorScheme.surfaceDim,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),
                        Text(
                          'User Name',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Username',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context)
                                .colorScheme
                                .inversePrimary
                                .withAlpha(153),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: _profileImage != null
                              ? FileImage(_profileImage!)
                              : null,
                          child: _profileImage == null
                              ? const Icon(Icons.person,
                                  size: 60, color: Colors.grey)
                              : null,
                        ),
                        if (isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18),
                                color: Colors.white,
                                onPressed: _pickImage,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Edit Button
                  Positioned(
                    top: 76,
                    right: 16,
                    child: IconButton(
                      icon: Icon(isEditing ? Icons.check : Icons.edit),
                      onPressed: _handleEditToggle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Personal Information Card
              Card(
                elevation: 2,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Theme.of(context).colorScheme.surfaceDim,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 25),
                          _buildInfoRow('Email', 'xyz@example.com'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Branch', 'Computer Engineering'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Posts Card
              Card(
                elevation: 2,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Theme.of(context).colorScheme.surfaceDim,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About posts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 25),
                      _buildPostButton(
                        icon: Icons.post_add,
                        label: 'My Posts',
                        onPressed: () {
                          // TODO: Handle My Posts
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildPostButton(
                        icon: Icons.bookmark,
                        label: 'Saved Posts',
                        onPressed: () {
                          // TODO: Handle Saved Posts
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Settings Card
              Card(
                elevation: 2,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey[200]
                    : Theme.of(context).colorScheme.surfaceDim,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 25),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThemeSelection(),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Theme',
                              style: TextStyle(fontSize: 18),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 15,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Clear stored credentials
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear(); // This removes all stored data

                      if (mounted) {
                        // Navigate to selection screen and remove all previous routes
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const SelectionScreen(),
                          ),
                          (route) => false, // This removes all previous routes
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildPostButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.centerLeft,
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
