import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._storage);

  final AuthService _authService;
  final FlutterSecureStorage _storage;

  UserModel? user;
  bool loading = true;
  String? error;

  bool get isLoggedIn => user != null;

  Future<void> restoreSession() async {
    loading = true;
    notifyListeners();
    try {
      final token = await _storage.read(key: ApiConstants.tokenKey);
      if (token == null || token.isEmpty) {
        user = null;
        return;
      }
      user = await _authService.me();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await _storage.delete(key: ApiConstants.tokenKey);
      }
      user = null;
    } catch (_) {
      user = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) {
    return _authenticate(() => _authService.register(name: name, email: email, password: password));
  }

  Future<bool> login(String email, String password) {
    return _authenticate(() => _authService.login(email: email, password: password));
  }

  Future<bool> _authenticate(Future<AuthResult> Function() action) async {
    error = null;
    loading = true;
    notifyListeners();
    try {
      final result = await action();
      await _storage.write(key: ApiConstants.tokenKey, value: result.token);
      user = result.user;
      return true;
    } catch (e) {
      error = friendlyError(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: ApiConstants.tokenKey);
    user = null;
    notifyListeners();
  }
}
