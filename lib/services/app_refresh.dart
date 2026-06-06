import 'package:flutter/foundation.dart';

/// 세션 종료 등으로 노트·캘린더 데이터가 바뀌었을 때 UI 갱신용
class AppRefresh {
  AppRefresh._();

  static final ValueNotifier<int> notesChanged = ValueNotifier(0);

  static void notifyNotesChanged() {
    notesChanged.value++;
  }
}
