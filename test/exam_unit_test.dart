import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/exam_unit.dart';

void main() {
  final f = jsonDecode(
    File('test/fixtures/essay_exam_unit.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final c = f['catalog'] as Map<String, dynamic>;
  final answers = (f['answers'] as List).cast<Map<String, dynamic>>();
  test('Native and WEB share snapshot order and exact request hash', () {
    final snapshot = freezeExamUnit(f['owner'] as String, c, answers);
    expect(snapshot, f['snapshot']);
    expect(examUnitRequestHash(snapshot, null), f['hash']);
    expect(examUnitRequestHash(snapshot, 'parent'), isNot(f['hash']));
    expect(() => (snapshot['answers'] as List).clear(), throwsUnsupportedError);
  });
  test('unreviewed, Math, source-only IDs and foreign questions cannot reserve exams', () {
    for (final change in [
      {'reviewed': false},
      {'billing': 'MATH_QUESTION'},
      {'examId': 'source-only'},
    ]) {
      expect(
        () => freezeExamUnit(f['owner'] as String, {...c, ...change}, answers),
        throwsStateError,
      );
    }
    expect(
      () => freezeExamUnit(f['owner'] as String, c, [
        {...answers.first, 'questionId': 'foreign'},
      ]),
      throwsStateError,
    );
    expect(
      () => freezeExamUnit(f['owner'] as String, c, [
        answers.first,
        answers.first,
      ]),
      throwsStateError,
    );
    expect(
      () => freezeExamUnit(f['owner'] as String, c, [
        {...answers.first, 'body': ' '},
      ]),
      throwsStateError,
    );
  });
  test('Native included revision freezes exam, question set and versions for 14 days', () {
    final parent = freezeExamUnit(f['owner'] as String, c, answers);
    final settled = DateTime.utc(2026, 1, 1);
    Map<String, dynamic> revise(
      List<Map<String, dynamic>> changes, {
      int days = 14,
      bool used = false,
      Map<String, dynamic>? catalog,
    }) => freezeExamReevaluation(
      f['owner'] as String,
      catalog ?? c,
      parent,
      changes,
      settledAt: settled,
      now: settled.add(Duration(days: days)),
      includedUsed: used,
    );
    final next = revise([
      {...answers.first, 'body': '직접 수정한 답안', 'revision': 2},
    ]);
    expect((next['answers'] as List).length, 2);
    expect(() => revise([], days: 15), throwsStateError);
    expect(() => revise([], used: true), throwsStateError);
    expect(
      () => revise([
        {...answers.first, 'questionId': 'foreign'},
      ]),
      throwsStateError,
    );
    expect(
      () => revise([
        {...answers.first, 'body': '수정', 'revision': 1},
      ]),
      throwsStateError,
    );
    expect(
      () => revise([], catalog: {...c, 'campus': '다른 캠퍼스'}),
      throwsStateError,
    );
  });
}
