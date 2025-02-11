import 'package:flutter/material.dart';

class BulletinPage extends StatelessWidget {
  const BulletinPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Page de bulletin',
        style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Inter Tight'),
      ),
    );
  }
}