import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/feedback/domain/feedback_models.dart';
import 'package:legendstudy_app/features/feedback/feedback_providers.dart';
import 'package:legendstudy_app/features/feedback/presentation/admin_feedback_page.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';

FeedbackSubmission feedback({
  String id = 'a',
  String? userId = 'owner-a',
  FeedbackStatus status = FeedbackStatus.newStatus,
  FeedbackCategory category = FeedbackCategory.inquiry,
  String title = '문의 제목',
  String body = '문의 내용',
}) {
  final now = DateTime.utc(2026, 9, 17, 1);
  return FeedbackSubmission(
    id: id,
    userId: userId,
    category: category,
    title: title,
    body: body,
    appVersion: '0.1.0',
    buildNumber: '1',
    platform: 'ios',
    osVersion: '26.0',
    locale: 'ko-KR',
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeFeedbackRepository implements FeedbackRepository {
  FakeFeedbackRepository(this.rows);
  final List<FeedbackSubmission> rows;
  final updates = <String, FeedbackStatus>{};

  @override
  Future<void> submit(FeedbackDraft draft) async {}

  @override
  Future<bool> isAdmin() async => true;

  @override
  Future<List<FeedbackSubmission>> fetchAdminFeedback({
    FeedbackStatus? status,
    int limit = 50,
  }) async => rows
      .where((row) => status == null || row.status == status)
      .take(limit)
      .toList();

  @override
  Future<FeedbackSubmission> fetchAdminFeedbackById(String id) async =>
      rows.firstWhere((row) => row.id == id);

  @override
  Future<FeedbackSubmission> updateFeedbackStatus(
    String id,
    FeedbackStatus status,
  ) async {
    updates[id] = status;
    final current = rows.firstWhere((row) => row.id == id);
    return feedback(id: current.id, status: status, title: current.title);
  }
}

Widget testApp({
  required Widget child,
  required AuthStatus auth,
  required AdminAccess admin,
  List<FeedbackSubmission> rows = const [],
  String? detailId,
}) {
  final repository = FakeFeedbackRepository(rows);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(auth)),
      adminAccessProvider.overrideWith((ref) async => admin),
      feedbackRepositoryProvider.overrideWithValue(repository),
      if (detailId != null)
        adminFeedbackDetailProvider(detailId).overrideWith(
          (ref) async => rows.firstWhere((row) => row.id == detailId),
        ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  test('feedback status and category labels match the production contract', () {
    expect(FeedbackStatus.newStatus.label, '신규');
    expect(FeedbackStatus.reviewing.label, '확인중');
    expect(FeedbackStatus.resolved.label, '처리완료');
    expect(FeedbackCategory.inquiry.label, '문의');
    expect(FeedbackCategory.bug.label, '오류 신고');
    expect(FeedbackCategory.suggestion.label, '기능 제안');
    expect(FeedbackCategory.other.label, '기타');
  });

  testWidgets('guest and normal MY do not show the admin menu', (tester) async {
    for (final auth in [const AuthStatus(null), const AuthStatus('user-a')]) {
      await tester.pumpWidget(
        testApp(
          child: const ProfilePage(),
          auth: auth,
          admin: AdminAccess(userId: auth.userId, isAdmin: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('문의 관리'), findsNothing);
    }
  });

  testWidgets('admin MY shows the server-derived admin menu', (tester) async {
    await tester.pumpWidget(
      testApp(
        child: const ProfilePage(),
        auth: const AuthStatus('admin-id'),
        admin: const AdminAccess(userId: 'admin-id', isAdmin: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('관리자'), findsOneWidget);
    expect(find.text('문의 관리'), findsOneWidget);
  });

  testWidgets('direct admin page denies normal users before list access', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        child: const AdminFeedbackPage(),
        auth: const AuthStatus('user-a'),
        admin: const AdminAccess(userId: 'user-a', isAdmin: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('관리자만 이용할 수 있어요.'), findsOneWidget);
  });

  testWidgets('admin list loading and empty states render', (tester) async {
    final pending = Completer<AdminAccess>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('admin')),
          ),
          adminAccessProvider.overrideWith((ref) => pending.future),
          feedbackRepositoryProvider.overrideWithValue(
            FakeFeedbackRepository([]),
          ),
        ],
        child: const MaterialApp(home: AdminFeedbackPage()),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const AdminAccess(userId: 'admin', isAdmin: true));
    await tester.pumpAndSettle();
    expect(find.text('접수된 문의가 없습니다.'), findsOneWidget);
  });

  testWidgets(
    'admin list shows newest-first rows with status and category labels',
    (tester) async {
      final rows = [
        feedback(id: 'new', title: '최신 문의', category: FeedbackCategory.bug),
        feedback(
          id: 'old',
          title: '이전 제안',
          category: FeedbackCategory.suggestion,
          status: FeedbackStatus.reviewing,
        ),
      ];
      await tester.pumpWidget(
        testApp(
          child: const AdminFeedbackPage(),
          auth: const AuthStatus('admin'),
          admin: const AdminAccess(userId: 'admin', isAdmin: true),
          rows: rows,
        ),
      );
      await tester.pumpAndSettle();
      final newestTitle = find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data?.startsWith('최신 문의\n') == true,
      );
      final olderTitle = find.byWidgetPredicate(
        (widget) =>
            widget is Text && widget.data?.startsWith('이전 제안\n') == true,
      );
      expect(newestTitle, findsOneWidget);
      expect(find.text('오류 신고'), findsOneWidget);
      expect(find.text('확인중'), findsNWidgets(2));
      expect(
        tester.getTopLeft(newestTitle).dy,
        lessThan(tester.getTopLeft(olderTitle).dy),
      );
    },
  );

  testWidgets('admin detail shows content and diagnostic metadata', (
    tester,
  ) async {
    final row = feedback(
      id: 'detail',
      title: '긴 제목 ' * 20,
      body: '긴 문의 내용 ' * 100,
      category: FeedbackCategory.other,
    );
    await tester.pumpWidget(
      testApp(
        child: const AdminFeedbackDetailPage(id: 'detail'),
        auth: const AuthStatus('admin'),
        admin: const AdminAccess(userId: 'admin', isAdmin: true),
        rows: [row],
        detailId: 'detail',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('기타'), findsOneWidget);
    expect(find.textContaining('긴 제목'), findsOneWidget);
    expect(find.textContaining('긴 문의 내용'), findsOneWidget);
    for (final label in ['앱 버전', '빌드 번호', '플랫폼', 'OS', 'locale']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('admin status workflow exposes only forward actions', (
    tester,
  ) async {
    final row = feedback(id: 'workflow');
    await tester.pumpWidget(
      testApp(
        child: const AdminFeedbackDetailPage(id: 'workflow'),
        auth: const AuthStatus('admin'),
        admin: const AdminAccess(userId: 'admin', isAdmin: true),
        rows: [row],
        detailId: 'workflow',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('확인중으로 변경'), findsOneWidget);
    expect(find.text('처리완료로 변경'), findsNothing);
    expect(find.textContaining('되돌'), findsNothing);
  });
}
