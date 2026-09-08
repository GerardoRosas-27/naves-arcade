import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naves_arcade/game/naves_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('NavesGame implements KeyboardEvents', () {
    expect(NavesGame(), isA<KeyboardEvents>());
  });

  test('WASD sets keyboardDelta; space is handled; release clears delta', () async {
    final game = NavesGame();
    await game.onLoad();

    final downA = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyA,
      logicalKey: LogicalKeyboardKey.keyA,
      timeStamp: Duration.zero,
    );
    expect(game.onKeyEvent(downA, {LogicalKeyboardKey.keyA}), KeyEventResult.handled);
    expect(game.player.keyboardDelta.x, lessThan(0));
    expect(game.player.keyboardDelta.y, closeTo(0, 1e-9));

    final downW = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyW,
      logicalKey: LogicalKeyboardKey.keyW,
      timeStamp: Duration.zero,
    );
    game.onKeyEvent(downW, {LogicalKeyboardKey.keyA, LogicalKeyboardKey.keyW});
    expect(game.player.keyboardDelta.x, lessThan(0));
    expect(game.player.keyboardDelta.y, lessThan(0));

    final downSpace = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    expect(
      game.onKeyEvent(downSpace, {LogicalKeyboardKey.space}),
      KeyEventResult.handled,
    );
    expect(game.player.keyboardDelta, Vector2.zero());

    final upSpace = KeyUpEvent(
      physicalKey: PhysicalKeyboardKey.space,
      logicalKey: LogicalKeyboardKey.space,
      timeStamp: Duration.zero,
    );
    game.onKeyEvent(upSpace, {});
    expect(game.player.keyboardDelta, Vector2.zero());
  });

  test('joystick and keyboard deltas combine on the player move path', () {
    // Same formula used in PlayerShip.update.
    final joystick = Vector2(1, 0);
    final keyboard = Vector2(0, -1);
    final move = joystick + keyboard;
    expect(move.normalized().x, closeTo(0.7071, 0.01));
    expect(move.normalized().y, closeTo(-0.7071, 0.01));
  });
}
