import 'package:flutter/material.dart';
import '../widgets/main_bottom_nav.dart';
import 'home/home_page.dart';
import 'note/note_page.dart';
import 'settings/settings_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    // 매번 빌드할 때 새로운 리스트를 참조하도록 하여 상태 동기화 보장
    final List<Widget> pages = [
      const NotePage(),
      const HomePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack( // 페이지 상태 유지를 위해 IndexedStack 사용
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
