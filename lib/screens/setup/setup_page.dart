import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import 'steps/step1_widget.dart';
import 'steps/step2_widget.dart';
import 'steps/step3_widget.dart';
import 'steps/step4_widget.dart';
import 'steps/step5_widget.dart';
import 'steps/step6_widget.dart';
import 'steps/summary_widget.dart';
//사용자가 step1~step6에서 선택, 입력한 모든 정보를 setupData Map에 모음
//성별, 생년월일, 일본어 실력, 배우는 목적, 취미, AI 설정값 등
//이후 setupData를 FastAPI 혹은 Firebase에 전송
//현재는 Phone 메모리(RAM)에만 저장.

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  //step widget 단계 표시
  final PageController _controller = PageController();
  double _progress = 1 / 6;
  int _currentIndex = 0;

  // 전체 설정을 저장할 데이터 맵
  final Map<String, dynamic> setupData = {
    'gender': '', //step1
    'birthDate': '',
    'level': '', //step2
    'duration': '', //step3
    'purposes': <String>{}, //step4
    'hobbies': <String>{}, //step5
    'aiSpeed': '현지인속도', //step6
    'showContentFromStart': '예',
    'showKoreanTranslation': '예',
    'showKoreanPronunciation': '아니오',
  };

  //각 step widget에서 입력이 완료되면 updateDate() 호출해서 부모에게 데이터 전달
  void updateData(String key, dynamic value) {
    setState(() {
      setupData[key] = value;
    });
  }

  //setup page 내용
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: Column(
          children: [
            if (_currentIndex != 6)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Step ${(_progress * 6).round()} of 6",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${(_progress * 100).toInt()}% Complete",
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE6E6E6),
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.deepYellow,
                        ),
                      ),
                    ),

                    // const SizedBox(height: 20),
                  ],
                ),
              ),
            Expanded(
              child: PageView(

                controller: _controller,
                //손가락으로 못넘기고 버튼 눌러야만 단계별로 넘어가도록 설정 (필수입력항목 체크)
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _progress = index >= 6 ? 1.0 : (index + 1) / 6;
                  });
                },
                children: [
                  Step1Widget( //onCompleted() 안에 내용 다 선택하면 updateData
                    pageController: _controller,
                    onCompleted: (gender, year, month, day) {
                      updateData('gender', gender == 'female' ? '여성' : '남성');
                      updateData('birthDate', '$year.$month.$day');
                    },
                  ),
                  Step2Widget(
                    pageController: _controller,
                    onCompleted: (level) => updateData('level', level),
                  ),
                  Step3Widget(
                    pageController: _controller,
                    onCompleted: (duration) => updateData('duration', duration),
                  ),
                  Step4Widget(
                    pageController: _controller,
                    onCompleted: (purposes) => updateData('purposes', purposes),
                  ),
                  Step5Widget(
                    pageController: _controller,
                    onCompleted: (hobbies) => updateData('hobbies', hobbies),
                  ),
                  Step6Widget(
                    pageController: _controller,
                    onCompleted: (speed, start, trans, pron) {
                      updateData('aiSpeed', speed);
                      updateData('showContentFromStart', start);
                      updateData('showKoreanTranslation', trans);
                      updateData('showKoreanPronunciation', pron);
                    },
                  ),
                  SummaryWidget( //선택한 정보 표시
                    pageController: _controller,
                    data: setupData, //사용자가 입력한 setupData 맵을 이용
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}