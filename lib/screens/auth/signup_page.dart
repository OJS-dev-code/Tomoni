import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty) {
      _showMessage('이메일을 입력해주세요.');
      return;
    }

    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showMessage('올바른 이메일 형식이 아닙니다.');
      return;
    }

    if (password.isEmpty) {
      _showMessage('비밀번호를 입력해주세요.');
      return;
    }

    if (password.length < 6) {
      _showMessage('비밀번호는 6자 이상이어야 합니다.');
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage('비밀번호 확인을 입력해주세요.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signUp(email: email, password: password);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(firebaseAuthErrorMessage(error));
    } catch (_) {
      _showMessage('회원가입에 실패했습니다. 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Text(
              "회원가입",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "토모니와 함께 일본어 공부를 시작해 보세요!",
              style: TextStyle(fontSize: 16, color: AppColors.darkGrey),
            ),
            const SizedBox(height: 50),
            _buildTextField("이메일", _emailController, false),
            const SizedBox(height: 20),
            _buildTextField(
              "비밀번호",
              _passwordController,
              true,
              isVisible: _isPasswordVisible,
              toggleVisibility: () {
                setState(() => _isPasswordVisible = !_isPasswordVisible);
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "비밀번호 확인",
              _confirmPasswordController,
              true,
              isVisible: _isConfirmPasswordVisible,
              toggleVisibility: () {
                setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                );
              },
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: _isLoading ? "가입 중..." : "회원가입",
              onPressed: _isLoading ? null : _handleSignup,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isPassword, {
    bool isVisible = false,
    VoidCallback? toggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          cursorColor: AppColors.darkGrey,
          obscureText: isPassword ? !isVisible : false,
          enabled: !_isLoading,
          decoration: InputDecoration(
            hintText: "$label 입력",
            filled: true,
            fillColor: Colors.white,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: toggleVisibility,
                  )
                : null,
            hintStyle: const TextStyle(
              color: AppColors.lightGrey2,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
