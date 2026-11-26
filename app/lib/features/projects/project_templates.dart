import '../../core/models.dart';

class StarterTaskIdea {
  final String title;
  final String description;
  const StarterTaskIdea({required this.title, required this.description});
}

class ProjectTemplate {
  final String id;
  final String label;
  final String subtitle;
  final String courseLabel;
  final String avatarKey;
  final String sdgTag;
  final String descriptionTemplate;
  final List<StarterTaskIdea> starterTasks;

  const ProjectTemplate({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.courseLabel,
    required this.avatarKey,
    required this.sdgTag,
    required this.descriptionTemplate,
    required this.starterTasks,
  });
}

const List<ProjectTemplate> kProjectTemplates = [
  ProjectTemplate(
    id: 'course',
    label: 'Tugas & Riset',
    subtitle: 'Kolaborasi tugas mata kuliah, riset, dan presentasi.',
    courseLabel: 'Tugas Mata Kuliah & Riset',
    avatarKey: 'book',
    sdgTag: 'SDG 4 · Pendidikan Berkualitas',
    descriptionTemplate:
        'Kolaborasi tim untuk menyusun riset, membagi peran secara adil, meninjau bukti kerja antaranggota, dan menghasilkan laporan kontribusi digital.',
    starterTasks: [
      StarterTaskIdea(
        title: 'Pemetaan masalah & referensi utama',
        description:
            'Kumpulkan minimal 3 referensi kredibel, rangkum poin inti, dan unggah catatan ringkasan sebagai bukti kerja.',
      ),
      StarterTaskIdea(
        title: 'Penyusunan draf konten & analisis',
        description:
            'Susun bagian analisis utama sesuai pembagian peran dan pastikan siap diperiksa oleh rekan reviewer.',
      ),
      StarterTaskIdea(
        title: 'Finalisasi materi presentasi & cek akhir',
        description:
            'Rapikan slide/dokumen akhir, periksa konsistensi data, dan unggah tautan atau tangkapan layar versi final.',
      ),
    ],
  ),
  ProjectTemplate(
    id: 'green_campus',
    label: 'Green Campus',
    subtitle: 'Aksi lingkungan, hemat energi, bank sampah, atau kampus hijau.',
    courseLabel: 'Aksi Lingkungan & Green Campus',
    avatarKey: 'sprout',
    sdgTag: 'SDG 13 · Aksi Iklim & Ramah Lingkungan',
    descriptionTemplate:
        'Inisiatif kolaborasi mahasiswa untuk mendorong kebiasaan ramah lingkungan, pengurangan sampah/kertas, serta dokumentasi aksi berkelanjutan secara paperless.',
    starterTasks: [
      StarterTaskIdea(
        title: 'Audit kebiasaan & titik aksi lingkungan',
        description:
            'Dokumentasikan kondisi awal lokasi atau kebiasaan kampus yang ingin diperbaiki beserta foto lapangan.',
      ),
      StarterTaskIdea(
        title: 'Kampanye digital & panduan aksi hijau',
        description:
            'Buat materi edukasi digital (tanpa cetak berlebih) dan bagikan ke komunitas atau kelas terkait.',
      ),
      StarterTaskIdea(
        title: 'Dokumentasi pelaksanaan & dampak aksi',
        description:
            'Unggah foto kegiatan nyata di lapangan dan catat hasil terukur yang dicapai tim.',
      ),
    ],
  ),
  ProjectTemplate(
    id: 'kkn',
    label: 'KKN & Sosial',
    subtitle: 'Program pengabdian masyarakat, edukasi warga, atau UMKM.',
    courseLabel: 'KKN & Pengabdian Masyarakat',
    avatarKey: 'team',
    sdgTag: 'SDG 11 · Komunitas Berkelanjutan',
    descriptionTemplate:
        'Ruang koordinasi program pengabdian masyarakat untuk mencatat pembagian kerja lapangan, bukti dokumentasi kegiatan, dan laporan kontribusi anggota.',
    starterTasks: [
      StarterTaskIdea(
        title: 'Observasi kebutuhan mitra / warga',
        description:
            'Catat hasil wawancara atau observasi singkat bersama mitra masyarakat beserta foto dokumentasi.',
      ),
      StarterTaskIdea(
        title: 'Persiapan materi & logistik kegiatan',
        description:
            'Susun daftar kebutuhan, jadwal pelaksanaan, dan pembagian peran tim sebelum turun ke lapangan.',
      ),
      StarterTaskIdea(
        title: 'Dokumentasi kegiatan & evaluasi lapangan',
        description:
            'Kumpulkan bukti foto pelaksanaan, umpan balik warga, dan catatan pembelajaran untuk laporan akhir.',
      ),
    ],
  ),
  ProjectTemplate(
    id: 'organization',
    label: 'Organisasi',
    subtitle: 'Kepanitiaan acara, komunitas mahasiswa, atau proyek lintas divisi.',
    courseLabel: 'Organisasi & Kepanitiaan',
    avatarKey: 'event',
    sdgTag: 'SDG 17 · Kemitraan Kolaboratif',
    descriptionTemplate:
        'Koordinasi lintas divisi untuk merencanakan kegiatan mahasiswa secara transparan, saling meninjau kesiapan tiap bagian, dan mendokumentasikan proses kerja.',
    starterTasks: [
      StarterTaskIdea(
        title: 'Penyusunan konsep & lini masa acara',
        description:
            'Tetapkan tujuan kegiatan, target peserta, serta tenggat tiap divisi untuk ditinjau bersama.',
      ),
      StarterTaskIdea(
        title: 'Publikasi & kesiapan operasional',
        description:
            'Unggah draf publikasi atau daftar cek teknis perlengkapan agar dapat direview sebelum hari-H.',
      ),
      StarterTaskIdea(
        title: 'Evaluasi pascakegiatan & arsip digital',
        description:
            'Catat capaian, kendala, dan rekomendasi perbaikan untuk kepengurusan berikutnya secara paperless.',
      ),
    ],
  ),
];

ProjectTemplate inferTemplateForProject(Json project) {
  final haystack =
      '${textOf(project, 'courseLabel')} ${textOf(project, 'name')} ${textOf(project, 'description')}'
          .toLowerCase();
  final avatar = textOf(project, 'avatar');

  if (avatar == 'sprout' ||
      haystack.contains('green') ||
      haystack.contains('lingkungan') ||
      haystack.contains('sampah') ||
      haystack.contains('hijau') ||
      haystack.contains('iklim') ||
      haystack.contains('eco')) {
    return kProjectTemplates[1];
  }
  if (haystack.contains('kkn') ||
      haystack.contains('pengabdian') ||
      haystack.contains('masyarakat') ||
      haystack.contains('sosial') ||
      haystack.contains('desa') ||
      haystack.contains('umkm')) {
    return kProjectTemplates[2];
  }
  if (avatar == 'event' ||
      haystack.contains('organisasi') ||
      haystack.contains('panitia') ||
      haystack.contains('acara') ||
      haystack.contains('event') ||
      haystack.contains('himpunan')) {
    return kProjectTemplates[3];
  }
  return kProjectTemplates[0];
}
