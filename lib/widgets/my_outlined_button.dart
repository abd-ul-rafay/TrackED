import 'package:flutter/material.dart';
import '../utils/consts.dart';

class MyOutlinedButton extends StatelessWidget {
  final void Function()? onTap;
  final String text;
  const MyOutlinedButton({Key? key, this.onTap, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isDarkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDarkTheme? Colors.white10 : myColor,
          width: 1.5,
        ),
      ),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(text,
                  style: const TextStyle(fontSize: 16.0, color: myColor),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10.0,),
              const Padding(
                padding: EdgeInsets.only(right: 10.0),
                child: Icon(Icons.arrow_forward_rounded, color: myColor,),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
