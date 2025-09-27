// ======================================
// 2. Family Events
// ======================================

// lib/features/family/presentation/bloc/family_event.dart

part of 'family_bloc.dart';

sealed class FamilyEvent extends Equatable {
  const FamilyEvent();

  @override
  List<Object?> get props => [];
}

final class FamilyCheckStatus extends FamilyEvent {}

final class FamilyJoinRequested extends FamilyEvent {
  final String familyId;

  const FamilyJoinRequested({required this.familyId});

  @override
  List<Object> get props => [familyId];
}

final class FamilyGetInfo extends FamilyEvent {}
