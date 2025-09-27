import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../shared/models/family_model.dart';
import '../../../../shared/repositories/family_repository.dart';
import '../../../../app/injection_container.dart' as di;

part 'family_event.dart';
part 'family_state.dart';

class FamilyBloc extends Bloc<FamilyEvent, FamilyState> {
  final FamilyRepository _familyRepository = di.sl<FamilyRepository>();

  FamilyBloc() : super(FamilyInitial()) {
    on<FamilyCheckStatus>(_onCheckStatus);
    on<FamilyJoinRequested>(_onJoinRequested);
    on<FamilyGetInfo>(_onGetInfo);
  }

  Future<void> _onCheckStatus(
    FamilyCheckStatus event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    try {
      final hasFamily = await _familyRepository.hasFamilyConnection();
      if (hasFamily) {
        final family = await _familyRepository.getCachedFamily();
        if (family != null) {
          emit(FamilyConnected(family: family));
        } else {
          // Try to fetch from server
          final response = await _familyRepository.getFamilyInfo();
          if (response.success && response.data != null) {
            emit(FamilyConnected(family: response.data!));
          } else {
            emit(FamilyNotConnected());
          }
        }
      } else {
        emit(FamilyNotConnected());
      }
    } catch (e) {
      emit(FamilyError(message: e.toString()));
    }
  }

  Future<void> _onJoinRequested(
    FamilyJoinRequested event,
    Emitter<FamilyState> emit,
  ) async {
    emit(FamilyLoading());

    try {
      final response = await _familyRepository.joinFamily(
        familyCode: event.familyId,
      );

      if (response.success && response.data != null) {
        emit(FamilyJoinSuccess(family: response.data!));
        emit(FamilyConnected(family: response.data!));
      } else {
        emit(
          FamilyError(
            message: response.message ?? 'Gagal bergabung dengan keluarga',
          ),
        );
      }
    } catch (e) {
      emit(FamilyError(message: 'Terjadi kesalahan: ${e.toString()}'));
    }
  }

  Future<void> _onGetInfo(
    FamilyGetInfo event,
    Emitter<FamilyState> emit,
  ) async {
    try {
      final response = await _familyRepository.getFamilyInfo();
      if (response.success && response.data != null) {
        emit(FamilyConnected(family: response.data!));
      }
    } catch (e) {
      // Ignore error for background refresh
    }
  }
}
