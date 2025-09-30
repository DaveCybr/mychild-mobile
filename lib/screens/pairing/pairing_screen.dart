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
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

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
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Check if all fields are filled
    String fullCode = _codeControllers.map((c) => c.text).join();
    if (fullCode.length == 6) {
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
    // Get screen size for responsive design
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 600;
    final isLargeScreen = size.width > 600;

    // Calculate responsive sizes
    final iconSize = isSmallScreen ? 80.0 : (isLargeScreen ? 120.0 : 100.0);
    final titleSize = isSmallScreen ? 24.0 : (isLargeScreen ? 32.0 : 28.0);
    final descSize = isSmallScreen ? 14.0 : 16.0;
    final inputSize = isSmallScreen ? 36.0 : (isLargeScreen ? 48.0 : 40.0);
    final inputHeight = isSmallScreen ? 50.0 : 56.0;
    final spacing = isSmallScreen ? 24.0 : (isLargeScreen ? 56.0 : 48.0);

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isLargeScreen ? 48 : 24,
                vertical: isSmallScreen ? 16 : 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxWidth: isLargeScreen ? 500 : double.infinity,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: isSmallScreen ? 20 : 40),

                      // Icon
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.qr_code_2,
                          size: iconSize * 0.5,
                          color: AppColors.primary,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Title
                      Text(
                        'Enter Family Code',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Description
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 32 : 0,
                        ),
                        child: Text(
                          'Ask your parent for the 6-character family code to connect this device',
                          style: TextStyle(
                            fontSize: descSize,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: spacing),

                      // Code input fields - Responsive spacing
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: isLargeScreen
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.spaceEvenly,
                          children: List.generate(6, (index) {
                            return Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: isLargeScreen
                                    ? 8
                                    : (isSmallScreen ? 4 : 6),
                              ),
                              child: SizedBox(
                                width: inputSize,
                                height: inputHeight,
                                child: TextField(
                                  controller: _codeControllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: AppColors.white,
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: AppColors.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onChanged: (value) =>
                                      _onCodeChanged(index, value),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Error message
                      Obx(
                        () => _controller.errorMessage.value.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.all(12),
                                margin: EdgeInsets.symmetric(
                                  horizontal: isLargeScreen ? 32 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _controller.errorMessage.value,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: isSmallScreen ? 13 : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      // const Spacer(),
                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Submit button
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 32 : 0,
                        ),
                        child: Obx(
                          () => _controller.isLoading.value
                              ? const LoadingIndicator()
                              : CustomButton(
                                  text: 'Connect Device',
                                  height: isSmallScreen ? 50 : 56,
                                  onPressed: () {
                                    String fullCode = _codeControllers
                                        .map((c) => c.text)
                                        .join();
                                    if (fullCode.length == 6) {
                                      _submitCode(fullCode);
                                    } else {
                                      _controller.errorMessage.value =
                                          'Please enter all 6 characters';
                                    }
                                  },
                                ),
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
                        child: Text(
                          'Where do I find the code?',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: isSmallScreen ? 13 : 14,
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 8 : 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
