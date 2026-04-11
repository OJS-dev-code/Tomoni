# Tomoni
LLM + 상황극을 기반으로 한 일본어 학습 안드로이드 앱

각 멤버 별로 branch를 나눠놨습니다. 해당하는 브랜치에서 작업해주세요.
yena, eunso, jeongseo

1. 다른 사람이 내 브랜치에서 작업하는 방법
가. 프로젝트 공동 작업자(Collaborator) 추가 (필수)
깃허브 저장소(Repository)로 이동합니다.
Settings 탭을 클릭합니다.
왼쪽 메뉴에서 Collaborators (또는 Manage access)를 선택합니다.
Add people 버튼을 눌러 작업할 팀원의 깃허브 아이디나 이메일을 초대합니다.
초대를 받은 팀원은 이메일 혹은 알림을 통해 수락해야 합니다. 
나. 다른 팀원의 작업 절차
Clone 또는 Pull: 팀원들은 원격 저장소를 git clone으로 가져오거나 git pull을 통해 최신 상태를 반영합니다.
Branch 이동/체크아웃: 당신이 만든 브랜치(예: feature/login)로 이동합니다.
bash
git checkout feature/login
작업 후 Push: 코드를 수정하고 커밋한 뒤, 해당 브랜치로 push합니다.
bash
git add .
git commit -m "작업 내용"
git push origin feature/login
 
2. 주의사항 및 팁
충돌(Conflict) 방지: 여러 명이 동시에 같은 파일을 수정하면 충돌이 발생할 수 있습니다. 한 브랜치에서 여러 명이 작업할 때는 서로 커뮤니케이션을 통해 작업 순서를 조율하는 것이 좋습니다.
Pull Request (PR) 활용: 다른 사람이 내 브랜치에 직접 푸시하는 대신, 포크(Fork)하거나 개인 브랜치를 만들어 작업한 후, 당신의 브랜치로 Pull Request를 보내는 것이 변경 사항을 검토하기에 더 안전합니다. 
Reddit
Reddit
 +3
