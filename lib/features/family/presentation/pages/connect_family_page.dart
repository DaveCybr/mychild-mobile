// lib/features/family/presentation/pages/connect_family_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/common_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../bloc/family_bloc.dart';
import '../widgets/qr_scanner_widget.dart';

class ConnectFamilyPage extends StatefulWidget {
  const ConnectFamilyPage({super.key});

  @override
  State<ConnectFamilyPage> createState() => _ConnectFamilyPageState();
}

class _ConnectFamilyPageState extends State<ConnectFamilyPage> {
  bool _showScanner = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FamilyBloc()..add(FamilyCheckStatus()),
      child: BlocListener<FamilyBloc, FamilyState>(
        listener: (context, state) {
          if (state is FamilyError) {
            context.showSnackBar(
              state.message,
              backgroundColor: AppColors.error,
            );
          } else if (state is FamilyJoinSuccess) {
            context.showSnackBar(
              'Berhasil bergabung dengan keluarga!',
              backgroundColor: AppColors.success,
            );
            // Navigate to permission setup
            context.go(RouteNames.permissionSetup);
          } else if (state is FamilyConnected) {
            // Already connected, go to next step
            context.go(RouteNames.permissionSetup);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Hubungkan Keluarga'),
            centerTitle: true,
          ),
          body: BlocBuilder<FamilyBloc, FamilyState>(
            builder: (context, state) {
              if (state is FamilyLoading) {
                return const Center(
                  child: LoadingWidget(
                    message: 'Menghubungkan dengan keluarga...',
                  ),
                );
              }

              if (_showScanner) {
                return QRScannerWidget(
                  onQRScanned: (familyId) {
                    setState(() {
                      _showScanner = false;
                    });
                    context.read<FamilyBloc>().add(
                      FamilyJoinRequested(familyId: familyId),
                    );
                  },
                  onCancel: () {
                    setState(() {
                      _showScanner = false;
                    });
                  },
                );
              }

              return _buildConnectContent(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConnectContent(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.1),
                          AppColors.primary.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner,
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'Hubungkan dengan Keluarga',
                    style: AppTextStyles.displaySmall,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    'Scan QR code yang ditampilkan di aplikasi orang tua untuk bergabung dengan keluarga Anda',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Instructions
                  _buildInstructionCard(),
                ],
              ),
            ),

            // Scan Button
            CommonButton(
              text: 'Scan QR Code',
              onPressed: () {
                setState(() {
                  _showScanner = true;
                });
              },
              icon: const Icon(Icons.qr_code_scanner, color: AppColors.white),
            ),

            const SizedBox(height: 16),

            // Help text
            Text(
              'Pastikan orang tua Anda telah membuka QR code di aplikasi parent',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cara menghubungkan:', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '1',
            'Buka aplikasi parent di perangkat orang tua',
          ),
          _buildInstructionStep(
            '2',
            'Pilih "Tambah Anak" dan tampilkan QR code',
          ),
          _buildInstructionStep('3', 'Tekan tombol "Scan QR Code" di bawah'),
          _buildInstructionStep(
            '4',
            'Arahkan kamera ke QR code yang ditampilkan',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
