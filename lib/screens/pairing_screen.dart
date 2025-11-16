import 'dart:developer' as developer;
import 'package:couple_guard_child/screens/permission_screen.dart';
import 'package:couple_guard_child/services/device_service.dart';
import 'package:couple_guard_child/utils/local_storage.dart'
    show LocalStorageService;
import 'package:couple_guard_child/utils/native_bridge.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/pairing_controller.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  static const String _tag = 'PairingScreen';

  final PairingController _controller = Get.put(PairingController());
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Auto focus pada input pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(int index, String value) {
    // Handle paste dari clipboard
    if (value.length > 1) {
      _handlePaste(value, index);
      return;
    }

    if (value.length == 1) {
      // Pindah ke input berikutnya
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Jika sudah di input terakhir, hilangkan keyboard
        _focusNodes[index].unfocus();
      }
    }

    // Auto submit ketika semua terisi
    _checkAndSubmit();
  }

  void _onKeyEvent(int index, KeyEvent event) {
    // Handle backspace/delete
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace ||
          event.logicalKey == LogicalKeyboardKey.delete) {
        if (_codeControllers[index].text.isEmpty && index > 0) {
          // Pindah ke input sebelumnya jika kosong
          _focusNodes[index - 1].requestFocus();
          _codeControllers[index - 1].clear();
        }
      }
    }
  }

  void _handlePaste(String pastedText, int startIndex) {
    // Bersihkan text yang di-paste (hanya ambil alphanumeric)
    final cleanText = pastedText
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]'), '')
        .substring(0, pastedText.length > 6 ? 6 : pastedText.length);

    // Isi input fields
    for (int i = 0; i < cleanText.length && (startIndex + i) < 6; i++) {
      _codeControllers[startIndex + i].text = cleanText[i];
    }

    // Fokus ke input terakhir yang terisi atau yang kosong berikutnya
    final lastFilledIndex = startIndex + cleanText.length - 1;
    if (lastFilledIndex < 5) {
      _focusNodes[lastFilledIndex + 1].requestFocus();
    } else {
      _focusNodes[lastFilledIndex].unfocus();
    }

    _checkAndSubmit();
  }

  void _checkAndSubmit() {
    String fullCode = _codeControllers.map((c) => c.text).join();
    if (fullCode.length == 6) {
      FocusScope.of(context).unfocus();
      _submitCode(fullCode);
    }
  }

  void _clearAllInputs() {
    for (var controller in _codeControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    _controller.errorMessage.value = '';
  }

  Future<void> _submitCode(String code) async {
    developer.log('========================================', name: _tag);
    developer.log('🔗 Starting pairing process with code: $code', name: _tag);

    try {
      // Step 1: Pair device via API
      developer.log('Step 1: Pairing device with server', name: _tag);
      final success = await _controller.pairDevice(code);

      if (!success) {
        developer.log('❌ Pairing failed', name: _tag, level: 900);
        return;
      }

      developer.log('✅ Device paired successfully', name: _tag);

      // Step 2: Sync data to Android Native
      developer.log('Step 2: Syncing data to Android Native', name: _tag);

      final deviceId = await LocalStorageService.getDeviceId();
      final familyCode = await LocalStorageService.getFamilyCode();
      final parentId = await LocalStorageService.getParentId();

      if (deviceId != null) {
        await NativeBridgeHelper.syncDeviceDataToNative(
          deviceId: deviceId,
          isPaired: true,
          familyCode: familyCode,
          parentId: parentId,
        );
        developer.log('✅ Data synced to Native', name: _tag);
      }

      // Step 3: Get and update FCM token
      developer.log('Step 3: Updating FCM token', name: _tag);

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final deviceService = Get.find<DeviceService>();
        final tokenUpdated = await deviceService.updateFcmToken(fcmToken);

        if (tokenUpdated) {
          developer.log('✅ FCM token synced with server', name: _tag);
        } else {
          developer.log('⚠️ Failed to sync FCM token', name: _tag);
        }
      } else {
        developer.log('⚠️ FCM token is empty', name: _tag);
      }

      // Step 4: Start tracking services
      developer.log('Step 4: Starting tracking services', name: _tag);

      final servicesStarted = await NativeBridgeHelper.startTrackingServices();

      if (servicesStarted) {
        developer.log('✅ Tracking services started', name: _tag);
      } else {
        developer.log('⚠️ Failed to start tracking services', name: _tag);
      }

      developer.log('========================================', name: _tag);

      // Step 5: Navigate to permission screen
      Get.off(() => const PermissionScreen());
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error during pairing process',
        name: _tag,
        error: e,
        stackTrace: stackTrace,
        level: 1000,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  size: 50,
                  color: Colors.blue,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Enter Family Code',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                'Ask your parent for the 6-character\nfamily code to connect this device',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Hitung lebar yang tersedia untuk setiap box
                  final availableWidth = constraints.maxWidth;
                  final totalMargin = 6 * 2 * 6; // 6 boxes * 2 sides * 6 pixels
                  final boxWidth = ((availableWidth - totalMargin) / 6).clamp(
                    40.0,
                    50.0,
                  );
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(6, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: SizedBox(
                          width: boxWidth,
                          height: 56,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) => _onKeyEvent(index, event),
                            child: TextField(
                              controller: _codeControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                UpperCaseTextFormatter(),
                              ],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (value) =>
                                  _onCodeChanged(index, value),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),

              // Code Input
              const SizedBox(height: 16),

              // Clear button
              TextButton.icon(
                onPressed: _clearAllInputs,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Clear all'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
              ),

              // Error Message
              Obx(
                () => _controller.errorMessage.value.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _controller.errorMessage.value,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 32),

              // Connect Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _controller.isLoading.value
                        ? null
                        : () {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child: _controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Connect Device',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Help Text
              TextButton.icon(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text('Need Help?'),
                      content: const Text(
                        'Ask your parent to:\n\n'
                        '1. Open the parent app\n'
                        '2. Go to settings or devices\n'
                        '3. Find the 6-character family code\n'
                        '4. Share it with you to connect',
                        style: TextStyle(height: 1.5),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.help_outline, size: 20),
                label: const Text(
                  'Where do I find the code?',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom TextInputFormatter untuk uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
