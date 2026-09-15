import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';
import '../game/platform.dart';
import '../game/enemy.dart';
import '../game/coin.dart';

class LevelData {
  List<Platform> platforms = [];
  List<Pipe> pipes = [];
  List<Enemy> enemies = [];
  List<Coin> coins = [];
  FinishFlag finishFlag;

  LevelData({required this.finishFlag});

  static Future<LevelData> loadFromJson(String path) async {
    try {
      final jsonStr = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(jsonStr);
      return _parse(data);
    } catch (e) {
      // Fallback to hardcoded level
      return _parse(_defaultLevel);
    }
  }

  static LevelData _parse(List<dynamic> data) {
    final platforms = <Platform>[];
    final pipes = <Pipe>[];
    final enemies = <Enemy>[];
    final coins = <Coin>[];
    FinishFlag finish = FinishFlag(position: Vector3(22, 1, 0));

    for (final obj in data) {
      final type = obj['type'];
      final posList = obj['pos'] as List;
      final pos = Vector3(posList[0].toDouble(), posList[1].toDouble(), posList[2].toDouble());

      if (type == 'platform') {
        final sizeList = obj['size'] as List;
        final size = Vector3(sizeList[0].toDouble(), sizeList[1].toDouble(), sizeList[2].toDouble());
        final moving = obj['moving'] == true;
        Vector3? from, to;
        if (moving) {
          final f = obj['from'] as List;
          final t = obj['to'] as List;
          from = Vector3(f[0].toDouble(), f[1].toDouble(), f[2].toDouble());
          to = Vector3(t[0].toDouble(), t[1].toDouble(), t[2].toDouble());
        }
        platforms.add(Platform(position: pos, size: size, isMoving: moving, from: from, to: to));
      } else if (type == 'pipe') {
        pipes.add(Pipe(position: pos));
      } else if (type == 'enemy') {
        final patrol = obj['patrol'] as List;
        enemies.add(Enemy(position: pos, patrolMinX: patrol[0].toDouble(), patrolMaxX: patrol[1].toDouble()));
      } else if (type == 'coin') {
        coins.add(Coin(position: pos));
      } else if (type == 'finish') {
        finish = FinishFlag(position: pos);
      }
    }

    // Ensure ground
    if (platforms.isEmpty) {
      platforms.add(Platform(position: Vector3(0, 0, 0), size: Vector3(20, 1, 10)));
    }

    final level = LevelData(finishFlag: finish);
    level.platforms = platforms;
    level.pipes = pipes;
    level.enemies = enemies;
    level.coins = coins;
    return level;
  }

  static const List<Map<String, dynamic>> _defaultLevel = [
    {"type": "platform", "pos": [0, 0, 0], "size": [20, 1, 14]},
    {"type": "platform", "pos": [10, 2, 3], "size": [6, 1, 5]},
    {"type": "platform", "pos": [18, 4, 0], "size": [6, 1, 6], "moving": true, "from": [18, 4, -3], "to": [18, 4, 5]},
    {"type": "platform", "pos": [26, 2, 2], "size": [8, 1, 8]},
    {"type": "platform", "pos": [36, 0, 0], "size": [16, 1, 12]},
    {"type": "pipe", "pos": [14, 0, 2]},
    {"type": "pipe", "pos": [30, 0, -2]},
    {"type": "enemy", "pos": [5, 1, 0], "patrol": [2, 8]},
    {"type": "enemy", "pos": [26, 3, 2], "patrol": [24, 30]},
    {"type": "coin", "pos": [0, 2, 0]},
    {"type": "coin", "pos": [10, 3.5, 3]},
    {"type": "coin", "pos": [11, 3.5, 3]},
    {"type": "coin", "pos": [18, 5.5, 0]},
    {"type": "coin", "pos": [26, 3.5, 2]},
    {"type": "coin", "pos": [27, 3.5, 2]},
    {"type": "coin", "pos": [36, 2, 0]},
    {"type": "coin", "pos": [37, 2, 1]},
    {"type": "coin", "pos": [38, 2, 0]},
    {"type": "coin", "pos": [39, 2, -1]},
    {"type": "finish", "pos": [42, 1, 0]},
  ];
}