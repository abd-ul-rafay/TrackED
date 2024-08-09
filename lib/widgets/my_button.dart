import 'package:tracked/utils/consts.dart';
import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final void Function()? onTap;
  final Widget widget;
  const MyButton({Key? key, required this.onTap, required this.widget,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var darkTheme = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return ElevatedButton(
      style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(7.5),
            side: darkTheme? const BorderSide(color: Colors.white38) : BorderSide.none,
          ),
        ),
        foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
        backgroundColor: darkTheme? MaterialStateProperty.all<Color>(Theme.of(context).scaffoldBackgroundColor)
            : MaterialStateProperty.all<Color>(myColor),
        overlayColor: MaterialStateProperty.all<Color>(myColorWithOpacity),
      ),
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
            child: widget,
        ),
      ),
    );
  }
}
