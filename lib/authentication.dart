import 'package:firedart/auth/firebase_auth.dart';
import 'package:firedart/firestore/firestore.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'homepage.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  var auth = FirebaseAuth.instance;

  bool _isSignIn = true;

  Future<void> _signIn() async {
    await auth
        .signIn(_emailController.text, _passwordController.text)
        .then((user) async {
      var document =
          await Firestore.instance.document("waiterAppLogins/${user.id}").get();

      Navigator.push(
        context,
        FluentPageRoute(
            builder: (context) =>
                Navigation(restaurantId: document['restaurantId'])),
      );
    });
  }

  Future<void> _signUp() async {
    await auth
        .signUp(_emailController.text, _passwordController.text)
        .then((user) {
      Firestore.instance.document("waiterAppLogins/${user.id}").set({
        "email": _emailController.text,
        "restaurantId": "",
      });

      Navigator.push(
        context,
        FluentPageRoute(
          builder: (context) => const AuthScreen(),
        ),
      );
    });
  }

  Future<void> _resetPassword() async {
    await auth.resetPassword(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      home: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSignIn ? 'Sign In' : 'Sign Up',
                    style: FluentTheme.of(context).typography.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    width: 400,
                    child: Column(
                      children: [
                        TextBox(
                          controller: _emailController,
                          placeholder: 'Email',
                        ),
                        const SizedBox(height: 16),
                        TextBox(
                          controller: _passwordController,
                          placeholder: 'Password',
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _isSignIn ? _signIn : _signUp,
                          child: Text(_isSignIn ? 'Sign In' : 'Sign Up'),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignIn = !_isSignIn;
                                });
                              },
                              child: Text(_isSignIn
                                  ? 'Don\'t have an account? Sign up'
                                  : 'Already have? Sign in'),
                            ),
                            TextButton(
                              onPressed: _resetPassword,
                              child: const Text(
                                  'Click to get password reset email!'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
