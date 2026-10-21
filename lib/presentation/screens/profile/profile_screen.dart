import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sekolahbinekas/presentation/routes/app_routes.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'package:sekolahbinekas/presentation/screens/profile/profile_logic.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String displayName = "Loading...";
  final TextEditingController _nameController = TextEditingController();
  ImageProvider profileImage = AssetImage('assets/images/profile.jpg');
  File? _selectedImage; // picked image file
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final user = await UserDatabase().getCurrentUserData();
      if (user != null) {
        setState(() {
          displayName = user.display_name;
          _nameController.text = displayName;
          profileImage = user.profile_picture != null
              ? NetworkImage(user.profile_picture!)
              : AssetImage('assets/images/profile.jpg');
        });
      }
    } catch (e) {
      print("Error loading user: $e");
    }
  }

  Future<void> _updateProfile() async {
    String newDisplayName = _nameController.text.trim();

    if (newDisplayName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Display name cannot be empty')));
      return;
    }

    try {
      // ✅ Use your logic to update both display name and image
      await ProfileLogic().updateProfile(newDisplayName, _selectedImage);

      setState(() {
        displayName = newDisplayName;
        if (_selectedImage != null) {
          profileImage = FileImage(_selectedImage!);
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      print("Error updating profile: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile')));
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFile(
      type: FileType.image, // restrict to images
    );

    if (result != null && result.path != null) {
      setState(() {
        _selectedImage = File(result.path!);
        profileImage = FileImage(_selectedImage!);
      });
    }
  }

  Future<void> _openWhatsApp() async {
    const phoneNumber = "6281316555067";
    const message = "Halo, saya ingin bertanya.";
    final url = "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      throw "Could not launch WhatsApp";
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 1) {
      _openWhatsApp();
      return;
    }

    if (index == 0) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    if (index == 2) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Public Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 1,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card container for better visual grouping
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
                      child: Column(
                        children: [
                          // Avatar with edit overlay
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                CircleAvatar(
                                  radius: 56,
                                  backgroundImage: profileImage,
                                  backgroundColor: Colors.blue.shade50,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap avatar to change photo',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue[600]),
                          ),
                          const SizedBox(height: 18),
                          // Input field
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Display Name',
                              prefixIcon: Icon(Icons.person_outline),
                              filled: true,
                              fillColor: Colors.blue[50],
                              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _updateProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.headset_mic), label: "CS"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}