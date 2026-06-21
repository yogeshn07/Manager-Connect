import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:manager_connect/core/constants/supabase_constants.dart';
import 'package:manager_connect/core/errors/app_exception.dart';
import 'package:manager_connect/core/network/api_error_handler.dart';
import 'package:manager_connect/features/recognition/data/models/recognition_dto.dart';

class RecognitionRepository {
  RecognitionRepository(this._client);

  final SupabaseClient _client;

  static const _recognitionSelect =
      'id, giver_id, category_tag, message, created_at, '
      'profiles!recognitions_giver_id_fkey(full_name, avatar_url), '
      'recognition_recipients(recipient_id, profiles(full_name, avatar_url))';

  Future<List<RecognitionDto>> getRecognitions() async {
    try {
      final response = await _client
          .from(Table.recognitions)
          .select(_recognitionSelect)
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(50);
      return response.map(RecognitionDto.fromJson).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<RecognitionDto> getRecognition(String recognitionId) async {
    try {
      final response = await _client
          .from(Table.recognitions)
          .select(_recognitionSelect)
          .eq('id', recognitionId)
          .single();
      return RecognitionDto.fromJson(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<Map<String, dynamic>> createRecognition({
    required List<String> recipientIds,
    required String categoryTag,
    required String message,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'create-recognition',
        body: {
          'recipient_ids': recipientIds,
          'category_tag': categoryTag,
          'message': message,
        },
      );
      if (response.status >= 400) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['error'] != null) {
          final error = data['error'] as Map<String, dynamic>;
          throw AppException(
            error['message'] as String? ?? 'Failed to create recognition',
            response.status,
          );
        }
        throw AppException('Failed to create recognition', response.status);
      }
      return response.data as Map<String, dynamic>;
    } on AppException {
      rethrow;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getActiveMembers() async {
    try {
      final response = await _client
          .from(Table.profiles)
          .select('id, full_name, avatar_url')
          .eq('is_active', true)
          .eq('is_system_account', false)
          .order('full_name');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
