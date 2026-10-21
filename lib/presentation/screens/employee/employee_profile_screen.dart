import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../data/employee_private_database.dart';
import '../../../data/employee_public_database.dart';
import '../../../data/employee_public_pending_database.dart';
import '../../../data/user_database.dart';
import '../../../models/employee_private.dart';
import '../../../models/employee_public.dart';
import '../../../models/employee_public_pending.dart';
import '../../../models/user.dart';

class EmployeeProfileScreen extends StatefulWidget {
  const EmployeeProfileScreen({super.key});

  @override
  State<EmployeeProfileScreen> createState() => _EmployeeProfileScreenState();
}

class _EmployeeProfileScreenState extends State<EmployeeProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthPlaceController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _genderController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _bloodTypeController = TextEditingController();
  final _religionController = TextEditingController();
  final _nikController = TextEditingController();

  static const _genderOptions = ['Male', 'Female', 'Other'];
  static const _maritalStatusOptions = [
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];
  static const _bloodTypeOptions = ['A', 'B', 'AB', 'O'];
  static const _religionOptions = [
    'Islam',
    'Christianity',
    'Catholicism',
    'Hinduism',
    'Buddhism',
    'Confucianism',
    'Other',
  ];

  EmployeePrivate? _privateData;
  EmployeePublic? _publicData;
  EmployeePublicPending? _pendingData;
  User? _userData;
  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  String? _error;

  List<TextEditingController> get _controllers => [
    _firstNameController,
    _lastNameController,
    _birthPlaceController,
    _birthDateController,
    _genderController,
    _maritalStatusController,
    _bloodTypeController,
    _religionController,
    _nikController,
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        EmployeePrivateDatabase().getMyEmployeePrivateData(),
        EmployeePublicDatabase().getMyEmployeePublicData(),
        EmployeePublicPendingDatabase().getMyEmployeePublicPendingData(),
      ]);
      User? userData;
      try {
        userData = await UserDatabase().getCurrentUserData(forceRefresh: true);
      } catch (_) {
        userData = null;
      }
      if (!mounted) return;
      setState(() {
        _privateData = results[0] as EmployeePrivate?;
        _publicData = results[1] as EmployeePublic?;
        _pendingData = results[2] as EmployeePublicPending?;
        _userData = userData;
        _fillForm(_pendingData ?? _publicData);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load employee data.';
        _loading = false;
      });
    }
  }

  void _fillForm(Object? data) {
    if (data is EmployeePublicPending) {
      _setValues(
        data.first_name,
        data.last_name,
        data.place_of_birth,
        data.date_of_birth,
        data.gender,
        data.martial_status,
        data.blood_type,
        data.religion,
        data.nik,
      );
    } else if (data is EmployeePublic) {
      _setValues(
        data.first_name,
        data.last_name,
        data.place_of_birth,
        data.date_of_birth,
        data.gender,
        data.martial_status,
        data.blood_type,
        data.religion,
        data.nik,
      );
    }
  }

  void _setValues(
    String firstName,
    String? lastName,
    String? birthPlace,
    String? birthDate,
    String? gender,
    String? maritalStatus,
    String? bloodType,
    String? religion,
    String? nik,
  ) {
    _firstNameController.text = firstName;
    _lastNameController.text = lastName ?? '';
    _birthPlaceController.text = birthPlace ?? '';
    _birthDateController.text = birthDate ?? '';
    _genderController.text = gender ?? '';
    _maritalStatusController.text = maritalStatus ?? '';
    _bloodTypeController.text = bloodType ?? '';
    _religionController.text = religion ?? '';
    _nikController.text = nik ?? '';
  }

  Future<void> _savePendingData() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final pending = EmployeePublicPending(
      id: _pendingData?.id ?? '',
      auth_id: _pendingData?.auth_id ?? '',
      first_name: _firstNameController.text.trim(),
      last_name: _lastNameController.text.trim(),
      place_of_birth: _birthPlaceController.text.trim(),
      date_of_birth: _birthDateController.text.trim(),
      gender: _genderController.text.trim(),
      martial_status: _maritalStatusController.text.trim(),
      blood_type: _bloodTypeController.text.trim(),
      religion: _religionController.text.trim(),
      nik: _nikController.text.trim(),
      isApproved: false,
    );
    final saved = await EmployeePublicPendingDatabase()
        .upsertEmployeePublicPendingData(pending);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (saved) _pendingData = pending;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Your employee data was submitted for approval.'
              : 'Could not submit employee data.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text(
            'Employee Profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }
    final privateData = _privateData;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'Employee Profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildProfileHeader(theme),
            if (privateData != null) ...[
              const SizedBox(height: 16),
              _buildEmploymentCard(privateData),
              const SizedBox(height: 16),
              _buildReportingCard(privateData),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _sectionTitle('Personal data', Icons.badge_outlined),
                ),
                Text(_isEditing ? 'Edit' : 'View'),
                Switch(
                  value: _isEditing,
                  activeThumbColor: Colors.blue,
                  inactiveThumbColor: Colors.grey,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _isEditing = value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field('First name', _firstNameController, required: true),
            _field('Last name', _lastNameController),
            _field('Place of birth', _birthPlaceController),
            _field(
              'Date of birth (YYYY-MM-DD)',
              _birthDateController,
              readOnly: !_isEditing,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                return DateTime.tryParse(value.trim()) == null
                    ? 'Use YYYY-MM-DD'
                    : null;
              },
            ),
            _dropdownField('Gender', _genderController, _genderOptions),
            _dropdownField(
              'Marital status',
              _maritalStatusController,
              _maritalStatusOptions,
            ),
            _dropdownField(
              'Blood type',
              _bloodTypeController,
              _bloodTypeOptions,
            ),
            _dropdownField('Religion', _religionController, _religionOptions),
            _field(
              'NIK',
              _nikController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 16,
              validator: (value) => value == null || value.isEmpty
                  ? 'Required'
                  : value.length != 16
                  ? 'NIK must be exactly 16 digits'
                  : null,
            ),
            if (_isEditing) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _savePendingData,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(_saving ? 'Submitting...' : 'Submit changes'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final name = [
      _firstNameController.text,
      _lastNameController.text,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final profilePicture = _userData?.profile_picture;
    final hasProfilePicture =
        profilePicture != null && profilePicture.isNotEmpty;
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: theme.colorScheme.primary,
              backgroundImage: hasProfilePicture
                  ? NetworkImage(profilePicture)
                  : null,
              child: hasProfilePicture
                  ? null
                  : Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Employee' : name,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isEditing
                        ? 'Update your personal information'
                        : 'Profile overview',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) => Row(
    children: [
      Icon(icon, size: 22, color: Colors.blue),
      const SizedBox(width: 8),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
    ],
  );

  Widget _buildEmploymentCard(EmployeePrivate data) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Employment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _info('Organization', data.organization?.name),
          _info('Position', data.job_position?.name),
          _info('Level', data.job_level?.name),
          _info('Status', data.employment_status),
          _info('Join date', _formatDate(data.join_date)),
        ],
      ),
    ),
  );

  Widget _buildReportingCard(EmployeePrivate data) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Reporting line', Icons.account_tree_outlined),
          const SizedBox(height: 16),
          _personTile('Manager', data.manager),
          const Divider(height: 24),
          _personTile('Approval line', data.approval_line),
        ],
      ),
    ),
  );

  Widget _personTile(String label, dynamic user) {
    final displayName = user?.display_name as String?;
    final picture = user?.profile_picture as String?;
    final hasPicture = picture != null && picture.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: hasPicture ? NetworkImage(picture) : null,
          child: hasPicture ? null : const Icon(Icons.person_outline),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(
                displayName?.isNotEmpty == true ? displayName! : 'Not assigned',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = false,
    String? Function(String?)? validator,
    bool readOnly = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        counterText: maxLength == null ? null : '',
      ),
      readOnly: readOnly || !_isEditing,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      validator:
          validator ??
          (required
              ? (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null
              : null),
    ),
  );

  Widget _dropdownField(
    String label,
    TextEditingController controller,
    List<String> options,
  ) {
    final values = [...options];
    if (controller.text.isNotEmpty && !values.contains(controller.text)) {
      values.insert(0, controller.text);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: controller.text.isEmpty ? null : controller.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: values
            .map((value) => DropdownMenuItem(value: value, child: Text(value)))
            .toList(),
        onChanged: !_isEditing
            ? null
            : (value) => setState(() => controller.text = value ?? ''),
        validator: (value) =>
            value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _info(String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value?.isNotEmpty == true ? value! : '-')),
      ],
    ),
  );

  String _formatDate(DateTime? date) =>
      date == null ? '-' : DateFormat.yMMMd().format(date);
}
