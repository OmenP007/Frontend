import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';
import '../services/api_service.dart';

// ── API service singleton ──────────────────────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── Auth state ────────────────────────────────────────────────────────────
class AuthState {
  final String? token;
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.token, this.user, this.isLoading = false, this.error});

  AuthState copyWith({String? token, UserModel? user, bool? isLoading, String? error}) =>
      AuthState(
        token:     token     ?? this.token,
        user:      user      ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error:     error,
      );

  AuthState clearError() => copyWith(error: null);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  final _storage = const FlutterSecureStorage();

  AuthNotifier(this._api) : super(const AuthState()) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await _storage.read(key: 'auth_token');
    final name  = await _storage.read(key: 'user_name');
    final email = await _storage.read(key: 'user_email');
    final role  = await _storage.read(key: 'user_role');
    final idStr = await _storage.read(key: 'user_id');

    if (token != null && idStr != null) {
      state = AuthState(
        token: token,
        user: UserModel(
          id:    int.parse(idStr),
          name:  name ?? '',
          email: email ?? '',
          role:  role ?? 'operator',
        ),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res  = await _api.login(email, password);
      final token = res['token'] as String;
      final userData = res['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      await _storage.write(key: 'auth_token', value: token);
      await _storage.write(key: 'user_id',    value: user.id.toString());
      await _storage.write(key: 'user_name',  value: user.name);
      await _storage.write(key: 'user_email', value: user.email);
      await _storage.write(key: 'user_role',  value: user.role);

      state = AuthState(token: token, user: user);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseError(e));
    }
  }

  Future<void> logout() async {
    try { await _api.logout(); } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState();
  }

  String _parseError(dynamic e) {
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return 'Erreur de connexion';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});
