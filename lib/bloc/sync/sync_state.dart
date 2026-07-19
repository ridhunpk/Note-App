import 'package:equatable/equatable.dart';

class SyncState extends Equatable {
  final bool isSyncing;
  final String? error;
  final DateTime? lastSyncedAt;

  const SyncState({
    this.isSyncing = false,
    this.error,
    this.lastSyncedAt,
  });

  static const _keepError = Object();

  SyncState copyWith({
    bool? isSyncing,
    Object? error = _keepError,
    DateTime? lastSyncedAt,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      error: identical(error, _keepError)
          ? this.error
          : error as String?,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  SyncState clearError() => SyncState(
        isSyncing: isSyncing,
        lastSyncedAt: lastSyncedAt,
      );

  @override
  List<Object?> get props => [isSyncing, error, lastSyncedAt];
}