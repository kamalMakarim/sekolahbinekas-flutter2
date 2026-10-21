import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sekolahbinekas/data/absen_logic.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class AbsenScreen extends StatefulWidget {
  const AbsenScreen({super.key});

  @override
  State<AbsenScreen> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<AbsenScreen> {
  Map<String, dynamic>? _todayAttendance;
  Map<String, bool?> _selfieVerification = {};
  bool _isLoading = true;
  bool _isNavigating = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _monthlyAttendance = [];
  Set<DateTime> _attendedDates = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    initializeDateFormatting('id_ID', null).then((_) {
      _loadAttendance();
      _loadMonthlyAttendance(_focusedDay);
    });
  }

  Future<void> _loadAttendance() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      AbsenLogic().getTodayAttendance(),
      AbsenLogic().getTodaySelfieVerification(),
    ]);

    setState(() {
      _todayAttendance = results[0];
      _selfieVerification = Map<String, bool?>.from(results[1] as Map);
      _isLoading = false;
    });
  }

  Future<void> _reloadData() async {
    await Future.wait([_loadAttendance(), _loadMonthlyAttendance(_focusedDay)]);
  }

  Future<Position?> _getLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage('GPS tidak aktif, aktifkan GPS terlebih dahulu');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showMessage('Izin lokasi ditolak');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showMessage('Izin lokasi ditolak permanen, ubah di pengaturan');
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  bool _isAtSchoolLocation(Position position) {
    const schoolLat = -6.96144;
    const schoolLng = 107.64263;
    const radiusInMeters = 44;

    final distanceInMeters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      schoolLat,
      schoolLng,
    );

    return distanceInMeters <= radiusInMeters;
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _takeAttendance(String recordType) async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      final position = await _getLocation();
      if (position == null) return;

      if (!_isAtSchoolLocation(position)) {
        _showMessage(
          'Anda tidak berada disekolah',
          backgroundColor: Colors.red,
        );
        return;
      }

      _showMessage('Anda berada di sekolah', backgroundColor: Colors.green);

      final image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      if (image == null) return;

      final selfieUrl = await AbsenLogic().uploadSelfie(File(image.path));
      if (selfieUrl == null) throw Exception('Gagal upload foto');

      await AbsenLogic().submitSelfieAttendance(
        selfieUrl: selfieUrl,
        locationLat: position.latitude,
        locationLng: position.longitude,
        recordType: recordType,
      );

      _showMessage(
        recordType == 'IN'
            ? 'Check In berhasil, menunggu verifikasi admin'
            : 'Check Out berhasil, menunggu verifikasi admin',
        backgroundColor: Colors.green,
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      await _reloadData();
    } catch (error) {
      _showMessage(
        'Gagal menyimpan absen: $error',
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }
  }

  Future<void> _loadMonthlyAttendance(DateTime month) async {
    final data = await AbsenLogic().getMonthlyAttendance(month);

    Set<DateTime> attended = {};
    for (var record in data) {
      if (record['check_in'] != null) {
        DateTime date = DateTime.parse(record['attendance_date']);
        attended.add(DateTime.utc(date.year, date.month, date.day));
      }
    }

    setState(() {
      _monthlyAttendance = data;
      _attendedDates = attended;
    });
  }

  bool _isPending(String recordType) =>
      _selfieVerification.containsKey(recordType) &&
      _selfieVerification[recordType] == null;

  bool _isRejected(String recordType) =>
      _selfieVerification[recordType] == false;

  bool get _isPendingIn => _isPending('IN');
  bool get _isPendingOut => _isPending('OUT');

  bool get _hasCheckedOut =>
      (_todayAttendance != null && _todayAttendance!['check_out'] != null) ||
      _isPendingOut;

  bool get _canCheckOut =>
      _todayAttendance != null &&
      _todayAttendance!['check_in'] != null &&
      !_hasCheckedOut &&
      !_isLoading;

  bool get _hasCheckedIn =>
      (_todayAttendance != null && _todayAttendance!['check_in'] != null) ||
      _isPendingIn;

  bool get _canCheckIn => !_hasCheckedIn && !_isLoading;

  String get _statusText {
    if (_isPendingIn) return 'Verifying Check In, please refresh';
    if (_isPendingOut) return 'Verifying Check Out, please refresh';
    if (_isRejected('IN')) return 'Check In ditolak, silakan ambil foto lagi';
    if (_isRejected('OUT')) return 'Check Out ditolak, silakan ambil foto lagi';
    if (_todayAttendance == null) return 'Belum absen hari ini';
    if (_todayAttendance!['check_out'] != null) {
      return 'Sudah Check In & Check Out';
    }

    if (_todayAttendance!['check_in'] != null) {
      return 'Sudah Check In, belum Check Out';
    }

    return 'Belum absen hari ini';
  }

  String _formatTime(String? time) {
    if (time == null) {
      return '';
    }

    return time.substring(0, 5);
  }

  String _formatMethod(String? method) {
    if (method == null) {
      return '';
    }

    if (method == 'fingerprint') {
      return 'Fingerprint';
    }

    if (method == 'selfie') {
      return 'Selfie';
    }

    return method;
  }

  String _checkInInfo() {
    if (_isPendingIn) {
      return 'Menunggu verifikasi...';
    }

    if (_todayAttendance?['check_in'] != null) {
      final time = _formatTime(_todayAttendance!['check_in']);
      final method = _formatMethod(_todayAttendance!['check_in_method']);
      return '$method | $time WIB';
    }

    if (_isRejected('IN')) {
      return 'Wajah tidak cocok, ambil foto lagi';
    }

    return '';
  }

  String _checkOutInfo() {
    if (_isPendingOut) {
      return 'Menunggu verifikasi...';
    }

    if (_todayAttendance?['check_out'] != null) {
      final time = _formatTime(_todayAttendance!['check_out']);
      final method = _formatMethod(_todayAttendance!['check_out_method']);
      return '$method | $time WIB';
    }

    if (_isRejected('OUT')) {
      return 'Wajah tidak cocok, ambil foto lagi';
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: const Text('Absen', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TableCalendar(
                locale: 'id_ID', // pake intl dan date_symbol_data_local
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                  _loadMonthlyAttendance(focusedDay);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    DateTime normalizedDay = DateTime.utc(
                      day.year,
                      day.month,
                      day.day,
                    );

                    // jika hari ini, pake style default kalender biru tipis
                    if (isSameDay(day, DateTime.now())) return null;

                    // jika tanggal tersebut ada di daftar absen pake warna hijau
                    if (_attendedDates.contains(normalizedDay)) {
                      return Container(
                        margin: const EdgeInsets.all(6.0),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade400),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _statusText,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 24),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Check In
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Check In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canCheckIn
                              ? Colors.blue
                              : Colors.grey.shade300,
                          foregroundColor: _canCheckIn
                              ? Colors.white
                              : Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _canCheckIn && !_isNavigating
                            ? () => _takeAttendance('IN')
                            : null,
                      ),
                      if (_checkInInfo().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _checkInInfo(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPendingIn
                                  ? Colors.orange.shade700
                                  : _isRejected('IN')
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // cek out
                Expanded(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Check Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canCheckOut
                              ? Colors.orange
                              : Colors.grey.shade300,
                          foregroundColor: _canCheckOut
                              ? Colors.white
                              : Colors.grey.shade500,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _canCheckOut && !_isNavigating
                            ? () => _takeAttendance('OUT')
                            : null,
                      ),
                      if (_checkOutInfo().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _checkOutInfo(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _isPendingOut
                                  ? Colors.orange.shade700
                                  : _isRejected('OUT')
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Muat ulang data'),
              onPressed: _isNavigating ? null : _reloadData,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
