import 'package:flutter/material.dart';
import 'package:sekolahbinekas/presentation/routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profileselection_logic.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'package:sekolahbinekas/models/user.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  int _selectedIndex = 2;
  User? currentUser;

  Future<void> _logout() async {
    await ProfileSelectionLogic().logout();
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _openWhatsApp() async {
    const phoneNumber = "6281316555067";
    const message = "Halo, saya ingin bertanya.";
    final url =
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}";

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
  void initState() {
    super.initState();
    UserDatabase()
        .getCurrentUserData()
        .then((user) {
          if (user != null) {
            setState(() {
              currentUser = user;
            });
          }
        })
        .catchError((error) {
          print('Error fetching user data: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    final options = <_ProfileOption>[
      const _ProfileOption(
        title: 'Public Profile',
        icon: Icons.person_outline,
        route: '/profile',
      ),
      if (currentUser?.role != 'parent')
      const _ProfileOption(
        title: 'Employee Profile',
        icon: Icons.badge_outlined,
        route: '/employee-profile',
      ),
      const _ProfileOption(
        title: 'Reset Password',
        icon: Icons.lock_outline,
        route: '/reset-password',
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...options.map(
                (option) => Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(context, option.route),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            child: Icon(option.icon, color: Colors.blue),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              option.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
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

class _ProfileOption {
  const _ProfileOption({
    required this.title,
    required this.icon,
    required this.route,
  });

  final String title;
  final IconData icon;
  final String route;
}
