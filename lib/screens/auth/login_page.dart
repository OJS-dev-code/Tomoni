import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      _showMessage('이메일을 입력해주세요.');
      return;
    }
    if (password.isEmpty) {
      _showMessage('비밀번호를 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signIn(email: email, password: password);

      final token = await AuthService.instance.getIdToken();
      Map<String, dynamic> profile = {};
      if (token != null) {
        profile = await ApiService.instance.getProfile(token);
        ApiService.instance.applyProfileToUserData(profile);
      }

      if (mounted) {
        final route = ApiService.instance.routeAfterAuth(profile);
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(firebaseAuthErrorMessage(error));
    } on ApiException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage('로그인에 실패했습니다. 다시 시도해주세요.');
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
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              "로그인",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildTextField("이메일", _emailController, false),
            const SizedBox(height: 20),
            _buildTextField("비밀번호", _passwordController, true),
            const SizedBox(height: 40),
            CustomButton(
              text: _isLoading ? "로그인 중..." : "로그인",
              onPressed: _isLoading ? null : _handleLogin,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('계정이 없으신가요?'),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pushNamed('/signup'),
                  child: const Text(
                    '회원가입',
                    style: TextStyle(
                      color: AppColors.deepYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isPassword,
  ) {
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
          obscureText: isPassword,
          enabled: !_isLoading,
          cursorColor: AppColors.darkGrey,
          decoration: InputDecoration(
            hintText: "$label 입력",
            filled: true,
            fillColor: Colors.white,
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
                color: AppColors.deepYellow,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
