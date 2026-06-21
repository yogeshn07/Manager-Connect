import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';

class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Future<void> sendOtp({required String email}) async {
    try {
      await _client.auth.signInWithOtp(email: email);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      return await _client.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Session? get currentSession => _client.auth.currentSession;

  Future<Map<String, dynamic>> validateInviteToken(String token) async {
    try {
      final response = await _client.functions.invoke(
        'validate-invite-token',
        body: {'token': token},
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Invalid token',
            response.status,
          );
        }
        throw AppException('Invalid invitation token', response.status);
      }
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
