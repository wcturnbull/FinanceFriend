import 'package:flutter/material.dart';

class FFAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FFAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Image.asset('assets/images/FFLogo.png',
          height:100, 
          width: 100),
        centerTitle: true,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}