import 'package:flutter/material.dart';
import '../../../data/change_shift_request_database.dart';
import '../../../data/user_database.dart';
import '../../../models/change_shift_request.dart';
import 'change_shift_approval_detail_screen.dart';

class ChangeShiftApprovalScreen extends StatefulWidget {
  const ChangeShiftApprovalScreen({super.key});

  @override
  State<ChangeShiftApprovalScreen> createState() =>
      _ChangeShiftApprovalScreenState();
}

class _ChangeShiftApprovalScreenState extends State<ChangeShiftApprovalScreen> {
  late Future<List<ChangeShiftRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _requests = ChangeShiftRequestDatabase()
        .getChangeShiftRequestsRequiringMyApproval();
  }

  void _reload() {
    setState(() {
      _requests = ChangeShiftRequestDatabase()
          .getChangeShiftRequestsRequiringMyApproval();
    });
  }

  Future<void> _openDetails(ChangeShiftRequest request) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeShiftApprovalDetailScreen(request: request),
      ),
    );
    if (updated == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Shift Approvals',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<ChangeShiftRequest>>(
        future: _requests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load requests: ${snapshot.error}'),
            );
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(
              child: Text('No requests require your approval.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                child: FutureBuilder(
                  future: UserDatabase().getUserPublicDataByAuthId(
                    request.authId,
                  ),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    final displayName = user?.display_name ?? request.authId;
                    final profilePicture = user?.profile_picture;
                    return ListTile(
                      onTap: () => _openDetails(request),
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 26,
                        backgroundImage:
                            profilePicture != null && profilePicture.isNotEmpty
                            ? NetworkImage(profilePicture)
                            : const AssetImage('assets/images/profile.jpg')
                                  as ImageProvider,
                        onBackgroundImageError: profilePicture != null
                            ? (_, _) {}
                            : null,
                      ),
                      title: Text(displayName),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          request.reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.blue,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
