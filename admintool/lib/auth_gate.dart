import 'package:admintool/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutterfire_ui/auth.dart';
import 'home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SignInScreen(              
                sideBuilder: (context, constraints) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Image(image: AssetImage('graphics/logo.png'))
                    ),
                  );
                },
                subtitleBuilder: (context, action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      action == AuthAction.signIn
                          ? 'Welcome to the KID Kooperation Indoor Navigation!'
                          : 'Welcome to the KID Kooperation Indoor Navigation!'
                    ),
                  );
                },
                providerConfigs: [EmailProviderConfiguration()]);
          }
          return HomeScreen(user: snapshot.data!);
        });
  }
}
