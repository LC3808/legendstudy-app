# PHASE3 닉네임 20 grapheme — 2026-11-14/15

Owner 요청: 신규·변경 닉네임만20 grapheme, 기존 이름 보존, 스토어 제출 금지.
characters 1.4.1 (Unicode16)을 직접 의존성으로 선언. 프로필/온보딩 공통 검증,
입력 counter20, 강제 절단 없음. repository에서 기존 이름 조회 후 동일하면
payload에 display_name을 보내지 않는다. 학교·학년/온보딩 완료와 기존 이름 보존.

검증: nickname/day7_profile/personalization_onboarding/onboarding_page/my_profile_state/task14b_profile_navigation 92 PASS.
Flutter3.47.5/Dart3.13.4 analyze PASS. 기존 테스트의 단일 요청 기대는 추가 GET을
고려해 POST payload를 검증하도록 변경; 이전1~80 안내 기대는1~20으로 변경.
기존 긴 이름으로 학년 저장,21자 거부,한글/영문/ZWJ가족/국기/피부색/결합문자 검증.

운영 DB는 WEB 작업의 `nickname_grapheme_20` migration으로 동일 Unicode16
검증을 적용했다. 기존80코드포인트 CHECK를 신규/변경만 검사하는 트리거로 교체.
기존660프로필 닉네임·58첨삭 원본·원장 해시 동일. 사용자 데이터 변경 없음.
[WEB 실행·검증·원복](https://github.com/LC3808/legendstudy-lab/blob/codex/lab-admin-operations-20261114/wiki/admin-console-phase3-20261114.md).

보존 질문: 기존 시점/원본/이력 유지; 같은 auth UUID; 학습·판단·결과 및 과금 분리;
기존권한/보존기간 유지; 신규수집/추론없음. 저장 구조 변경 없이 입력 검증만 수정.
실기기 제출/신규 스토어 빌드·업로드: NOT TESTED/미수행(요청 범위 제외).
