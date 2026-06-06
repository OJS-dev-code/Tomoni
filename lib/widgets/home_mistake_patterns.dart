import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/mistake_pattern.dart';
import '../services/api_service.dart';
import '../services/app_refresh.dart';
import '../services/mistake_service.dart';

class HomeMistakePatterns extends StatefulWidget {
  const HomeMistakePatterns({super.key});

  @override
  State<HomeMistakePatterns> createState() => _HomeMistakePatternsState();
}

class _HomeMistakePatternsState extends State<HomeMistakePatterns> {
  bool _isLoading = true;
  List<MistakePattern> _patterns = [];

  @override
  void initState() {
    super.initState();
    AppRefresh.notesChanged.addListener(_onRefresh);
    _loadPatterns();
  }

  @override
  void dispose() {
    AppRefresh.notesChanged.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() => _loadPatterns();

  Future<void> _loadPatterns() async {
    setState(() => _isLoading = true);
    try {
      final patterns = await MistakeService.instance.getPatterns(limit: 5);
      if (!mounted) return;
      setState(() {
        _patterns = patterns;
        _isLoading = false;
      });
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() {
        _patterns = [];
        _isLoading = false;
      });
    }
  }

  void _showDetail(MistakePattern pattern) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.lightGrey1,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _categoryChip(pattern.category),
                    const SizedBox(width: 8),
                    Text(
                      '${pattern.count}회 반복',
                      style: const TextStyle(color: AppColors.darkGrey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pattern.label,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (pattern.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    pattern.description,
                    style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                  ),
                ],
                if (pattern.userExample.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('내가 말한 표현', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    pattern.userExample,
                    style: const TextStyle(color: AppColors.darkGrey, height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('이렇게 말해보세요', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  pattern.betterJapanese,
                  style: const TextStyle(color: AppColors.pinkyRed, fontSize: 16, height: 1.4),
                ),
                if (pattern.betterPronunciation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    pattern.betterPronunciation,
                    style: const TextStyle(color: Colors.blueAccent, height: 1.4),
                  ),
                ],
                if (pattern.betterTranslation.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    pattern.betterTranslation,
                    style: const TextStyle(color: AppColors.darkGrey, height: 1.4),
                  ),
                ],
                if (pattern.lastTopic.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '최근 주제: ${pattern.lastTopic}',
                    style: const TextStyle(fontSize: 12, color: AppColors.darkGrey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _categoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pastelLightgreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_patterns.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '자주 하는 실수',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '상황극을 마치면 반복 실수 패턴이 여기에 쌓입니다.',
              style: TextStyle(color: AppColors.darkGrey, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '자주 하는 실수',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            '반복된 표현·경어 실수를 모아두었어요.',
            style: TextStyle(fontSize: 13, color: AppColors.darkGrey),
          ),
          const SizedBox(height: 14),
          ..._patterns.map((pattern) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => _showDetail(pattern),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.lightGrey1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _categoryChip(pattern.category),
                                const SizedBox(width: 6),
                                Text(
                                  '${pattern.count}회',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.darkGrey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              pattern.label,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.darkGrey),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
