void logDeepgramKeyDebug(String key, {String source = 'unknown'}) {
  print('===== DEEPGRAM DEBUG ($source) =====');
  print('Key Loaded: $key');
  print('Key Empty: ${key.isEmpty}');
  print('Key Length: ${key.length}');
  print('=========================');
}
