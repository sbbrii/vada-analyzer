import 'package:flutter/material.dart';
import 'package:vada_analyser/Presentation/home_screen.dart';

class ScreenSplash extends StatefulWidget {
  const ScreenSplash({super.key});

  @override
  State<ScreenSplash> createState() => _ScreenSplashState();
}

class _ScreenSplashState extends State<ScreenSplash> {
  @override
  void initState() {
    super.initState();
    waitSplash();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'വട?',
                  style: TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  // height: 250,
                  // width: 500,
                  child: Image(image: AssetImage('assets/Loading.gif')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  waitSplash() async {
    await Future.delayed(Duration(seconds: 4));
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => HomeScreen()));
  }
}
