import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jejaktim/data/demo_repository.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/core/evidence_photo.dart';

void main() {
  late DemoRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = DemoRepository(await SharedPreferences.getInstance());
  });
  test('malformed demo storage recovers to a persisted clean seed', () async {
    for (final corrupted in ['{not-json', '[]', '{"profiles": 1}']) {
      SharedPreferences.setMockInitialValues({'jejaktim.demo.v1': corrupted});
      final prefs = await SharedPreferences.getInstance();

      final recovered = DemoRepository(prefs);
      final data = await recovered.load('nara');

      expect(data['projects'], isNotEmpty);
      expect(
        (jsonDecode(prefs.getString('jejaktim.demo.v1')!) as Map)['projects'],
        isA<List>(),
      );
    }
  });
  test(
    'evidence accepts web links and rejects unsafe schemes and credentials',
    () {
      for (final bad in [
        'javascript:alert(1)',
        'https://user:pass@example.com',
        'https://',
        'x',
      ]) {
        expect(validEvidence(bad), false);
      }
      expect(validEvidence('https://example.com/evidence'), true);
      expect(validEvidence('http://example.com/evidence'), true);
      expect(
        normalizeEvidenceLink('drive.google.com/file'),
        'https://drive.google.com/file',
      );
    },
  );
  test('photo evidence type comes from bytes, not a filename', () {
    expect(
      detectEvidencePhoto(Uint8List.fromList([0xff, 0xd8, 0xff]))?.mimeType,
      'image/jpeg',
    );
    expect(
      detectEvidencePhoto(
        Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      )?.extension,
      'png',
    );
    expect(
      detectEvidencePhoto(
        Uint8List.fromList('RIFFxxxxWEBP'.codeUnits),
      )?.extension,
      'webp',
    );
    expect(detectEvidencePhoto(Uint8List.fromList('<svg/>'.codeUnits)), isNull);
  });
  test('photo alone can be submitted in demo', () async {
    final task = repo.list('tasks').firstWhere((t) => t['id'] == 't1');
    final submitted = await repo.command('nara', 'submitTask', {
      'projectId': 'p1',
      'taskId': 't1',
      'version': task['version'],
      'url': '',
      'photoDataUrl':
          'data:image/png;base64,${base64Encode([137, 80, 78, 71])}',
      'note': '',
    });
    final evidence = rowsOf(submitted, 'submissions').single;
    expect(rowsOf(evidence, 'evidenceLinks'), isEmpty);
    expect(
      rowsOf(evidence, 'evidenceFiles').single['dataUrl'],
      startsWith('data:image/png'),
    );
  });
  test(
    'complete revision lifecycle persists immutable history and rejects stale versions',
    () async {
      final t =
          (await repo.load('nara'))['tasks'].firstWhere((t) => t['id'] == 't1')
              as Json;
      final submit = await repo.command('nara', 'submitTask', {
        'projectId': 'p1',
        'taskId': 't1',
        'version': t['version'],
        'url': 'https://example.com/evidence',
        'note': 'Versi pertama',
      });
      expect(submit['status'], 'submitted');
      await expectLater(
        repo.command('nara', 'reviewSubmission', {
          'projectId': 'p1',
          'taskId': 't1',
          'version': submit['version'],
          'decision': 'approved',
          'comment': 'Review sendiri',
        }),
        throwsA(isA<AppFailure>()),
      );
      final revision = await repo.command('raka', 'reviewSubmission', {
        'projectId': 'p1',
        'taskId': 't1',
        'version': submit['version'],
        'decision': 'revision_requested',
        'comment': 'Lengkapi referensi jurnal.',
      });
      expect(revision['status'], 'revision_requested');
      await expectLater(
        repo.command('nara', 'submitTask', {
          'projectId': 'p1',
          'taskId': 't1',
          'version': 1,
          'url': 'https://example.com/v2',
          'note': 'Versi kedua',
        }),
        throwsA(isA<AppFailure>()),
      );
      final second = await repo.command('nara', 'submitTask', {
        'projectId': 'p1',
        'taskId': 't1',
        'version': revision['version'],
        'url': 'https://example.com/v2',
        'note': 'Referensi dilengkapi.',
      });
      final done = await repo.command('raka', 'reviewSubmission', {
        'projectId': 'p1',
        'taskId': 't1',
        'version': second['version'],
        'decision': 'approved',
        'comment': 'Referensi sudah lengkap.',
      });
      expect(done['status'], 'done');
      expect(rowsOf(done, 'submissions').length, 2);
      expect(rowsOf(done, 'reviews').length, 2);
      final fresh = DemoRepository(await SharedPreferences.getInstance());
      expect(
        (await fresh.load(
          'nara',
        ))['tasks'].firstWhere((t) => t['id'] == 't1')['status'],
        'done',
      );
    },
  );
  test(
    'project isolation, owner-only settings, invite preview and join',
    () async {
      final p = await repo.command('nara', 'createProject', {
        'name': 'Proyek privat',
        'description': 'Hanya untuk kelompok ini.',
      });
      expect(
        (await repo.load('salsa'))['projects'].any((x) => x['id'] == p['id']),
        false,
      );
      await expectLater(
        repo.command('raka', 'saveProject', {
          'projectId': 'p1',
          'name': 'Serangan',
        }),
        throwsA(isA<AppFailure>()),
      );
      final code = await repo.command('nara', 'createInvite', {
        'projectId': p['id'],
      });
      final preview = await repo.command('salsa', 'previewInvite', {
        'code': code['code'],
      });
      expect(preview['name'], 'Proyek privat');
      expect(
        (await repo.load('salsa'))['projects'].any((x) => x['id'] == p['id']),
        false,
      );
      await repo.command('salsa', 'joinProject', {'code': code['code']});
      expect(
        (await repo.load('salsa'))['projects'].any((x) => x['id'] == p['id']),
        true,
      );
    },
  );
  test(
    'report date scope and unavailable AI never fabricate results',
    () async {
      final report = await repo.command('nara', 'generateProjectReport', {
        'projectId': 'p1',
        'periodStart': '2000-01-01T00:00:00Z',
        'periodEnd': '2001-01-01T00:00:00Z',
      });
      expect(rowsOf(report, 'tasks'), isEmpty);
      await expectLater(
        repo.command('nara', 'generateTeamInsight', {'projectId': 'p1'}),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test('updates are rejected for done and cancelled tasks', () async {
    for (final status in ['done', 'cancelled']) {
      final task = repo.list('tasks').firstWhere((t) => t['id'] == 't3');
      task['status'] = status;
      task['version'] = 1;

      await expectLater(
        repo.command('raka', 'addUpdate', {
          'projectId': 'p1',
          'taskId': 't3',
          'version': 1,
          'message': 'Pembaruan yang tidak boleh tersimpan.',
          'kind': 'progress',
        }),
        throwsA(
          isA<AppFailure>().having(
            (error) => error.message,
            'message',
            'Tugas yang selesai atau dibatalkan tidak dapat diperbarui.',
          ),
        ),
      );
      expect(rowsOf(task, 'updates'), isEmpty);
    }
  });
}
