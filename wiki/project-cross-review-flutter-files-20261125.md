# 11/25 Flutter 비교 파일 전수 목록

[종합 보고](project-cross-review-20261125.md)의 보조 자료. 기준 `08345b69`(실제 출시88) → `02996bed`(오래된 main). 아래 M/D는 이 역방향 diff의 상태이며 신규 개발 또는 실제 삭제 지시가 아니다. 총47파일, iOS/Android/assets 차이0.

```text
M	lib/app/navigation_shell.dart
M	lib/app/router.dart
M	lib/features/analytics/domain/analytics_events.dart
D	lib/features/analytics/usage_actions.dart
M	lib/features/applications/application_editor.dart
M	lib/features/applications/applications_page.dart
M	lib/features/applications/onboarding_applications.dart
M	lib/features/auth/presentation/delete_account_page.dart
M	lib/features/credits/essay_beta_credit.dart
M	lib/features/essay/essay_growth_page.dart
M	lib/features/essay/math_gateway.dart
M	lib/features/essay/source_catalog_page.dart
M	lib/features/essay/university_catalog.dart
M	lib/features/home/customization/home_editor.dart
M	lib/features/home/customization/home_registry.dart
M	lib/features/home/presentation/home_page.dart
D	lib/features/home/university_news/catalog_news.dart
M	lib/features/home/university_news/university_news.dart
M	lib/features/home/university_news/university_news_widgets.dart
M	lib/features/lab/score_summary.dart
M	lib/features/materials/application/search_controller.dart
M	lib/features/materials/data/supabase_search_repository.dart
M	lib/features/materials/domain/search_models.dart
M	lib/features/materials/presentation/materials_page.dart
M	lib/features/onboarding/presentation/onboarding_page.dart
M	lib/features/personal/bookmark_providers.dart
M	lib/features/personal/data/supabase_personal_repositories.dart
M	lib/features/profile/nickname_validation.dart
M	lib/features/profile/presentation/aspirations_card.dart
M	lib/features/profile/presentation/profile_edit_page.dart
M	lib/features/profile/presentation/profile_page.dart
D	lib/features/resources/data/download_history.dart
M	lib/features/resources/data/pdf_download.dart
M	lib/features/resources/presentation/pdf_download_action.dart
M	lib/features/resources/presentation/pdf_viewer_page.dart
M	lib/features/resources/presentation/resource_section.dart
D	lib/features/saved/presentation/downloaded_page.dart
M	lib/features/study/application/study_controller.dart
M	lib/features/study/domain/study_models.dart
M	lib/features/study/presentation/study_page.dart
M	lib/features/study/study_providers.dart
D	lib/features/study/trends/study_goals.dart
M	lib/features/study/trends/study_trend_page.dart
M	lib/features/study/trends/study_trends.dart
M	lib/shared/widgets/legendstudy_lab_entry.dart
M	pubspec.lock
M	pubspec.yaml
```

## 실제 미출시 D-Day 변경

`6cd4c1a7`의 Flutter 변경6파일 및 테스트1파일. 출시88/main 모두 미포함. 다른 파일 전체를 덮어쓰지 않고 선택 통합·QA가 필요하다.

```text
lib/features/home/data/supabase_day_event_repository.dart
lib/features/home/day_event_providers.dart
lib/features/home/domain/admission_day_event.dart
lib/features/home/domain/day_event.dart
lib/features/home/domain/day_event_repository.dart
lib/features/home/presentation/day_target_card.dart
test/admission_day_event_test.dart
```
