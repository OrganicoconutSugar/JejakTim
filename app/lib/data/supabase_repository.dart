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
  bool get isDemo => false;

  @override
  Future<Json> load(String uid) async =>
      Map<String, dynamic>.from(await client.rpc('jt_workspace') as Map);

  @override
  Future<Json> command(String uid, String action, Json payload) async {
    final result =
        action == 'submitTask'
            ? await client.rpc(
              'jt_submit_evidence',
              params: {'input_data': payload},
            )
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
}
