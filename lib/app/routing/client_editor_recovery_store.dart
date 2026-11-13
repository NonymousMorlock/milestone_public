import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:milestone/src/client/presentation/layout/client_route_success_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

enum ClientEditorRecoveryStatus {
  draft,
  saving,
  committed,
}

class ClientEditorRecoveryRecord extends Equatable {
  const ClientEditorRecoveryRecord({
    required this.ownerUserId,
    required this.operationId,
    required this.mode,
    required this.sessionKey,
    required this.clientId,
    required this.targetLocation,
    required this.disposition,
    required this.status,
    this.addRecoveryClaimKey,
    this.addSuccessMode,
    this.editSuccessMode,
  });

  factory ClientEditorRecoveryRecord.fromMap(Map<String, dynamic> map) {
    final mode = ClientEditorRouteMode.values.byName(map['mode'] as String);
    final disposition = ClientEditorRecoveryDisposition.values.byName(
      map['disposition'] as String,
    );
    final status = ClientEditorRecoveryStatus.values.byName(
      map['status'] as String,
    );
    final addSuccessMode = map['addSuccessMode'] as Map<String, dynamic>?;
    final editSuccessMode = map['editSuccessMode'] as Map<String, dynamic>?;

    return ClientEditorRecoveryRecord(
      ownerUserId: map['ownerUserId'] as String,
      operationId: map['operationId'] as String,
      mode: mode,
      sessionKey: map['sessionKey'] as String,
      clientId: map['clientId'] as String,
      targetLocation: map['targetLocation'] as String,
      disposition: disposition,
      status: status,
      addRecoveryClaimKey: map['addRecoveryClaimKey'] as String?,
      addSuccessMode: addSuccessMode == null
          ? null
          : _decodeAddSuccessMode(addSuccessMode),
      editSuccessMode: editSuccessMode == null
          ? null
          : _decodeEditSuccessMode(editSuccessMode),
    );
  }

  final String ownerUserId;
  final String operationId;
  final ClientEditorRouteMode mode;
  final String sessionKey;
  final String clientId;
  final String targetLocation;
  final ClientEditorRecoveryDisposition disposition;
  final String? addRecoveryClaimKey;
  final AddClientRouteSuccessMode? addSuccessMode;
  final EditClientRouteSuccessMode? editSuccessMode;
  final ClientEditorRecoveryStatus status;

  ClientEditorRecoveryRecord copyWith({
    String? ownerUserId,
    String? operationId,
    ClientEditorRouteMode? mode,
    String? sessionKey,
    String? clientId,
    String? targetLocation,
    ClientEditorRecoveryDisposition? disposition,
    Object? addRecoveryClaimKey = _sentinel,
    Object? addSuccessMode = _sentinel,
    Object? editSuccessMode = _sentinel,
    ClientEditorRecoveryStatus? status,
  }) {
    return ClientEditorRecoveryRecord(
      ownerUserId: ownerUserId ?? this.ownerUserId,
      operationId: operationId ?? this.operationId,
      mode: mode ?? this.mode,
      sessionKey: sessionKey ?? this.sessionKey,
      clientId: clientId ?? this.clientId,
      targetLocation: targetLocation ?? this.targetLocation,
      disposition: disposition ?? this.disposition,
      addRecoveryClaimKey: addRecoveryClaimKey == _sentinel
          ? this.addRecoveryClaimKey
          : addRecoveryClaimKey as String?,
      addSuccessMode: addSuccessMode == _sentinel
          ? this.addSuccessMode
          : addSuccessMode as AddClientRouteSuccessMode?,
      editSuccessMode: editSuccessMode == _sentinel
          ? this.editSuccessMode
          : editSuccessMode as EditClientRouteSuccessMode?,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ownerUserId': ownerUserId,
      'operationId': operationId,
      'mode': mode.name,
      'sessionKey': sessionKey,
      'clientId': clientId,
      'targetLocation': targetLocation,
      'disposition': disposition.name,
      'addRecoveryClaimKey': addRecoveryClaimKey,
      'status': status.name,
      'addSuccessMode': addSuccessMode == null
          ? null
          : _encodeAddSuccessMode(addSuccessMode!),
      'editSuccessMode': editSuccessMode == null
          ? null
          : _encodeEditSuccessMode(editSuccessMode!),
    };
  }

  @override
  List<Object?> get props => [
    ownerUserId,
    operationId,
    mode,
    sessionKey,
    clientId,
    targetLocation,
    disposition,
    addRecoveryClaimKey,
    addSuccessMode,
    editSuccessMode,
    status,
  ];
}

enum ClientEditorRouteMode {
  add,
  edit,
}

class ClientEditorRecoveryStore {
  ClientEditorRecoveryStore({
    required SharedPreferences prefs,
    Uuid? uuid,
  }) : _prefs = prefs,
       _uuid = uuid ?? const Uuid() {
    final raw = _prefs.getString(_kClientEditorRecoveryKey);
    if (raw == null || raw.isEmpty) {
      return;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List<dynamic>) {
      return;
    }

    for (final item in decoded.whereType<Map<String, dynamic>>()) {
      final record = ClientEditorRecoveryRecord.fromMap(item);
      _records[record.operationId] = record;
    }
  }

  final SharedPreferences _prefs;
  final Uuid _uuid;
  final Map<String, ClientEditorRecoveryRecord> _records = {};

  ClientEditorRecoveryRecord ensureAddDraftForRouteEntry({
    required String ownerUserId,
    required String sessionKey,
    required AddClientRouteSuccessMode successMode,
  }) {
    final existingBySession = readBySession(
      ownerUserId: ownerUserId,
      sessionKey: sessionKey,
    );
    if (existingBySession != null) {
      return existingBySession;
    }

    final existingByClaimKey = readUnresolvedAddByClaimKey(
      ownerUserId: ownerUserId,
      claimKey: successMode.recoveryClaimKey,
    );
    if (existingByClaimKey != null) {
      final rebound = existingByClaimKey.copyWith(
        ownerUserId: ownerUserId,
        sessionKey: sessionKey,
        targetLocation: successMode.recoveryTargetLocation,
        disposition: successMode.recoveryDisposition,
        addRecoveryClaimKey: successMode.recoveryClaimKey,
        addSuccessMode: successMode,
      );
      _persist(rebound);
      return rebound;
    }

    final record = ClientEditorRecoveryRecord(
      ownerUserId: ownerUserId,
      operationId: _uuid.v4(),
      mode: ClientEditorRouteMode.add,
      sessionKey: sessionKey,
      clientId: _uuid.v4(),
      targetLocation: successMode.recoveryTargetLocation,
      disposition: successMode.recoveryDisposition,
      addRecoveryClaimKey: successMode.recoveryClaimKey,
      addSuccessMode: successMode,
      status: ClientEditorRecoveryStatus.draft,
    );
    _persist(record);
    return record;
  }

  ClientEditorRecoveryRecord ensureEditDraft({
    required String ownerUserId,
    required String sessionKey,
    required String clientId,
    required EditClientRouteSuccessMode successMode,
  }) {
    final existing = readBySession(
      ownerUserId: ownerUserId,
      sessionKey: sessionKey,
    );
    if (existing != null) {
      return existing;
    }

    final record = ClientEditorRecoveryRecord(
      ownerUserId: ownerUserId,
      operationId: _uuid.v4(),
      mode: ClientEditorRouteMode.edit,
      sessionKey: sessionKey,
      clientId: clientId,
      targetLocation: successMode.recoveryTargetLocation,
      disposition: successMode.recoveryDisposition,
      editSuccessMode: successMode,
      status: ClientEditorRecoveryStatus.draft,
    );
    _persist(record);
    return record;
  }

  Future<void> markSaving({
    required String ownerUserId,
    required String operationId,
  }) async {
    _updateStatus(
      ownerUserId: ownerUserId,
      operationId: operationId,
      status: ClientEditorRecoveryStatus.saving,
    );
  }

  Future<void> markDraft({
    required String ownerUserId,
    required String operationId,
  }) async {
    _updateStatus(
      ownerUserId: ownerUserId,
      operationId: operationId,
      status: ClientEditorRecoveryStatus.draft,
    );
  }

  Future<void> markCommitted({
    required String ownerUserId,
    required String operationId,
  }) async {
    _updateStatus(
      ownerUserId: ownerUserId,
      operationId: operationId,
      status: ClientEditorRecoveryStatus.committed,
    );
  }

  ClientEditorRecoveryRecord? readBySession({
    required String ownerUserId,
    required String sessionKey,
  }) {
    return _records.values.firstWhereOrNull((record) {
      return record.ownerUserId == ownerUserId &&
          record.sessionKey == sessionKey;
    });
  }

  ClientEditorRecoveryRecord? readUnresolvedAddByClaimKey({
    required String ownerUserId,
    required String claimKey,
  }) {
    return _records.values.firstWhereOrNull((record) {
      return record.ownerUserId == ownerUserId &&
          record.mode == ClientEditorRouteMode.add &&
          record.status != ClientEditorRecoveryStatus.committed &&
          record.addRecoveryClaimKey == claimKey;
    });
  }

  ClientEditorRecoveryRecord? readCommittedForTarget({
    required String ownerUserId,
    required String targetLocation,
  }) {
    return _records.values.firstWhereOrNull((record) {
      return record.ownerUserId == ownerUserId &&
          record.status == ClientEditorRecoveryStatus.committed &&
          record.targetLocation == targetLocation;
    });
  }

  Future<void> consume({
    required String ownerUserId,
    required String operationId,
  }) async {
    final record = _records[operationId];
    if (record == null || record.ownerUserId != ownerUserId) {
      return;
    }

    _records.remove(operationId);
    _flush();
  }

  Future<void> clearForSession({
    required String ownerUserId,
    required String sessionKey,
  }) async {
    final operationIds = _records.values
        .where((record) {
          return record.ownerUserId == ownerUserId &&
              record.sessionKey == sessionKey;
        })
        .map((record) => record.operationId)
        .toList();

    if (operationIds.isEmpty) {
      return;
    }

    operationIds.forEach(_records.remove);
    _flush();
  }

  void _updateStatus({
    required String ownerUserId,
    required String operationId,
    required ClientEditorRecoveryStatus status,
  }) {
    final record = _records[operationId];
    if (record == null || record.ownerUserId != ownerUserId) {
      return;
    }

    _persist(record.copyWith(status: status));
  }

  void _persist(ClientEditorRecoveryRecord record) {
    _records[record.operationId] = record;
    _flush();
  }

  void _flush() {
    final payload = _records.values.map((record) => record.toMap()).toList();
    unawaited(_prefs.setString(_kClientEditorRecoveryKey, jsonEncode(payload)));
  }
}

const _kClientEditorRecoveryKey = 'client_editor_recovery_store_v1';
const _sentinel = Object();

Map<String, dynamic> _encodeAddSuccessMode(AddClientRouteSuccessMode mode) {
  return <String, dynamic>{
    'kind': mode.kind,
    'recoveryTargetLocation': mode.recoveryTargetLocation,
  };
}

AddClientRouteSuccessMode _decodeAddSuccessMode(Map<String, dynamic> map) {
  final kind = map['kind'] as String;
  final target = map['recoveryTargetLocation'] as String;

  return switch (kind) {
    'returnCreatedClient' => AddClientRouteSuccessMode.returnCreatedClient(
      recoveryTargetLocation: target,
    ),
    'returnCreatedClientAndRefreshList' =>
      const AddClientRouteSuccessMode.returnCreatedClientAndRefreshList(),
    _ => const AddClientRouteSuccessMode.goToClients(),
  };
}

Map<String, dynamic> _encodeEditSuccessMode(EditClientRouteSuccessMode mode) {
  return <String, dynamic>{
    'kind': mode.kind,
    'recoveryTargetLocation': mode.recoveryTargetLocation,
  };
}

EditClientRouteSuccessMode _decodeEditSuccessMode(Map<String, dynamic> map) {
  final kind = map['kind'] as String;
  final target = map['recoveryTargetLocation'] as String;

  return switch (kind) {
    'returnUpdatedFlag' => EditClientRouteSuccessMode.returnUpdatedFlag(
      recoveryTargetLocation: target,
    ),
    _ => EditClientRouteSuccessMode.goToClientDetails(
      clientId: target.split('/').last,
    ),
  };
}

extension _FirstWhereOrNullExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
