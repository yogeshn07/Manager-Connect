import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/errors/app_exception.dart';

AppException mapSupabaseError(Object error) {
  if (error is AuthException) {
    return AppException(error.message, int.tryParse(error.statusCode ?? ''));
  }
  if (error is PostgrestException) {
    return AppException(error.message, _parseStatusCode(error.code));
  }
  if (error is FunctionException) {
    final details = error.details;
    if (details is Map<String, dynamic>) {
      final errorBody = details['error'];
      if (errorBody is Map<String, dynamic>) {
        return AppException(
          errorBody['message'] as String? ?? 'Unknown error',
          error.status,
        );
      }
    }
    return AppException(
      error.reasonPhrase ?? 'Edge function error',
      error.status,
    );
  }
  return AppException(error.toString());
}

int? _parseStatusCode(String? code) {
  if (code == null) return null;
  return int.tryParse(code);
}
