// ======================================
// 3. Family States
// ======================================

// lib/features/family/presentation/bloc/family_state.dart
part of 'family_bloc.dart';

sealed class FamilyState extends Equatable {
  const FamilyState();

  @override
  List<Object?> get props => [];
}

final class FamilyInitial extends FamilyState {}

final class FamilyLoading extends FamilyState {}

final class FamilyNotConnected extends FamilyState {}

final class FamilyConnected extends FamilyState {
  final FamilyModel family;

  const FamilyConnected({required this.family});

  @override
  List<Object> get props => [family];
}

final class FamilyJoinSuccess extends FamilyState {
  final FamilyModel family;

  const FamilyJoinSuccess({required this.family});

  @override
  List<Object> get props => [family];
}

final class FamilyError extends FamilyState {
  final String message;

  const FamilyError({required this.message});

  @override
  List<Object> get props => [message];
}
