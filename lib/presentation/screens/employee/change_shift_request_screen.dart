import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:sekolahbinekas/presentation/routes/app_routes.dart';
import '../../../data/change_shift_request_database.dart';
import '../../../data/image_database.dart';
import '../../../data/shift_database.dart';
import '../../../models/shift.dart';

class ChangeShiftRequestScreen extends StatefulWidget {
  const ChangeShiftRequestScreen({super.key});

  @override
  State<ChangeShiftRequestScreen> createState() =>
      _ChangeShiftRequestScreenState();
}

class _ChangeShiftRequestScreenState extends State<ChangeShiftRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _checkInController = TextEditingController();
  final _checkOutController = TextEditingController();
  late Future<List<Shift>> _shiftsFuture;
  Shift? _selectedShift;
  PlatformFile? _selectedFile;
  DateTime _attendanceDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _shiftsFuture = ShiftDatabase().getRequestableShifts();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(FileType type) async {
    final result = await FilePicker.pickFile(type: FileType.any);
    if (result != null && result.path != null) {
      setState(() => _selectedFile = result);
    }
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _attendanceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) setState(() => _attendanceDate = selected);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final filePath = _selectedFile?.path;
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a file or image.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final uploadedFiles = await ImageDatabase().uploadFiles([File(filePath)]);
      if (uploadedFiles.isEmpty) {
        throw Exception('The attachment could not be uploaded.');
      }
      await ChangeShiftRequestDatabase().addChangeShiftRequest(
        _attendanceDate,
        _selectedShift!.id,
        _reasonController.text.trim(),
        uploadedFiles.first,
        _checkInController.text.trim().isEmpty
            ? null
            : _checkInController.text.trim(),
        _checkOutController.text.trim().isEmpty
            ? null
            : _checkOutController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Change shift request submitted.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Change Shift Request',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.changeShiftStatus),
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'My requests',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              key: ValueKey(_attendanceDate),
              readOnly: true,
              initialValue: MaterialLocalizations.of(
                context,
              ).formatMediumDate(_attendanceDate),
              onTap: _saving ? null : _selectDate,
              decoration: InputDecoration(
                labelText: 'Attendance date',
                helperText: 'Tap to choose the date for this request',
                prefixIcon: const Icon(
                  Icons.calendar_month,
                  color: Colors.blue,
                ),
                suffixIcon: IconButton(
                  onPressed: _saving ? null : _selectDate,
                  icon: const Icon(Icons.edit_calendar, color: Colors.blue),
                  tooltip: 'Choose date',
                ),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            FutureBuilder<List<Shift>>(
              future: _shiftsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator();
                }
                if (snapshot.hasError) {
                  return Text('Could not load shifts: ${snapshot.error}');
                }
                final shifts = snapshot.data ?? [];
                return DropdownButtonFormField<Shift>(
                  initialValue: _selectedShift,
                  decoration: const InputDecoration(
                    labelText: 'Requested shift',
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  items: shifts
                      .map(
                        (shift) => DropdownMenuItem<Shift>(
                          value: shift,
                          child: Text('${shift.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (shift) => setState(() => _selectedShift = shift),
                  validator: (value) =>
                      value == null ? 'Select a requested shift' : null,
                );
              },
            ),
            if (_selectedShift != null) ...[
              const SizedBox(height: 8),
              Text(
                _selectedShift!.requireHrApproval
                    ? 'This request will need HR approval after approval line review.'
                    : 'This shift only needs approval from the approval line.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Reason is required'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pickFile(FileType.image),
                    icon: const Icon(Icons.image, color: Colors.blue),
                    label: const Text('Add image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : () => _pickFile(FileType.any),
                    icon: const Icon(Icons.attach_file, color: Colors.blue),
                    label: const Text('Add file'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedFile != null) ...[
              const SizedBox(height: 8),
              Text(
                'Selected: ${_selectedFile!.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.blue),
              ),
            ],
            if (_selectedFile == null) ...[
              const SizedBox(height: 8),
              const Text(
                'An image or file attachment is required.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _checkInController,
              decoration: const InputDecoration(
                labelText: 'Check-in time (optional)',
                hintText: '08:00:00',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _checkOutController,
              decoration: const InputDecoration(
                labelText: 'Check-out time (optional)',
                hintText: '16:00:00',
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(_saving ? 'Submitting...' : 'Submit request'),
            ),
          ],
        ),
      ),
    );
  }
}
