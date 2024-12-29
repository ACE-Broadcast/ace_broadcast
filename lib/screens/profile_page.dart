import 'package:flutter/material.dart';
import 'package:post_ace/screens/theme_selection.dart';

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

  void _handleSkillsEdit() {
    setState(() {
      isEditingSkills = !isEditingSkills;
    });
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
                        const CircleAvatar(
                          radius: 60,
                          backgroundImage: AssetImage(
                              'assets/icons/avatar.avif'), // TODO: Change this to the actual profile image
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
                                onPressed: () {
                                  // TODO: Add image upload logic
                                },
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
                              IconButton(
                                icon: Icon(
                                    isEditingSkills ? Icons.check : Icons.edit),
                                onPressed: _handleSkillsEdit,
                              ),
                            ],
                          ),
                          const Divider(height: 25),
                          _buildInfoRow('Email', 'xyz@example.com'),
                          const SizedBox(height: 12),
                          _buildInfoRow('Branch', 'Computer Engineering'),
                          const SizedBox(height: 12),
                          // Special handling for Skills
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Skills',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isEditingSkills)
                                TextField(
                                  controller: _controllers['Skills'],
                                  maxLines: null,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(12),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    isDense: true,
                                  ),
                                  style: const TextStyle(fontSize: 16),
                                )
                              else
                                Text(
                                  _controllers['Skills']?.text ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                            ],
                          ),
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
                      const SizedBox(height: 12),
                      _buildPostButton(
                        icon: Icons.request_page,
                        label: 'Requests',
                        onPressed: () {
                          // TODO: Handle Requests
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildPostButton(
                        icon: Icons.bookmark,
                        label: 'Saved Posts',
                        onPressed: () {
                          // TODO: Handle Saved Posts
                        },
                      ),
                      const SizedBox(height: 12),
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
                    onPressed: () {
                      // TODO: sign out logic
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
