import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kvman/app/router.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/services.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const new({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  static const int otpLength = 6;

  final TextEditingController pinController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FocusNode focusNode = FocusNode();

  String get _maskedPhone {
    final phone = widget.phoneNumber;
    return '${phone.substring(0, 2)}******${phone.substring(8)}';
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verify OTP',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+91 $_maskedPhone',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 36),
              Form(
                key: formKey,
                child: Pinput(
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  autofocus: true,
                  controller: pinController,
                  focusNode: focusNode,
                  length: otpLength,
                  // validator: (value) {
                  //   return value == '2222' ? null : 'Pin is incorrect';
                  // },
                  onCompleted: (pin) {
                    context.go(AppRoutes.home);
                  },
                  hapticFeedbackType: HapticFeedbackType.lightImpact,
                  defaultPinTheme: PinTheme(
                    width: 46,
                    height: 56,
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  focusedPinTheme: PinTheme(
                    width: 46,
                    height: 56,
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.primary),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.center,
              //   children: List.generate(OTP_LENGTH, (index) {
              //     return Container(
              //       width: 46,
              //       height: 56,
              //       margin: EdgeInsets.only(
              //         left: index == 0 ? 0 : 6,
              //         right: index == OTP_LENGTH - 1 ? 0 : 6,
              //       ),
              //       decoration: BoxDecoration(
              //         border: Border.all(color: theme.colorScheme.primary),
              //         borderRadius: BorderRadius.circular(8),
              //       ),
              //     );
              //   }),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
