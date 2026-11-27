import 'dart:async';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/evidence_photo.dart';
import '../core/models.dart';
import 'repository.dart';

/// The database functions enforce membership and task permissions server-side.
class SupabaseTeamRepository implements TeamRepository {
  final SupabaseClient client;
  SupabaseTeamRepository(this.client);

  @override
  Future<Json> load(String uid) async =>
      Map<String, dynamic>.from(await client.rpc('jt_workspace') as Map);

  @override
  Future<Json> command(String uid, String action, Json payload) async {
    const dedicatedRpcs = {
      'removeTask': 'jt_remove_task',
      'projectChat': 'jt_project_chat',
      'submitTask': 'jt_submit_evidence',
      'leaveProject': 'jt_leave_project',
      'transferOwnership': 'jt_transfer_ownership',
    };
    final rpcName = dedicatedRpcs[action];
    final result =
        rpcName != null
            ? await client.rpc(rpcName, params: {'input_data': payload})
            : await client.rpc(
              'jt_command',
              params: {'action_name': action, 'input_data': payload},
            );
    return Map<String, dynamic>.from(result as Map);
  }

  Future<String> uploadEvidencePhoto({
    required String projectId,
    required String taskId,
    required Uint8List bytes,
    required EvidencePhotoType type,
  }) async {
    final path = '$projectId/$taskId/${const Uuid().v4()}.${type.extension}';
    await client.storage
        .from('jt-evidence')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: type.mimeType, upsert: false),
        );
    return path;
  }

  Future<Uint8List> downloadEvidencePhoto(String path) =>
      client.storage.from('jt-evidence').download(path);

  Future<void> uploadChatImage(
    String path,
    Uint8List bytes,
    EvidencePhotoType type,
  ) async {
    try {
      await client.storage
          .from('jt-chat-images')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: type.mimeType),
          );
    } on StorageException catch (e) {
      // The path belongs to this message. An earlier attempt may have uploaded it.
      if (e.statusCode != '409' && e.error != 'Duplicate') rethrow;
    }
  }

  Future<Uint8List> downloadChatImage(String path) =>
      client.storage.from('jt-chat-images').download(path);

  @override
  Future<void> clearSession() => client.auth.signOut();

  RealtimeChannel watch(String uid, void Function() onChange) =>
      client
          .channel('jejaktim-workspace-$uid')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'jt_events',
            callback: (_) => onChange(),
          )
          .subscribe();

  RealtimeChannel watchProjectChat(String projectId, void Function() onChange) =>
      client
          .channel('jejaktim-chat-$projectId-${const Uuid().v4()}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'jt_project_messages',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'project_id',
              value: projectId,
            ),
            callback: (_) => onChange(),
          )
          .subscribe();

  Future<void> removeChannel(RealtimeChannel channel) =>
      client.removeChannel(channel);
}
