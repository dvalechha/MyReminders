import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../repositories/user_profile_repository.dart';

class UserProfileProvider extends ChangeNotifier {
  UserProfile? _profile;
  bool _isLoading = false;
  final UserProfileRepository _repository = UserProfileRepository();

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get displayName => _profile?.displayName;
  String? get email => _profile?.email;

  /// Get display name with fallback to email
  String getDisplayNameOrEmail() {
    if (_profile != null && _profile!.displayName.isNotEmpty) {
      return _profile!.displayName;
    }
    // Fallback to email from auth if profile is not loaded
    final user = Supabase.instance.client.auth.currentUser;
    return user?.email ?? 'User';
  }

  /// Load user profile for current authenticated user
  /// Note: This will fail silently if the user_profile table doesn't exist
  Future<void> loadProfile() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _profile = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _profile = await _repository.getById(user.id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // Silently fail if user_profile table doesn't exist
      // This is expected if the table hasn't been created in Supabase
      _profile = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh user profile
  Future<void> refreshProfile() async {
    await loadProfile();
  }

  /// Clear profile (on logout)
  void clearProfile() {
    _profile = null;
    _isLoading = false;
    notifyListeners();
  }
}

