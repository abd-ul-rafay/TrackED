import 'package:tracked/widgets/my_button.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../utils/consts.dart';
import '../../services/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  Widget buttonWidget = const Center(child: Text('Login', style: TextStyle(color: Colors.white, fontSize: 18.0,),),);

  void login() async {
    var pin = _pinController.text.trim().toString();
    if (pin.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete the pin')));
      return;
    }

    setState(() {
      buttonWidget = const CircularProgressIndicator(color: Colors.white,);
    });

    Auth().signin(pin, context, () {
      setState(() {
        buttonWidget = const Center(child: Text('Login', style: TextStyle(color: Colors.white, fontSize: 18.0, ),),);
      });
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hello, Welcome Back!',),
      ),
      body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 5.0,),
                    const Text('PLEASE ENTER YOUR PIN CODE',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30.0,),
                    Container(
                      width: 500.0,
                      padding: const EdgeInsets.symmetric(horizontal: 20.0,),
                      child: PinCodeTextField(
                        keyboardType: TextInputType.number,
                        appContext: context,
                        length: 6,
                        onChanged: (String value) {  },
                        controller: _pinController,
                        cursorColor: myColor,
                        animationType: AnimationType.scale,
                        // enableActiveFill: true,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          inactiveColor: Colors.grey,
                          selectedColor: myColor,
                          selectedFillColor: myColor,
                          inactiveFillColor: Colors.white,
                          activeColor: (MediaQuery.of(context).platformBrightness == Brightness.light)? Colors.green : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0,),
                    MyButton(
                      widget: buttonWidget,
                      onTap: login,
                    ),
                    const SizedBox(height: 20.0)
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
