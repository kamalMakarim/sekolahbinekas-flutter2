import 'package:flutter/material.dart';
import '../../../data/change_shift_request_database.dart';
import '../../../data/shift_database.dart';
import '../../../models/change_shift_request.dart';
import '../../../models/shift.dart';
import 'change_shift_approval_detail_screen.dart';

class ChangeShiftStatusScreen extends StatefulWidget {
  const ChangeShiftStatusScreen({super.key});

  @override
  State<ChangeShiftStatusScreen> createState() =>
      _ChangeShiftStatusScreenState();
}

class _ChangeShiftStatusScreenState extends State<ChangeShiftStatusScreen> {
  late Future<List<ChangeShiftRequest>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = ChangeShiftRequestDatabase().getMyChangeShiftRequests();
  }

  void _reload() {
    setState(() {
      _requestsFuture = ChangeShiftRequestDatabase().getMyChangeShiftRequests();
    });
  }

  String _status(ChangeShiftRequest request, Shift? shift) {
    if (request.isApprovedByApprovalLine == false ||
        request.isApprovedByHr == false) {
      return 'Rejected';
    }
    if (request.isApprovedByApprovalLine == null) {
      return 'Waiting for approval line';
    }
    if (shift?.requireHrApproval == true && request.isApprovedByHr == null) {
      return 'Waiting for HR approval';
    }
    return 'Approved';
  }

  Color _statusColor(String status) {
    if (status == 'Approved') return Colors.green;
    if (status == 'Rejected') return Colors.red;
    return Colors.orange;
  }

  Future<void> _openDetails(ChangeShiftRequest request) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeShiftApprovalDetailScreen(
          request: request,
          showDecisionButtons: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'My Change Shift Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<List<ChangeShiftRequest>>(
        future: _requestsFuture,
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
              child: Text('You have no change shift requests.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final request = requests[index];
              return FutureBuilder<Shift?>(
                future: ShiftDatabase().getShiftById(request.shiftId),
                builder: (context, shiftSnapshot) {
                  final shift = shiftSnapshot.data;
                  final status = _status(request, shift);
                  return Card(
                    color: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.white),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      onTap: () => _openDetails(request),
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        shift == null
                            ? 'Shift information unavailable'
                            : shift.name,
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${MaterialLocalizations.of(context).formatMediumDate(request.attendanceDate)}\n${request.reason}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: Text(
                        status,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
