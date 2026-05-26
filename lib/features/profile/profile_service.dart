import '../../core/api/api_client.dart';
import 'models/driver_profile.dart';

class ProfileService {
  final ApiClient _api;
  ProfileService(this._api);

  Future<DriverProfile> fetchProfile() async {
    final json = await _api.get('/driver/profile') as Map<String, dynamic>;
    return DriverProfile.fromJson(json['driver'] as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('/driver/profile/change-password', {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    });
  }
}
