import 'dart:async';

import 'package:flutter/foundation.dart';

import 'essay_models.dart';

class EssayController extends ChangeNotifier {
  EssayController(this.gateway, {String initialBody = ''}) : body = initialBody;
  final EssayGateway gateway;
  String body, firstAnswer = '';
  int revision = 0;
  EssayStage stage = EssayStage.writing;
  DraftStatus draftStatus = DraftStatus.saved;
  EssayEvaluation? evaluation;
  Timer? _debounce;
  Future<void>? _save;
  bool _disposed = false, dirty = false;
  String? _attemptId;
  int _submissionSequence = 0;
  void emit() {
    if (!_disposed) notifyListeners();
  }

  void edit(String value) {
    body = value;
    dirty = true;
    if (draftStatus != DraftStatus.conflict) draftStatus = DraftStatus.saving;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), save);
    emit();
  }

  Future<void> save() async {
    _debounce?.cancel();
    if (_save != null) {
      await _save;
      if (!_disposed && dirty) await save();
      return;
    }
    if (!dirty || _disposed || draftStatus == DraftStatus.conflict) return;
    final snapshot = body;
    draftStatus = DraftStatus.saving;
    emit();
    _save = () async {
      try {
        final saved = await gateway.saveDraft(snapshot, revision);
        if (_disposed) return;
        revision = saved.revision;
        dirty = body != snapshot;
        draftStatus = dirty ? DraftStatus.saving : DraftStatus.saved;
      } on EssayConflict {
        draftStatus = DraftStatus.conflict;
      } catch (_) {
        draftStatus = DraftStatus.failed;
      }
      emit();
    }();
    await _save;
    _save = null;
    if (!_disposed && dirty && draftStatus == DraftStatus.saving) await save();
  }

  Future<void> reloadDraft() async {
    final saved = await gateway.loadDraft();
    if (_disposed) return;
    body = saved.body;
    revision = saved.revision;
    dirty = false;
    draftStatus = DraftStatus.saved;
    emit();
  }

  Future<void> submit() async {
    if (stage == EssayStage.processing ||
        body.trim().isEmpty ||
        draftStatus == DraftStatus.conflict) {
      return;
    }
    final previous = stage;
    stage = EssayStage.processing;
    emit();
    await save();
    if (_disposed) return;
    if (draftStatus != DraftStatus.saved) {
      stage = previous;
      emit();
      return;
    }
    try {
      _attemptId ??= await gateway.submit(
        body,
        revision,
        'submission-$_submissionSequence',
      );
      if (firstAnswer.isEmpty) firstAnswer = body;
      evaluation = await gateway.requestEvaluation(_attemptId!);
      if (_disposed) return;
      stage = _submissionSequence == 0
          ? EssayStage.result
          : EssayStage.comparison;
    } on EssayConflict {
      stage = previous;
      draftStatus = DraftStatus.conflict;
    } catch (_) {
      stage = EssayStage.failed;
    }
    emit();
  }

  void rewrite() {
    _attemptId = null;
    _submissionSequence++;
    stage = EssayStage.revising;
    emit();
  }

  @override
  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    super.dispose();
  }
}
