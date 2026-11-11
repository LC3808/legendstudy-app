import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../../../shared/widgets/legendstudy_lab_entry.dart';
import '../../content/domain/content_types.dart';
import '../../personal/personal_list_providers.dart';
import '../../personal/presentation/personal_material_list.dart';
import '../../school/presentation/home_meal_card.dart';
import '../presentation/day_target_card.dart';
import '../presentation/home_components.dart';
import '../university_news/university_news_widgets.dart';
import 'home_configuration.dart';

class HomeCardDefinition {
  const HomeCardDefinition(
    this.id,
    this.title,
    this.description,
    this.icon,
    this.component,
    this.dataDependency, {
    this.route,
    this.availability = 'available',
  });
  final String id, title, description, availability;
  final IconData icon;
  final WidgetBuilder component;
  final List<String> dataDependency;
  final String? route;
  int get displayOrderDefault =>
      defaultHomeVisibility.keys.toList().indexOf(id);
  bool get defaultVisible => defaultHomeVisibility[id] ?? false;
}

final homeCards = <HomeCardDefinition>[
  HomeCardDefinition(
    'dday',
    'D-Day',
    '내가 정한 대표 일정',
    Icons.event,
    (_) => const DayTargetCard(),
    ['dayEvents', 'dayTargetClock'],
  ),
  HomeCardDefinition(
    'study_summary',
    '나의 공부 시간',
    '오늘의 공부 기록과 학습 시작',
    Icons.timer_outlined,
    (_) =>
        const Padding(padding: EdgeInsets.only(top: 8), child: HomeStudyCard()),
    ['studyController'],
    route: '/study',
  ),
  HomeCardDefinition(
    'school_meals',
    '학교 급식',
    '등록한 학교의 급식 · 학교가 없으면 설정 안내',
    Icons.restaurant,
    (_) =>
        const Padding(padding: EdgeInsets.only(top: 8), child: HomeMealCard()),
    ['schoolSelection', 'meals'],
  ),
  HomeCardDefinition(
    'materials_search',
    '자료 검색',
    '모의고사·학습·논술·입시 자료 찾기',
    Icons.search,
    (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const HomeSection(title: '자료 검색', child: HomeSearch()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final type in [
              'exam',
              'study_material',
              'university_essay',
              'admissions_info',
            ])
              QuickFilterChip(
                contentTypeLabels[type]!,
                onTap: () => context.go(
                  Uri(
                    path: '/materials',
                    queryParameters: {'type': type},
                  ).toString(),
                ),
              ),
          ],
        ),
      ],
    ),
    [],
    route: '/materials',
  ),
  HomeCardDefinition(
    'recent_documents',
    '최근 본 자료',
    '최근 열어 본 자료를 이어서 확인',
    Icons.history,
    (_) => const HomeSection(
      title: '최근 본 자료',
      child: PersonalMaterialList(
        kind: PersonalListKind.recentViews,
        homeMode: true,
      ),
    ),
    ['recentViews'],
    route: '/my/recent',
  ),
  HomeCardDefinition(
    'recent_updates',
    '최근 업데이트',
    '새로 올라온 학습 자료',
    Icons.update,
    (_) => const HomeSection(title: '최근 업데이트', child: HomeRecentUpdates()),
    ['homeRecentContent'],
  ),
  HomeCardDefinition(
    'school_ranking',
    '학교별 공부 순위',
    '학교별 학습 현황 보기',
    Icons.leaderboard_outlined,
    (context) => _entry(context, '학교별 공부 순위', '/study/schools'),
    [],
    route: '/study/schools',
  ),
  HomeCardDefinition(
    'essay_lab',
    '논술 LAB',
    '기존 논술 학습과 첨삭으로 이동',
    Icons.edit_note,
    (_) => const Padding(
      padding: EdgeInsets.only(top: 16),
      child: LegendStudyLabEntry(),
    ),
    [],
    route: '/lab/essay',
  ),
  HomeCardDefinition(
    'university_news',
    '나의 대학 소식',
    '희망·지원 대학의 공식 일정과 소식',
    Icons.school_outlined,
    (_) => const UniversityNewsCard(),
    ['interestedUniversities', 'applications', 'verifiedUniversityNews'],
    availability: 'official-data-required',
  ),
];
Widget _entry(BuildContext context, String title, String route) => Padding(
  padding: const EdgeInsets.only(top: 16),
  child: LsCard(
    child: ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push(route),
    ),
  ),
);
