import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Chrome blob: URL은 package:http로 읽으면 깨질 수 있어 fetch API 사용.
Future<List<int>> readRecordingBytes(String path) async {
  final response = await web.window.fetch(path.toJS).toDart;
  if (!response.ok) {
    throw StateError('blob read failed (${response.status})');
  }

  final blob = await response.blob().toDart;
  final buffer = await blob.arrayBuffer().toDart;
  return Uint8List.view(buffer.toDart);
}
