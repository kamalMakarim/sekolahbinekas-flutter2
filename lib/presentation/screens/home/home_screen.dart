import 'package:flutter/material.dart';
import 'package:sekolahbinekas/presentation/routes/app_routes.dart';
import 'package:sekolahbinekas/presentation/screens/bukom/class_selection_screen.dart';
import 'package:sekolahbinekas/presentation/screens/rapor/rapor_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sekolahbinekas/data/user_database.dart';
import 'package:sekolahbinekas/models/user.dart';
import 'package:sekolahbinekas/presentation/screens/bukom/bukom_screen.dart';
import 'package:sekolahbinekas/presentation/screens/log/log_screen.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/edit_foto_kegiatan_screen.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/foto_kegiatan_screen.dart';
import 'package:sekolahbinekas/presentation/screens/fotokegiatan/add_foto_kegiatan_screen.dart';
import 'package:sekolahbinekas/presentation/screens/log/log_bs_screen.dart';
import 'package:sekolahbinekas/core/notifications_service.dart';
import 'package:sekolahbinekas/presentation/screens/absen/kalender.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? currentUser;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationsService().setupFCM();
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

  Future<void> _openWhatsApp() async {
    const phoneNumber = "6281316555067"; // Replace with your number
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
    setState(() => _selectedIndex = index);
    if (index == 1) {
      _openWhatsApp();
    }
    if (index == 2) {
      Navigator.pushReplacementNamed(context, AppRoutes.profileSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.of(context).size.width > 600 ? 100 : 80,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 40,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child:
                    currentUser?.profile_picture != null &&
                        currentUser!.profile_picture!.isNotEmpty
                    ? Image.network(
                        currentUser!.profile_picture!,
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/images/profile.jpg',
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                            ),
                      )
                    : Image.asset(
                        'assets/images/profile.jpg',
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Halo,',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                  Text(
                    currentUser?.display_name ?? 'display name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              //Icon(Icons.notifications, color: Colors.white),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                crossAxisCount: 3,
                children: [
                  HomeMenuItem(
                    icon: Icons.chat_bubble_outline,
                    label: "Bukom",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BukomScreen()),
                      );
                    },
                  ),
                  if (currentUser?.role != null &&
                      (currentUser!.role == 'bidang_study_tk' ||
                          currentUser!.role == 'bidang_study_sd'))
                    HomeMenuItem(
                      icon: Icons.chat_bubble_outline,
                      label: "Bukom Bidang Study",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClassSelectionScreen(),
                          ),
                        );
                      },
                    ),
                  HomeMenuItem(
                    icon: Icons.checklist,
                    label: "Rapor",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RaporScreen()),
                      );
                    },
                  ),
                  HomeMenuItem(
                    icon: Icons.camera_alt,
                    label: "Foto Kegiatan",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => FotoKegiatanScreen()),
                      );
                    },
                  ),
                  if (currentUser?.role != null &&
                      currentUser!.role == 'multimedia')
                    HomeMenuItem(
                      icon: Icons.delete,
                      label: "Delete Foto",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditFotoKegiatanScreen(),
                          ),
                        );
                      },
                    ),
                  if (currentUser?.role != null &&
                      currentUser!.role == 'multimedia')
                    HomeMenuItem(
                      icon: Icons.add_a_photo,
                      label: "Add Foto",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddFotoKegiatanScreen(),
                          ),
                        );
                      },
                    ),
                  if (currentUser?.role != null &&
                      [
                        'teacher',
                        'bidang_study_tk',
                        'bidang_study_sd',
                        'accountant',
                        'z_test',
                      ].contains(currentUser?.role))
                    HomeMenuItem(
                      icon: Icons.post_add,
                      label: "Log",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LogScreen()),
                        );
                      },
                    ),
                  if (currentUser?.role != null &&
                      (currentUser!.role == 'bidang_study_tk' ||
                          currentUser!.role == 'bidang_study_sd'))
                    HomeMenuItem(
                      icon: Icons.post_add,
                      label: "Log Bidang Study",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LogBsScreen()),
                        );
                      },
                    ),
                  if (currentUser?.role != null &&
                      currentUser!.role != 'parent')
                    HomeMenuItem(
                      icon: Icons.how_to_reg,
                      label: "Absen",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AbsenScreen()),
                        );
                      },
                    ),
                  if (currentUser?.role != null &&
                      currentUser!.role != 'parent')
                    HomeMenuItem(
                      icon: Icons.edit_calendar,
                      label: "Change Shift",
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.changeShiftRequest,
                      ),
                    ),
                  if (currentUser?.role != null &&
                      currentUser!.role != 'parent')
                    HomeMenuItem(
                      icon: Icons.fact_check_outlined,
                      label: "Shift Approval",
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.changeShiftApproval,
                      ),
                    ),
                ],
              ),
            ),
          ],
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

class HomeMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const HomeMenuItem({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.blue.shade50,
            child: Icon(icon, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
