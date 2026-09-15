import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  final VoidCallback onPlay;
  const MainMenu({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5DC1FF), Color(0xFF1E88E5)]),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('JUMP HERO 3D', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 8, color: Colors.black38)])),
            const SizedBox(height: 8),
            const Text('Mario-inspired • Original Hero', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onPlay,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              child: const Text('PLAY NOW'),
            ),
            const SizedBox(height: 16),
            const Text('WASD + SPACE • Joystick on Mobile', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}