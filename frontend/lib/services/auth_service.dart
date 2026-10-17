import '../models/user_model.dart';
import 'api_client.dart';

class AuthResult {
  final String token;
  final UserModel user;

  AuthResult({required this.token, required this.user});
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/register',
      body: {'name': name, 'email': email, 'password': password},
      auth: false,
    );
    return _fromAuthPayload(data);
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final data = await _api.post(
      '/auth/login',
      body: {'email': email, 'password': password},
      auth: false,
    );
    return _fromAuthPayload(data);
  }

  Future<UserModel> me() async {
    final data = await _api.get('/auth/me');
    return UserModel.fromJson(Map<String, dynamic>.from(data as Map));
  }

  AuthResult _fromAuthPayload(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    return AuthResult(
      token: map['access_token'] as String,
      user: UserModel.fromJson(Map<String, dynamic>.from(map['user'] as Map)),
    );
  }
}
