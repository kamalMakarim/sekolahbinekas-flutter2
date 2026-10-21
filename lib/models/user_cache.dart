import 'package:sekolahbinekas/models/user.dart' as local_user;

class UserCache {
  static local_user.User? _user;

  static void setUser(local_user.User user) {
    _user = user;
  }

  static local_user.User? getCurrentUser() {
    return _user;
  }

  static void clear() {
    _user = null;
  }

  static local_user.User? get user => _user;
}
