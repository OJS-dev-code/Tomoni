import 'audio_blob_reader_stub.dart'
    if (dart.library.js_interop) 'audio_blob_reader_web.dart' as impl;

Future<List<int>> readRecordingBytes(String path) {
  return impl.readRecordingBytes(path);
}
