import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paths_mobile/core/network/generated/api_contract.dart';
import 'package:paths_mobile/features/auth/domain/auth_models.dart';
import 'package:paths_mobile/features/safety/domain/safety_repository.dart';
import 'package:paths_mobile/features/safety/presentation/report_cubit.dart';
import 'package:paths_mobile/features/safety/presentation/blocked_accounts_cubit.dart';

class FakeSafety implements SafetyRepository {
  @override
  String? accountId = 'owner';
  final events = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => events.stream;
  final sent = <ReportInput>[];
  Future<ReportReceiptDto> Function()? response;
  Future<void> Function()? blockResponse;
  int preparations = 0;
  Future<ReportEvidenceDto> Function()? prepareResponse;
  Future<ReportMessagesPageDto> Function()? messageResponse;
  Future<void> Function()? unblockResponse;
  Future<BlockedPageDto> Function()? listResponse;
  @override
  Future<ReportEvidenceDto> preparePost(
    ReportEvidenceInput input, {
    CancelToken? cancelToken,
  }) async {
    preparations++;
    if (prepareResponse != null) return prepareResponse!();
    return const ReportEvidenceDto(
      validForSeconds: 900,
      grantId: 'grant',
      expiresAt: '2026-10-18T00:00:00Z',
    );
  }

  @override
  Future<ReportMessagesPageDto> reportableMessages(
    String subject, {
    String? cursor,
    CancelToken? cancelToken,
  }) async =>
      messageResponse?.call() ??
      Future.value(const ReportMessagesPageDto(items: [], nextCursor: null));
  @override
  Future<ReportReceiptDto> report(
    ReportInput input, {
    CancelToken? cancelToken,
  }) async {
    sent.add(input);
    return response?.call() ??
        Future.value(
          const ReportReceiptDto(id: 'reference', status: 'received'),
        );
  }

  @override
  Future<void> block(String target, {CancelToken? cancelToken}) async {
    await blockResponse?.call();
  }

  @override
  Future<void> unblock(String target, {CancelToken? cancelToken}) async {
    await unblockResponse?.call();
  }

  @override
  Future<BlockedPageDto> blocked({
    String? cursor,
    CancelToken? cancelToken,
  }) async =>
      listResponse?.call() ??
      Future.value(const BlockedPageDto(items: [], nextCursor: null));
}

void main() {
  test('failed report retries its original intent; edited report starts another intent', () async {
    final r = FakeSafety();
    final subject = ReportCubit(
      r,
      const SafetyTarget('peer', kind: 'message', contentId: 'message'),
    );
    r.response = () async => throw const AuthFailure('offline');
    await subject.submit('harassment', 'details');
    expect(subject.state.receipt, isNull);
    expect(subject.state.error, isNotNull);
    await subject.submit('harassment', 'details');
    expect(r.sent[0].clientReportId, r.sent[1].clientReportId);
    await subject.submit('threats', 'changed');
    expect(r.sent[2].clientReportId, isNot(r.sent[1].clientReportId));
    r.response = null;
    await subject.submit('threats', 'changed');
    expect(subject.state.receipt, 'reference');
    await subject.close();
    await r.events.close();
  });
  test(
    'blocking leaves report available and prevents duplicate block submission',
    () async {
      final r = FakeSafety(),
          c = ReportCubit(FakeSafety(), const SafetyTarget('peer'));
      await c.close();
      final subject = ReportCubit(r, const SafetyTarget('peer'));
      var calls = 0;
      final pending = Completer<void>();
      r.blockResponse = () {
        calls++;
        return pending.future;
      };
      final first = subject.block();
      await subject.block();
      expect(calls, 1);
      expect(subject.state.blocked, false);
      pending.complete();
      await first;
      expect(subject.state.blocked, true);
      await subject.submit('suspected_minor', '');
      expect(subject.state.receipt, 'reference');
      expect(subject.state.blocked, true);
      await subject.close();
      await r.events.close();
    },
  );
  test(
    'account switch drops late acknowledgment and does not allow new actions',
    () async {
      final r = FakeSafety(), pending = Completer<ReportReceiptDto>();
      r.response = () => pending.future;
      final c = ReportCubit(r, const SafetyTarget('peer'));
      final send = c.submit('other', '');
      await Future<void>.delayed(Duration.zero);
      r.accountId = 'new';
      pending.complete(const ReportReceiptDto(id: 'old', status: 'received'));
      await send;
      expect(c.state.receipt, isNull);
      await c.submit('other', '');
      expect(r.sent.length, 1);
      await c.close();
      await r.events.close();
    },
  );
  test('late blocked-list refresh cannot restore an unblocked row', () async {
    final r = FakeSafety(), pending = Completer<BlockedPageDto>();
    const page = BlockedPageDto(
      items: [BlockedAccountDto(userId: 'peer', name: 'Peer')],
      nextCursor: null,
    );
    r.listResponse = () async => page;
    final c = BlockedCubit(r);
    await c.load();
    r.listResponse = () => pending.future;
    final refresh = c.load();
    await c.unblock('peer');
    expect(c.state.items, isEmpty);
    pending.complete(page);
    await refresh;
    expect(c.state.items, isEmpty);
    await c.close();
    await r.events.close();
  });
  test(
    'failed unblock retains the row and can retry without a false success',
    () async {
      final r = FakeSafety();
      r.listResponse = () async => const BlockedPageDto(
        items: [BlockedAccountDto(userId: 'peer', name: 'Peer')],
        nextCursor: null,
      );
      final c = BlockedCubit(r);
      await c.load();
      r.unblockResponse = () async => throw const AuthFailure('offline');
      await c.unblock('peer');
      expect(c.state.items.length, 1);
      expect(c.state.error, isNotNull);
      r.unblockResponse = null;
      await c.unblock('peer');
      expect(c.state.items, isEmpty);
      await c.close();
      await r.events.close();
    },
  );
  test('post evidence is prepared before blocking and remains scoped on submission', () async {
    final r = FakeSafety();
    r.blockResponse = () async {
      expect(r.preparations, 1);
    };
    final c = ReportCubit(
      r,
      const SafetyTarget('peer', kind: 'post', contentId: 'post'),
    );
    await c.prepare();
    await c.block();
    expect(c.state.blocked, true);
    await c.submit('other', '');
    expect(r.sent.single.evidenceGrantId, 'grant');
    expect(r.sent.single.contentId, 'post');
    expect(r.preparations, 1);
    await c.close();
    await r.events.close();
  });
  test('failed evidence preparation never prevents blocking', () async {
    final r = FakeSafety();
    r.prepareResponse = () async => throw const AuthFailure('RATE_LIMITED');
    final c = ReportCubit(
      r,
      const SafetyTarget('peer', kind: 'post', contentId: 'post'),
    );
    await c.prepare();
    await c.block();
    expect(c.state.blocked, true);
    expect(c.state.problem, EvidenceProblem.unavailable);
    c.reportMemberInstead();
    await c.submit('other', '');
    expect(r.sent.single.kind, 'profile');
    expect(r.sent.single.contentId, isNull);
    await c.close();
    await r.events.close();
  });
  test('blocking does not wait for a pending evidence request', () async {
    final r = FakeSafety(), pending = Completer<ReportEvidenceDto>();
    r.prepareResponse = () => pending.future;
    final c = ReportCubit(
      r,
      const SafetyTarget('peer', kind: 'post', contentId: 'post'),
    );
    final preparation = c.prepare();
    await c.block();
    expect(c.state.blocked, true);
    pending.complete(
      const ReportEvidenceDto(
        grantId: 'grant',
        expiresAt: 'unused',
        validForSeconds: 900,
      ),
    );
    await preparation;
    await c.submit('other', '');
    expect(r.sent.single.evidenceGrantId, 'grant');
    await c.close();
    await r.events.close();
  });
  test('expired post grant is renewed before a new report', () async {
    var elapsed = 0;
    final r = FakeSafety();
    final c = ReportCubit(
      r,
      const SafetyTarget('peer', kind: 'post', contentId: 'post'),
      elapsedMilliseconds: () => elapsed,
    );
    await c.prepare();
    elapsed = 901000;
    await c.submit('other', '');
    expect(r.preparations, 2);
    expect(c.state.receipt, 'reference');
    await c.close();
    await r.events.close();
  });
  test(
    'expired blocked evidence offers explicit member-report recovery',
    () async {
      var elapsed = 0;
      final r = FakeSafety();
      final c = ReportCubit(
        r,
        const SafetyTarget('peer', kind: 'post', contentId: 'post'),
        elapsedMilliseconds: () => elapsed,
      );
      await c.prepare();
      await c.block();
      elapsed = 901000;
      await c.submit('other', '');
      expect(c.state.problem, EvidenceProblem.expired);
      expect(r.sent, isEmpty);
      c.reportMemberInstead();
      await c.submit('other', '');
      expect(r.sent.single.kind, 'profile');
      expect(c.state.receipt, 'reference');
      await c.close();
      await r.events.close();
    },
  );
  test(
    'uncertain report retries original body after evidence expiry',
    () async {
      var elapsed = 0;
      final r = FakeSafety();
      final c = ReportCubit(
        r,
        const SafetyTarget('peer', kind: 'post', contentId: 'post'),
        elapsedMilliseconds: () => elapsed,
      );
      r.response = () async => throw const AuthFailure('offline');
      await c.submit('other', '');
      await c.block();
      elapsed = 901000;
      r.response = null;
      await c.submit('other', '');
      expect(r.sent.length, 2);
      expect(r.sent[0].clientReportId, r.sent[1].clientReportId);
      expect(r.sent[0].evidenceGrantId, r.sent[1].evidenceGrantId);
      expect(r.preparations, 1);
      expect(c.state.receipt, 'reference');
      await c.close();
      await r.events.close();
    },
  );
  test(
    'uncommitted expired attempt renews once while access remains active',
    () async {
      var elapsed = 0;
      final r = FakeSafety();
      final c = ReportCubit(
        r,
        const SafetyTarget('peer', kind: 'post', contentId: 'post'),
        elapsedMilliseconds: () => elapsed,
      );
      r.response = () async => throw const AuthFailure('offline');
      await c.submit('other', '');
      elapsed = 901000;
      var calls = 0;
      r.response = () async {
        if (calls++ == 0) throw const AuthFailure('NOT_FOUND');
        return const ReportReceiptDto(id: 'renewed', status: 'received');
      };
      await c.submit('other', '');
      expect(r.preparations, 2);
      expect(r.sent[0].clientReportId, r.sent[1].clientReportId);
      expect(r.sent[2].clientReportId, isNot(r.sent[1].clientReportId));
      expect(c.state.receipt, 'renewed');
      await c.close();
      await r.events.close();
    },
  );
}
