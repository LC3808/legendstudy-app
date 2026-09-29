import 'dart:async';

import 'essay_controller.dart';
import 'essay_live_gateway.dart';
import 'essay_models.dart';

class EssayLiveController extends EssayController {
  EssayLiveController(this.live, EssayDraft draft)
    : super(live, initialBody: draft.body) {
    revision = draft.revision;
    if (live.history.attempts.isNotEmpty) {
      firstAnswer = live.history.attempts.first['body'] as String;
    }
  }
  final SupabaseEssayGateway live;
  EssayServerStatus? serverStatus;
  String? message;
  Timer? _poll;
  bool _closed = false, _busy = false;
  String? _submitted;
  bool get canRequest => live.writesEnabled && live.evaluationsEnabled;
  bool get hasPending =>
      serverStatus?.state == 'processing' ||
      serverStatus?.state == 'reconciling';
  Future<void> restore() async {
    _submitted = live.attemptId;
    if (live.evaluationId != null) {
      stage = EssayStage.processing;
      await refreshStatus();
    }
  }

  @override
  Future<void> submit() async {
    if (_busy ||
        _closed ||
        hasPending ||
        !canRequest ||
        body.trim().isEmpty ||
        draftStatus == DraftStatus.conflict) {
      return;
    }
    _busy = true;
    message = null;
    stage = EssayStage.processing;
    emit();
    try {
      await save();
      if (_closed) return;
      if (draftStatus != DraftStatus.saved) {
        stage = EssayStage.writing;
        return;
      }
      _submitted ??= await live.submit(body, revision, '');
      if (_closed) return;
      if (firstAnswer.isEmpty) firstAnswer = body;
      if (serverStatus?.state == 'failed') live.retryConfirmedFailure();
      evaluation = await live.requestEvaluation(_submitted!);
      if (_closed) return;
      await _complete();
    } on EssayPending catch (e) {
      _pending(e.status);
    } on EssayConflict {
      draftStatus = DraftStatus.conflict;
      stage = EssayStage.writing;
    } catch (e) {
      _error(e);
    } finally {
      _busy = false;
      if (!_closed) emit();
    }
  }

  Future<void> refreshStatus() async {
    if (_closed || _busy) return;
    _busy = true;
    try {
      evaluation = await live.poll();
      if (!_closed) await _complete();
    } on EssayPending catch (e) {
      _pending(e.status);
    } catch (e) {
      _error(e);
    } finally {
      _busy = false;
      if (!_closed) emit();
    }
  }

  Future<void> _complete() async {
    serverStatus = live.status;
    message = null;
    _poll?.cancel();
    final attempt = live.history.attempts
        .where((a) => a['id'] == live.attemptId)
        .first;
    stage = (attempt['attempt_no'] as int) > 1
        ? EssayStage.comparison
        : EssayStage.result;
  }

  void _pending(EssayServerStatus status) {
    if (_closed) return;
    serverStatus = status;
    message = status.message;
    stage = status.state == 'failed'
        ? EssayStage.failed
        : EssayStage.processing;
    _poll?.cancel();
    if (status.state != 'failed') {
      _poll = Timer(const Duration(seconds: 3), refreshStatus);
    }
  }

  void _error(Object error) {
    if (_closed) return;
    _poll?.cancel();
    message =
        (error is EssayClientError ? error : const EssayClientError('NETWORK'))
            .message;
    stage = EssayStage.failed;
    // Network failure is not authoritative evaluation failure or release.
  }

  Future<void> retry() async {
    if (live.evaluationId != null && serverStatus?.state != 'failed') {
      await refreshStatus();
    } else {
      await submit();
    }
  }

  @override
  void rewrite() {
    if (_closed || evaluation == null) return;
    live.beginRevision();
    _submitted = null;
    serverStatus = null;
    message = null;
    stage = EssayStage.revising;
    emit();
  }

  @override
  void dispose() {
    _closed = true;
    _poll?.cancel();
    live.revoke();
    super.dispose();
  }
}
