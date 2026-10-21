import 'package:flutter/material.dart';
import '../screens/login/login_screen.dart';
import '../screens/bukom/bukom_screen.dart';
import '../screens/bukom/bukom_bs_screen.dart';
import '../screens/bukom/class_selection_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/log/log_screen.dart';
import '../screens/onprogress/onprogress_screen.dart';
import '../screens/resetpassword/resetpassword_screen.dart';
import '../screens/fotokegiatan/foto_kegiatan_screen.dart';
import '../screens/fotokegiatan/edit_foto_kegiatan_screen.dart';
import '../screens/fotokegiatan/add_foto_kegiatan_screen.dart';
import '../screens/log/log_bs_screen.dart';
import '../screens/rapor/rapor_screen.dart';
import '../screens/profileselection/profileselection_screen.dart';
import '../screens/employee/employee_profile_screen.dart';
import '../screens/employee/change_shift_request_screen.dart';
import '../screens/employee/change_shift_approval_screen.dart';
import '../screens/employee/change_shift_status_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const bukom = '/bukom';
  static const bukomBs = '/bukom-bs';
  static const classSelection = '/class-selection';
  static const home = '/home';
  static const profile = '/profile';
  static const log = '/log';
  static const logBs = '/log-bs';
  static const onprogress = '/onprogress';
  static const resetPassword = '/reset-password';
  static const fotoKegiatan = '/foto-kegiatan';
  static const editFotoKegiatan = '/edit-foto-kegiatan';
  static const addFotoKegiatan = '/add-foto-kegiatan';
  static const rapor = '/rapor';
  static const profileSelection = '/profile-selection';
  static const employeeProfile = '/employee-profile';
  static const changeShiftRequest = '/change-shift-request';
  static const changeShiftApproval = '/change-shift-approval';
  static const changeShiftStatus = '/change-shift-status';

  static final routes = <String, WidgetBuilder>{
    login: (_) => LoginScreen(),
    bukom: (_) => BukomScreen(),
    classSelection: (_) => ClassSelectionScreen(),
    bukomBs: (_) => BukomBsScreen(),
    home: (_) => HomeScreen(),
    profile: (_) => ProfileScreen(),
    log: (_) => LogScreen(),
    onprogress: (_) => OnProgressScreen(),
    resetPassword: (_) => ResetPasswordScreen(),
    fotoKegiatan: (_) => FotoKegiatanScreen(),
    editFotoKegiatan: (_) => EditFotoKegiatanScreen(),
    addFotoKegiatan: (_) => AddFotoKegiatanScreen(),
    logBs: (_) => LogBsScreen(),
    rapor: (_) => RaporScreen(),
    profileSelection: (_) => ProfileSelectionScreen(),
    employeeProfile: (_) => const EmployeeProfileScreen(),
    changeShiftRequest: (_) => const ChangeShiftRequestScreen(),
    changeShiftApproval: (_) => const ChangeShiftApprovalScreen(),
    changeShiftStatus: (_) => const ChangeShiftStatusScreen(),
  };
}
