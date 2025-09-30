// screens/pairing/pairing_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../controllers/pairing_controller.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_indicator.dart';
import '../permissions/permission_screen.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final PairingController _controller = Get.put(PairingController());
  final TextEditingController _codeController = TextEditingController();
  final List<TextEditingController> _codeControllers = List.generate(
    8,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  @override
  void dispose() {
    _codeController.dispose();
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1 && index < 7) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    String fullCode = _codeControllers.map((c) => c.text).join();
    if (fullCode.length == 8) {
      _submitCode(fullCode);
    }
  }

  Future<void> _submitCode(String code) async {
    final success = await _controller.pairDevice(code);
    if (success) {
      Get.off(() => const PermissionScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Enter Family Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              const Text(
                'Ask your parent for the 8-character family code to connect this device',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Code input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (index) {
                  return SizedBox(
                    width: 40,
                    height: 56,
                    child: TextField(
                      controller: _codeControllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onChanged: (value) => _onCodeChanged(index, value),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),

              // Error message
              Obx(
                () => _controller.errorMessage.value.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _controller.errorMessage.value,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const Spacer(),

              // Submit button
              Obx(
                () => _controller.isLoading.value
                    ? const LoadingIndicator()
                    : CustomButton(
                        text: 'Connect Device',
                        onPressed: () {
                          String fullCode = _codeControllers
                              .map((c) => c.text)
                              .join();
                          if (fullCode.length == 8) {
                            _submitCode(fullCode);
                          } else {
                            _controller.errorMessage.value =
                                'Please enter all 8 characters';
                          }
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Help text
              TextButton(
                onPressed: () {
                  Get.snackbar(
                    'Need Help?',
                    'Ask your parent to open their app and share the family code with you.',
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 4),
                  );
                },
                child: const Text(
                  'Where do I find the code?',
                  style: TextStyle(color: AppColors.primary, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
