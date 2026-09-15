# Jump Hero 3D - Production Ready 3D Platformer

Original 3D Mario-inspired platformer built in Flutter + Flame.

## Run
```
flutter pub get
flutter run -d chrome
flutter run
```

## Features
- 60FPS custom 3D projection engine (no heavy native 3D dep needed to run)
- Third-person follow camera with smooth lerp
- Double jump, coyote time (0.15s), jump buffer, ground pound
- Moving platforms, patrol enemies, rotating coins
- Joystick + A/B buttons on mobile, WASD + Space + Shift on desktop
- Pause, Game Over, Level Complete
- Original character - uses primitives, ready to swap .glb into assets/models/hero.glb and it will auto-use flutter_3d_controller if present

## Swap 3D Model
Drop your low-poly hero.glb into assets/models/hero.glb and set use3DModel=true in constants.dart