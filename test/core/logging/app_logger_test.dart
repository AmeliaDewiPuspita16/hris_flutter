import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/core/logging/app_logger.dart';

import '../../support/log_recorder.dart';

void main() {
  late LogRecorder recorder;

  setUp(() => recorder = LogRecorder()..install());
  tearDown(AppLogger.resetSink);

  test('meneruskan pesan info ke sink', () {
    AppLogger.info('memanggil endpoint login');

    expect(recorder.messages, ['memanggil endpoint login']);
  });

  test('meneruskan pesan, error, dan stack trace ke sink', () {
    final failure = StateError('gagal menulis keychain');
    final stack = StackTrace.current;

    AppLogger.error('login gagal', failure, stack);

    expect(recorder.entries.single.message, 'login gagal');
    expect(recorder.entries.single.error, same(failure));
    expect(recorder.entries.single.stackTrace, same(stack));
  });

  test('tetap mencatat walau stack trace tidak diberikan', () {
    AppLogger.error('login gagal', StateError('x'));

    expect(recorder.entries.single.stackTrace, isNull);
  });
}
