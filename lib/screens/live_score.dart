import 'package:flutter/material.dart';

class LiveScoreScreen extends StatelessWidget {
  const LiveScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Live Match Scores Here",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}