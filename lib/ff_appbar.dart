import 'package:flutter/material.dart';

class FFAppBar extends StatelessWidget implements PreferredSizeWidget {
  final title;

  const FFAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      leading: IconButton(
        icon: Image.asset('images/FFLogo.png'),
        onPressed: () => {Navigator.pushNamed(context, '/home')},
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}