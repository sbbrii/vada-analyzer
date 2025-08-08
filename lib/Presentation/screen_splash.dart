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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: 
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              SizedBox(
                //height: 100,width: 50,
                child: Image(image: AssetImage('assets/Loading.gif'))
                ),
              Text('Loading..',style: TextStyle(fontSize: 20),)
            ],
          )
        ),
      ),
    );
  }

  waitSplash() async {
    await Future.delayed(Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomeScreen()));
  }
}