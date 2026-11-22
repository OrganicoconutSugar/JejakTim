import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jejaktim/data/demo_repository.dart';
import 'package:jejaktim/features/reports/report_screens.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('report snapshot exports readable PDF bytes', () async {
    await initializeDateFormatting('id');
    SharedPreferences.setMockInitialValues({});
    final repo = DemoRepository(await SharedPreferences.getInstance());
    final report = await repo.command('nara', 'generateProjectReport', {
      'projectId': 'p1',
      'periodStart': '2020-01-01T00:00:00Z',
      'periodEnd': '2099-01-01T00:00:00Z',
    });

    final bytes = await buildReportPdf(report);

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(5000));
  });
}
