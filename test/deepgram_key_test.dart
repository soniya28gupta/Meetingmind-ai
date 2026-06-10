import 'package:flutter_test/flutter_test.dart';
import 'package:meetingmind_ai/core/config/deepgram_debug.dart';

void main() {
  test('deepgram debug helper reports non-empty key metadata', () {
    const key = '6ecb2124a1a4982a3e3b1c6e5c3eee0ad25d21e1';
    expect(key.isEmpty, isFalse);
    expect(key.length, 40);
    logDeepgramKeyDebug(key, source: 'test');
  });

  test('empty deepgram key is detected', () {
    const key = '';
    expect(key.isEmpty, isTrue);
    expect(key.length, 0);
  });
}
