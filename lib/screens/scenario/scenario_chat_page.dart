import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';
import '../../services/app_refresh.dart';
import '../../services/note_service.dart';
import '../../services/scenario_service.dart';
import '../note/note_detail_page.dart';
import '../../services/user_data_service.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/hint_panel.dart';

class ScenarioChatPage extends StatefulWidget {
  final ScenarioSession session;

  const ScenarioChatPage({super.key, required this.session});

  @override
  State<ScenarioChatPage> createState() => _ScenarioChatPageState();
}

class _ScenarioChatPageState extends State<ScenarioChatPage>
    with SingleTickerProviderStateMixin {
  static const _micAreaHeight = 200.0;
  static const _hintPanelHeight = 168.0;

  final UserDataService _userService = UserDataService();
  final AudioService _audioService = AudioService.instance;
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  Map<String, dynamic>? _availableHint;
  bool _hintVisible = false;
  bool _isSending = false;
  bool _isPreparingAiResponse = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isPlayingAudio = false;
  bool _isPlayingAiSpeech = false;
  bool _sessionEnded = false;
  Set<int> _completedGoalIndices = {};
  bool _waitingForUserStart = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _waitingForUserStart =
        widget.session.isUserFirst || widget.session.openingMessage == null;

    final opening = widget.session.openingMessage;
    if (!widget.session.isUserFirst && opening != null) {
      _isPreparingAiResponse = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        setState(() {});
        _scrollToBottom();

        final aiSpeed = _userService.data['aiSpeed'] ?? '현지인 속도로';
        final speed = _audioService.speedFromSetting(aiSpeed);
        final openingText = opening['text'] as String? ?? '';
        String? audioUrl = widget.session.openingAudioUrl;

        try {
          audioUrl = await _audioService.prepareAiTts(
            openingText,
            speed: speed,
            voice: widget.session.ttsVoice,
            preloadedAudioUrl: audioUrl,
          );
        } catch (_) {
          audioUrl = null;
        }

        if (!mounted) return;
        _messages.add(_mapMessage(opening));
        setState(() => _isPreparingAiResponse = false);
        _scrollToBottom();
        await _speakAiMessage(
          openingText,
          preloadedAudioUrl: audioUrl,
        );
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _speakAiMessage(
    String text, {
    double? speed,
    String? preloadedAudioUrl,
  }) async {
    if (text.trim().isEmpty || !mounted) return;

    final settings = _userService.data;
    final aiSpeed = settings['aiSpeed'] ?? '현지인 속도로';
    final resolvedSpeed = speed ?? _audioService.speedFromSetting(aiSpeed);

    setState(() {
      _isPlayingAudio = true;
      _isPlayingAiSpeech = true;
    });
    try {
      await _audioService.playTts(
        text,
        speed: resolvedSpeed,
        voice: widget.session.ttsVoice,
        preloadedAudioUrl: preloadedAudioUrl,
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _isPlayingAiSpeech = false;
        });
      }
    }
  }

  Future<void> _speakUserReplay(String text) async {
    if (text.trim().isEmpty || !mounted) return;

    setState(() {
      _isPlayingAudio = true;
      _isPlayingAiSpeech = false;
    });
    try {
      await _audioService.playTts(
        text,
        speed: 1.0,
        voice: widget.session.ttsVoice,
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
          _isPlayingAiSpeech = false;
        });
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (_isSending || _sessionEnded || _isPlayingAudio) return;

    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _pulseController.stop();
      });
      try {
        final text = await _audioService.stopRecordingAndTranscribe();
        if (mounted) setState(() => _isTranscribing = false);
        await _sendMessage(text: text);
      } on ApiException catch (error) {
        if (mounted) setState(() => _isTranscribing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message)),
          );
        }
      }
      return;
    }

    try {
      await _audioService.startRecording();
      if (!mounted) return;
      setState(() => _isRecording = true);
      _pulseController.repeat(reverse: true);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }

  Map<String, dynamic> _mapMessage(Map<String, dynamic> json) {
    return {
      'isAI': json['isAI'] ?? false,
      'text': json['text'] ?? '',
      'pronunciation': json['pronunciation'] ?? '',
      'translation': json['translation'] ?? '',
      'isRecommended': json['isRecommended'] ?? false,
    };
  }

  void _storeHint(Map<String, dynamic> recommended) {
    setState(() {
      _availableHint = _mapMessage(recommended);
      _hintVisible = false;
    });
  }

  void _clearHint() {
    setState(() {
      _availableHint = null;
      _hintVisible = false;
    });
  }

  void _toggleHintPanel() {
    if (_availableHint == null || _sessionEnded) return;
    setState(() => _hintVisible = !_hintVisible);
  }

  String _normalizeJapanese(String text) {
    return text.replaceAll(RegExp(r'[\s　。、！？!?.,，「」『』（）()"\[\]{}]'), '').toLowerCase();
  }

  bool _messageMatchesHint(String messageText, Map<String, dynamic>? hint) {
    if (hint == null) return false;
    final hintText = (hint['text'] as String? ?? '').trim();
    if (hintText.isEmpty) return false;
    final user = _normalizeJapanese(messageText);
    final target = _normalizeJapanese(hintText);
    if (user.isEmpty || target.isEmpty) return false;
    if (user == target) return true;
    if (target.length >= 4 && (target.contains(user) || user.contains(target))) {
      return true;
    }
    return false;
  }

  Future<void> _sendMessage({required String text, bool isRecommended = false}) async {
    if (_sessionEnded) return;

    final messageText = text.trim();
    if (messageText.isEmpty || _isSending) return;

    final hintSnapshot = _availableHint;
    final usedHint = _messageMatchesHint(messageText, hintSnapshot);

    setState(() {
      _isSending = true;
      _isPreparingAiResponse = true;
      _availableHint = null;
      _hintVisible = false;
      _waitingForUserStart = false;
    });

    _messages.add({
      'isAI': false,
      'text': messageText,
      'pronunciation': '',
      'translation': '',
      'isRecommended': isRecommended,
      'usedHint': usedHint,
      if (usedHint && hintSnapshot != null) ...{
        'hintText': hintSnapshot['text'] ?? '',
        'hintPronunciation': hintSnapshot['pronunciation'] ?? '',
        'hintTranslation': hintSnapshot['translation'] ?? '',
      },
    });
    setState(() {});
    _scrollToBottom();

    try {
      String? hintText;
      String? hintPronunciation;
      String? hintTranslation;
      if (usedHint && hintSnapshot != null) {
        hintText = hintSnapshot['text'] as String?;
        hintPronunciation = hintSnapshot['pronunciation'] as String?;
        hintTranslation = hintSnapshot['translation'] as String?;
      }

      final response = await ScenarioService.instance.sendMessage(
        sessionId: widget.session.sessionId,
        text: messageText,
        isRecommended: isRecommended,
        usedHint: usedHint,
        hintText: hintText,
        hintPronunciation: hintPronunciation,
        hintTranslation: hintTranslation,
      );

      final aiMessage = _mapMessage(
        Map<String, dynamic>.from(response['aiMessage'] as Map),
      );
      final aiAudioUrl = response['aiAudioUrl'] as String?;

      if (mounted) setState(() => _isSending = false);

      final settings = _userService.data;
      final aiSpeed = settings['aiSpeed'] ?? '현지인 속도로';
      final speed = _audioService.speedFromSetting(aiSpeed);
      final aiText = aiMessage['text'] as String? ?? '';
      String? resolvedAudioUrl;
      try {
        resolvedAudioUrl = await _audioService.prepareAiTts(
          aiText,
          speed: speed,
          voice: widget.session.ttsVoice,
          preloadedAudioUrl: aiAudioUrl,
        );
      } catch (_) {
        resolvedAudioUrl = null;
      }

      _messages.add(aiMessage);

      _completedGoalIndices = Set<int>.from(
        response['completedGoalIndices'] ?? [],
      );

      final allGoalsCompleted = response['allGoalsCompleted'] == true;
      final recommended = response['recommendedAnswer'];

      if (!allGoalsCompleted && recommended is Map<String, dynamic>) {
        _storeHint(recommended);
      } else {
        _clearHint();
      }

      if (mounted) {
        setState(() => _isPreparingAiResponse = false);
      }
      _scrollToBottom();

      await _speakAiMessage(
        aiText,
        preloadedAudioUrl: resolvedAudioUrl,
      );

      if (allGoalsCompleted) {
        await _handleGoalsCompleted();
      }
    } on ApiException catch (error) {
      _messages.removeLast();
      if (mounted) {
        setState(() {
          _isPreparingAiResponse = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleGoalsCompleted() async {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _clearHint();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('모든 대화 목표를 달성했습니다!'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    await Future<void>.delayed(const Duration(seconds: 2));
    await _endSession(showSnackBar: false);
  }

  Future<void> _endSession({bool showSnackBar = true}) async {
    if (_sessionEnded && showSnackBar) return;
    _sessionEnded = true;
    _clearHint();

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String? noteId;
    String? errorMessage;

    try {
      final result = await ScenarioService.instance.endSession(widget.session.sessionId);
      noteId = result.noteId;
      AppRefresh.notifyNotesChanged();
    } on ApiException catch (error) {
      errorMessage = error.message;
    } catch (error) {
      errorMessage = '세션 종료 중 오류가 발생했습니다.';
    }

    navigator.popUntil(ModalRoute.withName('/main'));

    if (errorMessage != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }

    if (noteId == null || noteId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('피드백 노트를 생성하지 못했습니다.')),
      );
      return;
    }

    try {
      final note = await NoteService.instance.getNote(noteId);
      await navigator.push(
        MaterialPageRoute(
          builder: (context) => NoteDetailPage(note: note, showHomeButton: true),
        ),
      );
    } on ApiException catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  void _showGoalsSheet() {
    final goals = widget.session.goals;
    if (goals.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
                Text(
                  '대화 목표 (${_completedGoalIndices.length}/${goals.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...goals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final goal = entry.value;
                  final isDone = _completedGoalIndices.contains(index);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isDone
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isDone ? AppColors.pastelGreen : AppColors.lightGrey2,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            goal,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDone ? AppColors.darkGrey : AppColors.black,
                              decoration: isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _backgroundAsset =>
      'assets/images/backgrounds/convenience_store.png';

  @override
  Widget build(BuildContext context) {
    final settings = _userService.data;
    final showJapaneseInitially = settings['showContentFromStart'] == '예';
    final showTranslationInitially = settings['showKoreanTranslation'] == '예';
    final showPronunciationInitially = settings['showKoreanPronunciation'] == '예';
    final aiSpeed = settings['aiSpeed'] ?? '현지인 속도로';
    final totalGoals = widget.session.goals.length;
    final micEnabled = !_isSending &&
        !_isPreparingAiResponse &&
        !_sessionEnded &&
        !_isPlayingAudio &&
        !_isTranscribing;
    final bottomInset = _micAreaHeight +
        (_hintVisible && _availableHint != null && !_sessionEnded
            ? _hintPanelHeight + 12
            : 0);
    final hintAvailable = _availableHint != null && !_sessionEnded;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppColors.background,
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: Colors.black87,
                        splashRadius: 20,
                        tooltip: '뒤로가기',
                      ),

                      _buildTopButton(
                        '대화종료',
                            () => _endSession(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '장소: ${widget.session.location} | AI 역할: ${widget.session.aiRole}',
                          style: const TextStyle(color: AppColors.deepYellow, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (totalGoals > 0)
                        GestureDetector(
                          onTap: _showGoalsSheet,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.flag_outlined,
                                size: 18,
                                color: AppColors.deepYellow,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '목표 ${_completedGoalIndices.length}/$totalGoals',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                Icons.chevron_right,
                                size: 20,
                                color: AppColors.deepYellow,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (_waitingForUserStart && widget.session.sceneNote.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.movie_filter_outlined, size: 20, color: AppColors.deepYellow),
                              SizedBox(width: 6),
                              Text(
                                '상황',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.deepYellow,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // 분리선
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.session.sceneNote,
                            style: const TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '먼저 일본어로 말을 걸어주세요',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.darkGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(20, 10, 20, bottomInset + 12),
                    itemCount: _messages.length + (_isPreparingAiResponse ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isPreparingAiResponse && index == _messages.length) {
                        return _buildAiPreparingBubble();
                      }
                      final msg = _messages[index];
                      final isAi = msg['isAI'] == true;
                      final messageText = msg['text'] as String? ?? '';
                      final pronunciation = msg['pronunciation'] as String?;
                      final translation = msg['translation'] as String?;
                      return ChatBubble(
                        text: messageText,
                        pronunciation: pronunciation,
                        translation: translation,
                        isAI: isAi,
                        isRecommended: msg['isRecommended'] ?? false,
                        showJapaneseInitially: showJapaneseInitially,
                        showTranslationInitially: showTranslationInitially,
                        showPronunciationInitially: showPronunciationInitially,
                        aiSpeedSetting: aiSpeed,
                        onReplay: messageText.trim().isEmpty
                            ? null
                            : isAi
                                ? () => _speakAiMessage(
                                      messageText,
                                      speed: _audioService.speedFromSetting(aiSpeed),
                                    )
                                : () => _speakUserReplay(messageText),
                        onSpeedTap: isAi
                            ? () => _speakAiMessage(
                                  messageText,
                                  speed: _audioService.adjustedSpeedFromSetting(
                                    aiSpeed,
                                  ),
                                )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (_hintVisible && _availableHint != null && !_sessionEnded)
            Positioned(
              left: 12,
              right: 12,
              bottom: _micAreaHeight + 8,
              child: HintPanel(
                text: _availableHint!['text'] as String? ?? '',
                pronunciation: _availableHint!['pronunciation'] as String?,
                translation: _availableHint!['translation'] as String?,
                showJapaneseInitially: showJapaneseInitially,
                showTranslationInitially: showTranslationInitially,
                showPronunciationInitially: showPronunciationInitially,
                onReplay: () => _speakAiMessage(
                  _availableHint!['text'] as String? ?? '',
                  speed: _audioService.speedFromSetting(aiSpeed),
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _micAreaHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_isTranscribing)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          '음성 인식 중…',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (_isPreparingAiResponse)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          '준비 중…',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (_isSending && !_sessionEnded)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          'AI가 응답 중…',
                          style: TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else if (_isPlayingAudio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _isPlayingAiSpeech ? 'AI가 말하는 중…' : '재생 중…',
                          style: const TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          _micStatusLabel(),
                          style: TextStyle(
                            color: _isRecording ? AppColors.deepYellow : AppColors.darkGrey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildKeyboardButton(),
                        const SizedBox(width: 36),
                        GestureDetector(
                          onTap: micEnabled ? _toggleRecording : null,
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_isRecording)
                                  ScaleTransition(
                                    scale: Tween<double>(begin: 0.95, end: 1.05).animate(
                                      CurvedAnimation(
                                        parent: _pulseController,
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.deepYellow.withValues(alpha: 0.15),
                                      ),
                                    ),
                                  ),
                                _buildMicButton(micEnabled),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 36),
                        _buildHintButton(hintAvailable),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPreparingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.lightGrey2,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '준비 중…',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.darkGrey.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _micStatusLabel() {
    if (_isRecording) return '녹음 중 · 탭하면 종료';
    if (_waitingForUserStart) return '녹음 버튼을 눌러 먼저 말해보세요';
    if (_availableHint != null && !_hintVisible) return '말하기 어려우면 힌트 버튼을 눌러보세요';
    return '';//'빨간 버튼을 눌러 녹음';
  }

  Widget _buildHintButton(bool hintAvailable) {
    final enabled = hintAvailable &&
        !_isSending &&
        !_isPreparingAiResponse &&
        !_isRecording &&
        !_isTranscribing;
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? _toggleHintPanel : null,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _hintVisible
                  ? const Color(0xFFFFF7D6)
                  : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.deepYellow,
                  size: 28,
                ),
                if (hintAvailable && !_hintVisible)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboardButton() {
    final enabled = !_isSending &&
        !_isPreparingAiResponse &&
        !_isRecording &&
        !_isTranscribing &&
        !_sessionEnded &&
        !_isPlayingAudio;

    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? _showKeyboardInput : null,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.95),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.keyboard_outlined,
              color: enabled
                  ? AppColors.deepYellow
                  : AppColors.lightGrey2,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(bool enabled) {
    if (_isRecording) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.deepYellow,

          boxShadow: [
            BoxShadow(
              color: AppColors.deepYellow.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.stop_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled
            ? AppColors.deepYellow
            : AppColors.lightGrey2,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.mic_rounded,
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _showKeyboardInput() async {
    _textController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "일본어 직접 입력",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _textController,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: "일본어를 입력하세요...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("취소"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final text = _textController.text.trim();

                          if (text.isEmpty) return;

                          Navigator.pop(context);

                          _sendMessage(text: text);

                          _textController.clear();
                        },
                        child: const Text("보내기"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
    );
  }
  Widget _buildTopButton(
      String label,
      VoidCallback onPressed,
      ) {
    return Material(
      color: AppColors.deepYellow,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.exit_to_app_rounded,
                size: 18,
                color: Colors.white,
              ),
              SizedBox(width: 6),
              Text(
                '대화 종료',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
