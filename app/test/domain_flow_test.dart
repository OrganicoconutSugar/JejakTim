import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:jejaktim/core/models.dart';
import 'package:jejaktim/core/evidence_photo.dart';
import 'fake_repository.dart';

void main() {
  test('deadline validation rejects past dates and allows today', () {
    expect(isPastDate(today().subtract(const Duration(days: 1))), true);
    expect(isPastDate(today()), false);
    expect(isPastDate(today().add(const Duration(days: 1))), false);
    expect(isPastDate(null), false);
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

  test('canSubmit and canReview enforce assignee and peer-reviewer rules', () {
    final task = {
      'status': 'in_progress',
      'assigneeIds': ['nara'],
      'reviewerId': 'raka',
    };
    expect(() => canSubmit(task, 'nara'), returnsNormally);
    expect(() => canSubmit(task, 'raka'), throwsA(isA<AppFailure>()));

    final submittedTask = {...task, 'status': 'submitted'};
    final submission = {'submittedBy': 'nara', 'status': 'pending_review'};
    expect(() => canReview(submittedTask, submission, 'raka'), returnsNormally);
    expect(
      () => canReview(submittedTask, submission, 'nara'),
      throwsA(isA<AppFailure>()),
    );
  });

  test('report date scope excludes out-of-range and soft-deleted tasks', () async {
    final repo = FakeTeamRepository();
    final emptyReport = await repo.command('nara', 'generateProjectReport', {
      'projectId': 'p1',
      'periodStart': '2000-01-01T00:00:00Z',
      'periodEnd': '2001-01-01T00:00:00Z',
    });
    expect(rowsOf(emptyReport, 'tasks'), isEmpty);

    // Mark t1 as soft-deleted and confirm it is excluded from report snapshot.
    (repo.db['tasks'] as List).first['deletedAt'] =
        DateTime.now().toUtc().toIso8601String();
    final activeReport = await repo.command('nara', 'generateProjectReport', {
      'projectId': 'p1',
      'periodStart': '2020-01-01T00:00:00Z',
      'periodEnd': '2099-01-01T00:00:00Z',
    });
    expect(
      rowsOf(activeReport, 'tasks').any((t) => t['id'] == 't1'),
      isFalse,
    );
  });
}
