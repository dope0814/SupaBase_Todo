import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_app/screens/main_app_page.dart';
import 'package:todo_app/screens/todo_list_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoginMode = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    KakaoSdk.init(nativeAppKey: dotenv.env['KAKAO_APP_KEY']);
  }

  Future<void> _authAction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        if (_isLoginMode) {
          await Supabase.instance.client.auth.signInWithPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        } else {
          await Supabase.instance.client.auth.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
        }
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const TodoListPage()),
          );
        }
      } on AuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An unexpected error occurrd.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  //Kakao Login
  Future<void> _signInWithKakao() async {
    setState(() {
      _isLoading = true;
    });

    try {
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      if (token.idToken == null) {
        throw const AuthException(
          'Kakao ID Token is null. Check Kakao Developer Center setting.',
        );
      }

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: token.idToken!,
        accessToken: token.accessToken,
      );

      if (mounted) {
        _navigateToMainAppPage();
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator:
                      (v) =>
                          (v == null || !v.contains('@'))
                              ? 'Please enter a valid email'
                              : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator:
                      (v) =>
                          (v == null || v.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _authAction,
                      child: Text(_isLoginMode ? 'Login' : 'Sing Up'),
                    ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _signInWithKakao,
                  label: const Text(''),
                  icon: Image.asset(
                    'lib/assets/kakao_login.png',
                    // height: 24,
                    // width: 24,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed:
                      () => {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        }),
                      },
                  child: Text(
                    _isLoginMode
                        ? 'Create an account'
                        : 'I already have an account.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToMainAppPage() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainAppPage()));
  }
}
