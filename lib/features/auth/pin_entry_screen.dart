import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kvman/features/auth/auth_notifier.dart';
import 'package:kvman/features/auth/auth_repository.dart';
import 'package:pinput/pinput.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key, required this.phoneNumber});
  final String phoneNumber;

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  static const int otpLength = 6;

  final TextEditingController pinController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  bool _isLoading = false;

  String get _maskedPhone {
    final phone = widget.phoneNumber;
    if (phone.length >= 10) {
      return '${phone.substring(0, 2)}******${phone.substring(phone.length - 2)}';
    }
    return phone;
  }

  @override
  void dispose() {
    pinController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(String pin) async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final token = await authRepo.verifyOtp(
        mobileNumber: widget.phoneNumber,
        otp: pin,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setInt(
        'token_generated_time',
        DateTime.now().millisecondsSinceEpoch.toInt(),
      );
      final users = await authRepo.fetchUsersList(widget.phoneNumber);
      if (users.isEmpty) {
        await prefs.remove('auth_token'); // Rollback token
        throw const AuthException('No accounts found for this number.');
      }

      if (!mounted) return;

      await ref
          .read(authNotifierProvider.notifier)
          .login(token: token, phoneNumber: widget.phoneNumber, users: users);
      // Router redirect will automatically navigate to home
    } on AuthException catch (e) {
      if (!mounted) return;
      pinController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      pinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
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

              Pinput(
                length: otpLength,
                controller: pinController,
                focusNode: focusNode,
                autofocus: true,
                enabled: !_isLoading,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onCompleted: _verifyOtp,
                hapticFeedbackType: HapticFeedbackType.lightImpact,
                defaultPinTheme: PinTheme(
                  width: 46,
                  height: 56,
                  textStyle: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outline),
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
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              if (_isLoading) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
