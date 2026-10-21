import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/change_shift_request_database.dart';
import '../../../data/shift_database.dart';
import '../../../data/user_database.dart';
import '../../../models/change_shift_request.dart';
import '../../../models/shift.dart';
import '../../../models/user.dart';

class ChangeShiftApprovalDetailScreen extends StatefulWidget {
  final ChangeShiftRequest request;
  final bool showDecisionButtons;

  const ChangeShiftApprovalDetailScreen({
    super.key,
    required this.request,
    this.showDecisionButtons = true,
  });

  @override
  State<ChangeShiftApprovalDetailScreen> createState() =>
      _ChangeShiftApprovalDetailScreenState();
}

class _ChangeShiftApprovalDetailScreenState
    extends State<ChangeShiftApprovalDetailScreen> {
  bool _saving = false;
  late DateTime _attendanceDate;
  String? _checkIn;
  String? _checkOut;
  late Future<_RequestDetails> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _attendanceDate = widget.request.attendanceDate;
    _checkIn = widget.request.checkIn;
    _checkOut = widget.request.checkOut;
    _detailsFuture = _loadDetails();
  }

  Future<_RequestDetails> _loadDetails() async {
    final details = await Future.wait<Object?>([
      UserDatabase().getUserPublicDataByAuthId(widget.request.authId),
      ShiftDatabase().getShiftById(widget.request.shiftId),
    ]);
    return _RequestDetails(
      user: details[0] as User?,
      shift: details[1] as Shift?,
    );
  }

  Future<void> _decide(bool approved) async {
    setState(() => _saving = true);
    try {
      final updated = await ChangeShiftRequestDatabase()
          .approveChangeShiftRequest(widget.request.id, approved);
      if (!mounted) return;
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot decide this request.')),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approved ? 'Request approved.' : 'Request rejected.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _approvalStatus(bool? status) {
    if (status == null) return 'Pending';
    return status ? 'Approved' : 'Rejected';
  }

  Future<void> _editAttendanceDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select attendance date',
    );
    if (selected == null || !mounted) return;

    setState(() => _saving = true);
    try {
      final updated = await ChangeShiftRequestDatabase()
          .updateChangeShiftRequestDate(widget.request.id, selected);
      if (!mounted) return;
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot update this request.')),
        );
        return;
      }
      setState(() => _attendanceDate = selected);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Attendance date updated.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update attendance date: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return null;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _editCheckTimes() async {
    var checkInValue = _checkIn;
    var checkOutValue = _checkOut;

    Future<void> pickTime({
      required bool isCheckIn,
      required StateSetter setDialogState,
    }) async {
      final currentValue = isCheckIn ? checkInValue : checkOutValue;
      final selected = await showTimePicker(
        context: context,
        initialTime: _parseTime(currentValue) ?? TimeOfDay.now(),
      );
      if (selected == null) return;
      setDialogState(() {
        final formattedTime = _formatTime(selected);
        if (isCheckIn) {
          checkInValue = formattedTime;
        } else {
          checkOutValue = formattedTime;
        }
      });
    }

    final values = await showDialog<Map<String, String?>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Update attendance hours'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: ValueKey('check-in-$checkInValue'),
                initialValue: checkInValue ?? '',
                readOnly: true,
                onTap: () =>
                    pickTime(isCheckIn: true, setDialogState: setDialogState),
                decoration: InputDecoration(
                  labelText: 'Check-in',
                  hintText: 'Select time',
                  prefixIcon: const Icon(Icons.login),
                  suffixIcon: IconButton(
                    onPressed: () => setDialogState(() => checkInValue = null),
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear check-in',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey('check-out-$checkOutValue'),
                initialValue: checkOutValue ?? '',
                readOnly: true,
                onTap: () =>
                    pickTime(isCheckIn: false, setDialogState: setDialogState),
                decoration: InputDecoration(
                  labelText: 'Check-out',
                  hintText: 'Select time',
                  prefixIcon: const Icon(Icons.logout),
                  suffixIcon: IconButton(
                    onPressed: () => setDialogState(() => checkOutValue = null),
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear check-out',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'checkIn': checkInValue,
                'checkOut': checkOutValue,
              }),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (values == null || !mounted) return;
    setState(() => _saving = true);
    try {
      final updated = await ChangeShiftRequestDatabase()
          .updateChangeShiftRequestTimes(
            widget.request.id,
            values['checkIn'],
            values['checkOut'],
          );
      if (!mounted) return;
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot update this request.')),
        );
        return;
      }
      setState(() {
        _checkIn = values['checkIn'];
        _checkOut = values['checkOut'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendance hours updated.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update attendance hours: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openAttachment() async {
    final url = widget.request.fileUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Attachment link is unavailable.')),
        );
      }
      return;
    }

    final imagePath = uri.path.toLowerCase();
    final isImage = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
    ].any(imagePath.endsWith);
    if (isImage) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not preview this image.'),
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this attachment.')),
        );
      }
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Shift Request Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<_RequestDetails>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load request details: ${snapshot.error}'),
            );
          }
          final details = snapshot.data!;
          final user = details.user;
          final shift = details.shift;
          final profilePicture = user?.profile_picture;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: Colors.blue.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage:
                            profilePicture != null && profilePicture.isNotEmpty
                            ? NetworkImage(profilePicture)
                            : const AssetImage('assets/images/profile.jpg')
                                  as ImageProvider,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user?.display_name ?? request.authId,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DetailRow(
                        label: 'Attendance date',
                        value: MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(_attendanceDate),
                      ),
                      _DetailRow(
                        label: 'Shift',
                        value: shift == null
                            ? 'Shift information unavailable'
                            : shift.name,
                      ),
                      _DetailRow(label: 'Reason', value: request.reason),
                      _DetailRow(
                        label: 'Check-in',
                        value: _checkIn ?? 'Not provided',
                      ),
                      _DetailRow(
                        label: 'Check-out',
                        value: _checkOut ?? 'Not provided',
                      ),
                      if (widget.showDecisionButtons)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _saving ? null : _editAttendanceDate,
                              icon: const Icon(Icons.edit_calendar),
                              label: const Text('Edit date'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _saving ? null : _editCheckTimes,
                              icon: const Icon(Icons.schedule),
                              label: const Text('Edit hours'),
                            ),
                          ],
                        ),
                      if (request.fileUrl.trim().isNotEmpty)
                        OutlinedButton.icon(
                          onPressed: _saving ? null : _openAttachment,
                          icon: const Icon(
                            Icons.attach_file,
                            color: Colors.blue,
                          ),
                          label: Text(
                            _isImageUrl(request.fileUrl)
                                ? 'Preview attachment image'
                                : 'Open attachment',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                          ),
                        )
                      else
                        const _DetailRow(
                          label: 'Attachment',
                          value: 'No attachment provided',
                        ),
                      _DetailRow(
                        label: 'Approval line',
                        value: _approvalStatus(
                          request.isApprovedByApprovalLine,
                        ),
                      ),
                      if (shift?.requireHrApproval == true)
                        _DetailRow(
                          label: 'HR approval',
                          value: _approvalStatus(request.isApprovedByHr),
                        ),
                    ],
                  ),
                ),
              ),
              if (widget.showDecisionButtons) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : () => _decide(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _decide(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  bool _isImageUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].any(path.endsWith);
  }
}

class _RequestDetails {
  final User? user;
  final Shift? shift;

  const _RequestDetails({required this.user, required this.shift});
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 3),
          SelectableText(value),
        ],
      ),
    );
  }
}
