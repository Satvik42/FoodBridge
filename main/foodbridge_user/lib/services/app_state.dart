import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn  => _currentUser != null;
  UserRole get role    => _currentUser?.role ?? UserRole.user;
  bool get isVolunteer => role == UserRole.volunteer;
  bool get isAdmin     => role == UserRole.admin;
  String get userId    => _currentUser?.uid  ?? '';
  String get userName  => _currentUser?.name ?? 'User';

  void setUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setRole(UserRole newRole) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: newRole);
      notifyListeners();
    }
  }

  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}
