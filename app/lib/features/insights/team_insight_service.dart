import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models.dart';

const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const String kGeminiModel = String.fromEnvironment(
  'GEMINI_MODEL',
  defaultValue: 'gemini-flash-lite-latest',
);
const List<String> kGeminiFallbackModels = [
  'gemini-flash-lite-latest',
  'gemini-flash-latest',
  'gemini-3-flash-preview',
  'gemini-2.5-flash-lite',
];

enum InsightSource { geminiDirect, supabaseEdge, localSmart }

class InsightRecommendation {
  final String title;
  final String detail;
  final String? taskId;
  final String priority; // 'high', 'medium', 'calm'

  const InsightRecommendation({
    required this.title,
    required this.detail,
    this.taskId,
    this.priority = 'medium',
  });
}

class TeamInsightResult {
  final String headline;
  final String summary;
  final List<String> highlights;
  final List<InsightRecommendation> recommendations;
  final InsightSource source;
  final String modelLabel;
  final DateTime generatedAt;
  final String? fallbackNote;

  const TeamInsightResult({
    required this.headline,
    required this.summary,
    required this.highlights,
    required this.recommendations,
    required this.source,
    required this.modelLabel,
    required this.generatedAt,
    this.fallbackNote,
  });

  bool get isAiGenerated =>
      source == InsightSource.geminiDirect ||
      source == InsightSource.supabaseEdge;
}

class MemberWorkload {
  final String uid;
  final String name;
  final bool isOwner;
  final int assigned;
  final int active;
  final int done;
  final int overdue;
  final int pendingReviews;
  final int submissions;
  final int reviews;
  final int updates;

  const MemberWorkload({
    required this.uid,
    required this.name,
    required this.isOwner,
    required this.assigned,
    required this.active,
    required this.done,
    required this.overdue,
    required this.pendingReviews,
    required this.submissions,
    required this.reviews,
    required this.updates,
  });
}

class TeamWorkloadAnalysis {
  final List<MemberWorkload> members;
  final String status; // 'balanced' | 'needs_balance' | 'starting' | 'completed'
  final String statusLabel;
  final String summaryText;
  final int maxAssigned;

  const TeamWorkloadAnalysis({
    required this.members,
    required this.status,
    required this.statusLabel,
    required this.summaryText,
    required this.maxAssigned,
  });
}

class AnonymizedInsightBundle {
  final Json payload;
  final Map<String, String> memberRefToName;
  final Map<String, String> taskRefToId;
  final Map<String, String> taskRefToTitle;

  const AnonymizedInsightBundle({
    required this.payload,
    required this.memberRefToName,
    required this.taskRefToId,
    required this.taskRefToTitle,
  });
}

TeamWorkloadAnalysis analyzeTeamWorkload({
  required List<Json> tasks,
  required List<String> memberIds,
  required Map<String, String> memberNames,
  String? ownerId,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final activeTasks = tasks.where((t) => t['status'] != 'cancelled').toList();
  final allIds = <String>{...memberIds};
  for (final task in activeTasks) {
    allIds.addAll(stringsOf(task, 'assigneeIds'));
    final reviewer = textOf(task, 'reviewerId');
    if (reviewer.isNotEmpty) allIds.add(reviewer);
  }

  final rows = <MemberWorkload>[];
  for (final id in allIds) {
    var assigned = 0;
    var active = 0;
    var done = 0;
    var overdue = 0;
    var pendingReviews = 0;
    var submissions = 0;
    var reviews = 0;
    var updates = 0;

    for (final task in activeTasks) {
      final status = textOf(task, 'status');
      final due = dateOf(task, 'dueAt');
      if (stringsOf(task, 'assigneeIds').contains(id)) {
        assigned++;
        if (status == 'done') {
          done++;
        } else {
          active++;
          if (due != null && due.isBefore(clock)) {
            overdue++;
          }
        }
      }
      if (task['reviewerId'] == id && status == 'submitted') {
        pendingReviews++;
      }
      submissions +=
          rowsOf(task, 'submissions').where((s) => s['submittedBy'] == id).length;
      reviews +=
          rowsOf(task, 'reviews').where((r) => r['reviewerId'] == id).length;
      updates +=
          rowsOf(task, 'updates').where((u) => u['authorId'] == id).length;
    }

    final resolvedName =
        memberNames[id]?.trim().isNotEmpty == true
            ? memberNames[id]!.trim()
            : 'Anggota';
    rows.add(
      MemberWorkload(
        uid: id,
        name: resolvedName,
        isOwner: ownerId != null && id == ownerId,
        assigned: assigned,
        active: active,
        done: done,
        overdue: overdue,
        pendingReviews: pendingReviews,
        submissions: submissions,
        reviews: reviews,
        updates: updates,
      ),
    );
  }

  rows.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  final maxAssigned = rows.fold<int>(0, (acc, m) => math.max(acc, m.assigned));
  final totalDone = activeTasks.where((t) => t['status'] == 'done').length;
  final totalActive = activeTasks.length - totalDone;

  if (activeTasks.isEmpty) {
    return TeamWorkloadAnalysis(
      members: rows,
      status: 'starting',
      statusLabel: 'Belum ada tugas',
      summaryText: 'Bagikan tugas pertama agar ritme kerja tim mulai terlihat.',
      maxAssigned: maxAssigned,
    );
  }
  if (totalActive == 0 && totalDone > 0) {
    return TeamWorkloadAnalysis(
      members: rows,
      status: 'completed',
      statusLabel: 'Semua tugas tuntas',
      summaryText: 'Seluruh tugas dalam proyek ini telah selesai dan ditinjau.',
      maxAssigned: maxAssigned,
    );
  }
  if (rows.length < 2 || activeTasks.length < 2) {
    return TeamWorkloadAnalysis(
      members: rows,
      status: 'starting',
      statusLabel: 'Tahap awal',
      summaryText:
          'Tambahkan anggota dan pembagian tugas agar distribusi beban lebih terbaca.',
      maxAssigned: maxAssigned,
    );
  }

  final activeCounts = rows.map((m) => m.active).toList();
  final maxActive = activeCounts.reduce(math.max);
  final minActive = activeCounts.reduce(math.min);
  final spread = maxActive - minActive;

  if (spread >= 2 && maxActive >= 2) {
    final heaviest = rows.firstWhere((m) => m.active == maxActive);
    return TeamWorkloadAnalysis(
      members: rows,
      status: 'needs_balance',
      statusLabel: 'Perlu pemerataan',
      summaryText:
          '${_firstName(heaviest.name)} sedang memegang $maxActive tugas aktif. Pertimbangkan berbagi peran atau saling bantu.',
      maxAssigned: maxAssigned,
    );
  }

  return TeamWorkloadAnalysis(
    members: rows,
    status: 'balanced',
    statusLabel: 'Beban cukup merata',
    summaryText:
        'Tugas aktif terbagi cukup seimbang di antara ${rows.length} anggota tim.',
    maxAssigned: maxAssigned,
  );
}

AnonymizedInsightBundle buildAnonymizedInsightBundle({
  required List<Json> tasks,
  required List<String> memberIds,
  required Map<String, String> memberNames,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final todayDate = dateOnly(clock);
  final activeTasks = tasks.where((t) => t['status'] != 'cancelled').toList();

  final orderedMembers = <String>[...memberIds];
  for (final task in activeTasks) {
    for (final uid in stringsOf(task, 'assigneeIds')) {
      if (!orderedMembers.contains(uid)) orderedMembers.add(uid);
    }
    final reviewer = textOf(task, 'reviewerId');
    if (reviewer.isNotEmpty && !orderedMembers.contains(reviewer)) {
      orderedMembers.add(reviewer);
    }
  }

  final uidToRef = <String, String>{};
  final memberRefToName = <String, String>{};
  for (var i = 0; i < orderedMembers.length; i++) {
    final uid = orderedMembers[i];
    final ref = 'Anggota ${i + 1}';
    uidToRef[uid] = ref;
    final full = memberNames[uid]?.trim();
    memberRefToName[ref] =
        (full != null && full.isNotEmpty) ? _firstName(full) : ref;
  }

  final taskRefToId = <String, String>{};
  final taskRefToTitle = <String, String>{};
  final anonymizedTasks = <Json>[];

  for (var i = 0; i < activeTasks.length; i++) {
    final task = activeTasks[i];
    final ref = 'T${i + 1}';
    taskRefToId[ref] = textOf(task, 'id');
    taskRefToTitle[ref] = textOf(task, 'title');

    final due = dateOf(task, 'dueAt');
    final dueInDays =
        due == null ? null : dateOnly(due).difference(todayDate).inDays;
    final updates = rowsOf(task, 'updates');
    final hasBlocker =
        updates.isNotEmpty && updates.last['kind'] == 'blocker';
    final reviews = rowsOf(task, 'reviews');
    final revisionCount =
        reviews.where((r) => r['decision'] == 'revision_requested').length;

    anonymizedTasks.add({
      'ref': ref,
      'status': textOf(task, 'status', 'todo'),
      'dueInDays': dueInDays,
      'assignees':
          stringsOf(task, 'assigneeIds')
              .map((uid) => uidToRef[uid] ?? 'Anggota')
              .toList(),
      'reviewer': uidToRef[textOf(task, 'reviewerId')] ?? 'Anggota',
      'hasActiveBlocker': hasBlocker,
      'revisionCount': revisionCount,
      'submissionCount': rowsOf(task, 'submissions').length,
      'updateCount': updates.length,
    });
  }

  final stats = aggregateTasks(activeTasks, clock);
  final workload = analyzeTeamWorkload(
    tasks: activeTasks,
    memberIds: orderedMembers,
    memberNames: memberNames,
    now: clock,
  );

  final payload = <String, dynamic>{
    'memberCount': orderedMembers.length,
    'summary': {
      'totalTasks': stats['total'],
      'doneTasks': stats['done'],
      'pendingReviewTasks': stats['review'],
      'overdueTasks': stats['overdue'],
      'revisionRequestedTasks':
          activeTasks
              .where((t) => t['status'] == 'revision_requested')
              .length,
      'activeBlockers':
          anonymizedTasks.where((t) => t['hasActiveBlocker'] == true).length,
      'workloadStatus': workload.status,
    },
    'memberLoads':
        workload.members
            .map(
              (m) => {
                'memberRef': uidToRef[m.uid] ?? 'Anggota',
                'activeTasks': m.active,
                'doneTasks': m.done,
                'pendingReviews': m.pendingReviews,
                'overdueTasks': m.overdue,
              },
            )
            .toList(),
    'tasks': anonymizedTasks,
  };

  return AnonymizedInsightBundle(
    payload: payload,
    memberRefToName: memberRefToName,
    taskRefToId: taskRefToId,
    taskRefToTitle: taskRefToTitle,
  );
}

class TeamInsightService {
  static const _systemPrompt = '''
Kamu adalah asisten koordinasi tim untuk aplikasi mahasiswa bernama JejakTim.
Prinsip wajib:
- Gunakan bahasa Indonesia yang hangat, ringkas, suportif, dan praktis.
- DILARANG memberi skor, ranking, nilai akademik, atau label menghakimi pada anggota.
- Gunakan hanya data agregat yang diberikan. Jangan mengarang fakta di luar data.
- Fokus pada keseimbangan beban kerja, tugas menunggu review, revisi, kendala (blocker), dan tenggat mendekat.
- Saat merujuk anggota gunakan persis kode seperti "Anggota 1", dan saat merujuk tugas gunakan kode seperti "T1" di field taskRef.
- Jawab HANYA dalam JSON valid dengan struktur persis:
{
  "headline": "Ringkasan singkat 4-8 kata",
  "summary": "2-3 kalimat suportif tentang ritme kerja tim saat ini.",
  "highlights": ["Temuan positif atau kondisi utama (maks 3 item)"],
  "recommendations": [
    {
      "title": "Judul langkah singkat",
      "detail": "Saran koordinasi konkret untuk tim",
      "taskRef": "T1 atau null",
      "priority": "high | medium | calm"
    }
  ]
}''';

  final http.Client _client;
  final String _apiKey;
  final String _model;
  final SupabaseClient? _supabase;

  TeamInsightService({
    http.Client? client,
    String? apiKey,
    String? model,
    SupabaseClient? supabase,
  }) : _client = client ?? http.Client(),
       _apiKey = (apiKey ?? kGeminiApiKey).trim(),
       _model =
           (model ?? kGeminiModel).trim().isEmpty
               ? 'gemini-flash-lite-latest'
               : (model ?? kGeminiModel).trim(),
       _supabase = supabase;

  bool get hasDirectGeminiKey => _apiKey.isNotEmpty;

  TeamInsightResult analyzeLocal({
    required List<Json> tasks,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    String? ownerId,
    DateTime? now,
    String? fallbackNote,
  }) {
    final clock = now ?? DateTime.now();
    final activeTasks = tasks.where((t) => t['status'] != 'cancelled').toList();
    final stats = aggregateTasks(activeTasks, clock);
    final workload = analyzeTeamWorkload(
      tasks: activeTasks,
      memberIds: memberIds,
      memberNames: memberNames,
      ownerId: ownerId,
      now: clock,
    );

    final total = stats['total'] as int;
    final done = stats['done'] as int;
    final review = stats['review'] as int;
    final overdue = stats['overdue'] as int;
    final revisionTasks =
        activeTasks
            .where((t) => t['status'] == 'revision_requested')
            .toList();
    final pendingReviewTasks =
        activeTasks.where((t) => t['status'] == 'submitted').toList();
    final overdueTasks =
        activeTasks
            .where(
              (t) =>
                  !['done', 'cancelled'].contains(t['status']) &&
                  dateOf(t, 'dueAt') != null &&
                  dateOf(t, 'dueAt')!.isBefore(clock),
            )
            .toList();
    final blockerTasks =
        activeTasks.where((t) {
          final updates = rowsOf(t, 'updates');
          return !['done', 'cancelled'].contains(t['status']) &&
              updates.isNotEmpty &&
              updates.last['kind'] == 'blocker';
        }).toList();

    final highlights = <String>[];
    final recommendations = <InsightRecommendation>[];

    if (total > 0) {
      final pct = ((done / total) * 100).round();
      highlights.add('$done dari $total tugas ($pct%) sudah selesai dan terverifikasi.');
    }
    highlights.add('${workload.statusLabel}: ${workload.summaryText}');

    if (blockerTasks.isNotEmpty) {
      final first = blockerTasks.first;
      recommendations.add(
        InsightRecommendation(
          title: 'Bantu kendala yang sedang aktif',
          detail:
              'Tugas "${textOf(first, 'title')}" mencatat kendala terbaru. Buka detail tugas atau bahas singkat di Chat proyek.',
          taskId: textOf(first, 'id'),
          priority: 'high',
        ),
      );
    }

    if (overdueTasks.isNotEmpty) {
      final first = overdueTasks.first;
      recommendations.add(
        InsightRecommendation(
          title: 'Tinjau $overdue tugas melewati tenggat',
          detail:
              'Prioritaskan "${textOf(first, 'title')}" atau sepakati ulang tenggat bersama agar tim tidak kewalahan.',
          taskId: textOf(first, 'id'),
          priority: 'high',
        ),
      );
    }

    if (pendingReviewTasks.isNotEmpty) {
      final first = pendingReviewTasks.first;
      final reviewerName =
          memberNames[textOf(first, 'reviewerId')]?.trim() ?? 'Reviewer';
      recommendations.add(
        InsightRecommendation(
          title: 'Selesaikan $review peer review tertunda',
          detail:
              '${_firstName(reviewerName)} dapat meninjau bukti "${textOf(first, 'title')}" agar progres tim segera lanjut.',
          taskId: textOf(first, 'id'),
          priority: 'medium',
        ),
      );
    }

    if (revisionTasks.isNotEmpty) {
      final first = revisionTasks.first;
      recommendations.add(
        InsightRecommendation(
          title: 'Tindak lanjuti ${revisionTasks.length} permintaan revisi',
          detail:
              'Cek masukan reviewer pada "${textOf(first, 'title')}" lalu kirim ulang bukti setelah perbaikan.',
          taskId: textOf(first, 'id'),
          priority: 'medium',
        ),
      );
    }

    if (workload.status == 'needs_balance') {
      recommendations.add(
        InsightRecommendation(
          title: 'Ratakan beban kerja aktif',
          detail: workload.summaryText,
          priority: 'medium',
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const InsightRecommendation(
          title: 'Pertahankan ritme kolaborasi',
          detail:
              'Terus catat pembaruan kecil dan unggah bukti kerja tepat waktu agar seluruh jejak kontribusi terdokumentasi rapi.',
          priority: 'calm',
        ),
      );
    }

    final String headline;
    final String summary;
    if (total == 0) {
      headline = 'Siap memulai ritme tim';
      summary =
          'Tambahkan tugas pertama beserta penanggung jawab dan reviewer agar analisis ritme kerja mulai bekerja.';
    } else if (done == total) {
      headline = 'Seluruh target tugas tuntas';
      summary =
          'Semua $total tugas telah selesai melalui proses bukti dan peer review. Tim siap membuat laporan kontribusi PDF.';
    } else if (blockerTasks.isNotEmpty || overdue > 0) {
      headline = 'Ada langkah yang perlu dibantu';
      summary =
          'Sebagian progres sudah berjalan ($done/$total selesai), namun ada ${blockerTasks.length} kendala aktif dan $overdue tugas lewat tenggat yang sebaiknya diselesaikan bersama lebih dulu.';
    } else if (review > 0 || revisionTasks.isNotEmpty) {
      headline = 'Progres bergerak, review menanti';
      summary =
          '$done dari $total tugas sudah selesai. Menyelesaikan $review tinjauan bukti dan ${revisionTasks.length} revisi akan menjaga laju tim tetap lancar.';
    } else {
      headline = 'Ritme kerja tim cukup stabil';
      summary =
          'Progres berjalan tenang dengan $done dari $total tugas selesai dan tanpa bottleneck review atau keterlambatan saat ini.';
    }

    return TeamInsightResult(
      headline: headline,
      summary: summary,
      highlights: highlights.take(3).toList(),
      recommendations: recommendations.take(4).toList(),
      source: InsightSource.localSmart,
      modelLabel: 'Smart Rhythm Analyzer',
      generatedAt: clock,
      fallbackNote: fallbackNote,
    );
  }

  Future<TeamInsightResult> generateInsight({
    required List<Json> tasks,
    required List<String> memberIds,
    required Map<String, String> memberNames,
    String? ownerId,
    DateTime? now,
  }) async {
    final clock = now ?? DateTime.now();
    final bundle = buildAnonymizedInsightBundle(
      tasks: tasks,
      memberIds: memberIds,
      memberNames: memberNames,
      now: clock,
    );

    if (_apiKey.isNotEmpty) {
      try {
        return await _callDirectGemini(bundle, clock);
      } catch (_) {
        return analyzeLocal(
          tasks: tasks,
          memberIds: memberIds,
          memberNames: memberNames,
          ownerId: ownerId,
          now: clock,
          fallbackNote:
              'Gemini belum merespons saat ini. Menampilkan analisis ritme lokal berbasis data tugas terbaru.',
        );
      }
    }

    if (_supabase != null) {
      try {
        return await _callSupabaseEdge(bundle, clock);
      } catch (_) {
        return analyzeLocal(
          tasks: tasks,
          memberIds: memberIds,
          memberNames: memberNames,
          ownerId: ownerId,
          now: clock,
          fallbackNote:
              'Menampilkan analisis ritme lokal. Tambahkan GEMINI_API_KEY di konfigurasi atau Supabase Secrets untuk mengaktifkan Gemini AI.',
        );
      }
    }

    return analyzeLocal(
      tasks: tasks,
      memberIds: memberIds,
      memberNames: memberNames,
      ownerId: ownerId,
      now: clock,
      fallbackNote:
          'Menampilkan analisis ritme lokal. Tambahkan GEMINI_API_KEY di supabase.config.json untuk mengaktifkan Gemini AI.',
    );
  }

  Future<TeamInsightResult> _callDirectGemini(
    AnonymizedInsightBundle bundle,
    DateTime clock,
  ) async {
    final prompt =
        'Analisis data agregat proyek mahasiswa berikut dan berikan saran koordinasi tim:\n'
        '${jsonEncode(bundle.payload)}';
    final candidatesToTry = <String>[
      _model,
      ...kGeminiFallbackModels.where((m) => m != _model),
    ];

    Object? lastError;
    for (final modelName in candidatesToTry) {
      final uri = Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$modelName:generateContent',
      );
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': _apiKey,
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': _systemPrompt},
                ],
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
              'generationConfig': {
                'temperature': 0.4,
                'responseMimeType': 'application/json',
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = body['candidates'] as List? ?? const [];
        if (candidates.isEmpty) {
          lastError = const AppFailure('Respons Gemini kosong.');
          continue;
        }
        final parts =
            ((candidates.first as Map)['content'] as Map?)?['parts'] as List? ??
            const [];
        final rawText =
            parts.isEmpty ? '' : (parts.first as Map)['text']?.toString() ?? '';
        final parsed = _decodeJsonPayload(rawText);
        return _parseAiResult(
          parsed,
          bundle: bundle,
          source: InsightSource.geminiDirect,
          modelLabel: _formatModelLabel(modelName),
          generatedAt: clock,
        );
      }

      lastError = AppFailure('Gemini HTTP ${response.statusCode}');
      // Retry next model on model-not-found, rate-limit, or temporary overload.
      if (![404, 429, 500, 503].contains(response.statusCode)) {
        break;
      }
    }

    throw lastError ?? const AppFailure('Layanan Gemini tidak tersedia.');
  }

  Future<TeamInsightResult> _callSupabaseEdge(
    AnonymizedInsightBundle bundle,
    DateTime clock,
  ) async {
    final response = await _supabase!.functions
        .invoke('team-insight', body: bundle.payload)
        .timeout(const Duration(seconds: 20));
    if (response.status < 200 || response.status >= 300) {
      throw AppFailure('Edge Function HTTP ${response.status}');
    }
    final data =
        response.data is Map
            ? Map<String, dynamic>.from(response.data as Map)
            : _decodeJsonPayload(response.data.toString());
    final modelName = textOf(data, 'model', _model);
    return _parseAiResult(
      data,
      bundle: bundle,
      source: InsightSource.supabaseEdge,
      modelLabel: _formatModelLabel(modelName),
      generatedAt: clock,
    );
  }

  Json _decodeJsonPayload(String raw) {
    final cleaned =
        raw
            .trim()
            .replaceFirst(RegExp(r'^```json\s*'), '')
            .replaceFirst(RegExp(r'^```\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
    return Map<String, dynamic>.from(jsonDecode(cleaned) as Map);
  }

  TeamInsightResult _parseAiResult(
    Json json, {
    required AnonymizedInsightBundle bundle,
    required InsightSource source,
    required String modelLabel,
    required DateTime generatedAt,
  }) {
    String resolveText(String input) {
      var out = input.trim();
      final memberEntries =
          bundle.memberRefToName.entries.toList()
            ..sort((a, b) => b.key.length.compareTo(a.key.length));
      for (final entry in memberEntries) {
        out = out.replaceAll(entry.key, entry.value);
      }
      final taskEntries =
          bundle.taskRefToTitle.entries.toList()
            ..sort((a, b) => b.key.length.compareTo(a.key.length));
      for (final entry in taskEntries) {
        out = out.replaceAll(
          RegExp('\\b${RegExp.escape(entry.key)}\\b'),
          '"${entry.value}"',
        );
      }
      return out;
    }

    final headline = resolveText(
      textOf(json, 'headline', 'Ringkasan ritme kerja tim'),
    );
    final summary = resolveText(
      textOf(
        json,
        'summary',
        'Berikut saran koordinasi berdasarkan progres tugas kelompokmu.',
      ),
    );
    final highlights =
        stringsOf(json, 'highlights')
            .map(resolveText)
            .where((s) => s.isNotEmpty)
            .take(3)
            .toList();
    final recommendations =
        rowsOf(json, 'recommendations')
            .map((r) {
              final ref = textOf(r, 'taskRef').trim();
              final taskId = bundle.taskRefToId[ref];
              final priority = textOf(r, 'priority', 'medium');
              return InsightRecommendation(
                title: resolveText(textOf(r, 'title', 'Langkah koordinasi')),
                detail: resolveText(textOf(r, 'detail')),
                taskId: taskId,
                priority:
                    ['high', 'medium', 'calm'].contains(priority)
                        ? priority
                        : 'medium',
              );
            })
            .where((item) => item.detail.isNotEmpty)
            .take(4)
            .toList();

    return TeamInsightResult(
      headline: headline,
      summary: summary,
      highlights: highlights,
      recommendations: recommendations,
      source: source,
      modelLabel: modelLabel,
      generatedAt: generatedAt,
    );
  }
}

String _firstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return 'Anggota';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _formatModelLabel(String rawModel) {
  if (rawModel.contains('flash-lite')) return 'Gemini Flash Lite';
  if (rawModel.contains('3-flash')) return 'Gemini 3 Flash';
  if (rawModel.contains('2.5-flash')) return 'Gemini 2.5 Flash';
  if (rawModel.contains('flash')) return 'Gemini Flash';
  if (rawModel.contains('pro')) return 'Gemini Pro';
  return 'Gemini AI ($rawModel)';
}
