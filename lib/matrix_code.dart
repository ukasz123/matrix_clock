// Copyright 2020 Łukasz Huculak
//
//    Licensed under the Apache License, Version 2.0 (the "License");
//    you may not use this file except in compliance with the License.
//    You may obtain a copy of the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in writing, software
//    distributed under the License is distributed on an "AS IS" BASIS,
//    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//    See the License for the specific language governing permissions and
//    limitations under the License.

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';

const double _FONT_SIZE_FRACTION = 0.95;
const double _FALLING_CODE_ANIMATION_SPEED = 0.23;
const double _FALL_STEP_PARTIAL = 1 / 3;
const double _ANIMATION_STEP_DELTA =
    _FALLING_CODE_ANIMATION_SPEED * _FALL_STEP_PARTIAL;
const double _NEXT_FALL_DELAY = _FALLING_CODE_ANIMATION_SPEED * 4;
const double _PRINTING_CODE_DELAY = _FALLING_CODE_ANIMATION_SPEED * 1 / 3;

const double _NEXT_FALL_STARTING_PROBABILITY = 0.02;

const int _NUMBER_OF_ROWS = 30;

final _availableSigns = [
  ...List.generate(24, (i) => String.fromCharCode(97 + i)), // a-z
  ...List.generate(24, (i) => String.fromCharCode(65 + i)), // A-Z
  ...List.generate(10, (i) => String.fromCharCode(49 + i)), // 0-9
  '\$',
  '+',
  '-',
  '*',
  '/',
  '=',
  '#',
  '&',
  '(', ')',
  '{', '}',
  '[', ']',
  '~',
  '\\',
  '|',
  ',', '.', ';', ':',
  '?',
  '!',
];
String randomSign() => _availableSigns[randomInt(_availableSigns.length)];

class MatrixCodeWall extends StatelessWidget {
  final Color codeTextColor;
  final Color codeTextHighlightedColor;
  const MatrixCodeWall({
    Key key,
    this.codeTextColor,
    this.codeTextHighlightedColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: _wallBuilder,
    );
  }

  Widget _wallBuilder(BuildContext context, BoxConstraints constraints) {
    var numberOfRows = _NUMBER_OF_ROWS;
    var signCubeSize = (constraints.biggest.height / numberOfRows);
    var numberOfColumns = (constraints.maxWidth / signCubeSize).ceil();
    return ClipRect(
      child: SpriteWidget(_MatrixCodeRoot(
          size: constraints.biggest,
          rows: numberOfRows,
          columns: numberOfColumns,
          cubeSize: signCubeSize,
          textColor: codeTextColor,
          printingTextColor: codeTextHighlightedColor)),
    );
  }
}

class _MatrixCodeRoot extends NodeWithSize {
  final int rows;
  final int columns;
  final double cubeSize;

  List<_CodeColumn> _codeColumns;

  _MatrixCodeRoot({
    @required Size size,
    @required this.rows,
    @required this.columns,
    @required this.cubeSize,
    @required Color textColor,
    @required Color printingTextColor,
  }) : super(size) {
    _codeColumns = List.generate(
      columns,
      (_) => _CodeColumn(
        rows: rows,
        size: Size(cubeSize, size.height),
        cubeSize: cubeSize,
        textColor: textColor,
        printingTextColor: printingTextColor,
      ),
    );
    for (int i = 0; i < columns; i++) {
      addChild(_codeColumns[i]..position = Offset(cubeSize * (1 / 3 + i), 0));
    }
  }
}

class _CodeColumn extends NodeWithSize {
  final int rows;
  final double cubeSize;
  final Size codeSize;
  final double columnHeight;
  final Color textColor;
  final Color printingTextColor;

  _CodeColumn({
    @required this.rows,
    @required this.cubeSize,
    Size size,
    this.textColor,
    this.printingTextColor,
  })  : codeSize = Size(cubeSize, cubeSize),
        columnHeight = rows * cubeSize,
        super(size) {
    _generateFallingCode();
  }

  // animation variables
  double timeSum;
  bool fallingAnimationRunning = false;
  NodeWithSize emptySpace;
  List<_CodeCharacter> codeColumn;
  _PrintingCodeCharacter printingCodeCharacter;
  List<_CodeCharacter> previousCodeColumn;

  @override
  void update(double dt) {
    super.update(dt);
    if (timeSum == null) {
      _resetTimeSum();
      fallingAnimationRunning = true;
      return;
    }

    timeSum += dt;
    if (fallingAnimationRunning) {
      if (timeSum >= _ANIMATION_STEP_DELTA) {
        children.forEach((node) {
          node.position = Offset(node.position.dx,
              node.position.dy + cubeSize * _FALL_STEP_PARTIAL);
        });
        timeSum = 0;
        if (printingCodeCharacter.position.dy >= columnHeight) {
          fallingAnimationRunning = false;
          if (previousCodeColumn != null) {
            previousCodeColumn.forEach((code) {
              removeChild(code);
            });
          }
          previousCodeColumn = codeColumn;
          removeChild(emptySpace);
          removeChild(printingCodeCharacter);
        }
      }
    } else {
      if (timeSum > _NEXT_FALL_DELAY) {
        if (randomDouble() < _NEXT_FALL_STARTING_PROBABILITY) {
          _generateFallingCode();
          fallingAnimationRunning = true;
        }
        _resetTimeSum();
      }
    }
  }

  void _generateFallingCode() {
    emptySpace = NodeWithSize(
        Size(cubeSize, cubeSize * (randomInt((rows * 0.25).ceil())+1)));
    printingCodeCharacter = _PrintingCodeCharacter(
      codeSize,
      printingTextColor,
    );
    codeColumn = List.generate(
        rows,
        (i) => _CodeCharacter(
              codeSize,
              textColor,
            )..position = Offset(0, -(i + 1) * cubeSize));

    emptySpace.position = Offset(0, -emptySpace.size.height);
    printingCodeCharacter.position =
        Offset(0, -cubeSize - emptySpace.size.height);
    codeColumn.forEach((c) => c
      ..position = Offset(
          c.position.dx, c.position.dy - cubeSize - emptySpace.size.height));

    addChild(emptySpace);
    addChild(printingCodeCharacter);
    codeColumn.forEach((c) => addChild(c));
  }

  void _resetTimeSum() {
    timeSum = randomDouble() * _ANIMATION_STEP_DELTA * 3 / 4;
  }
}

class _CodeCharacter extends NodeWithSize {
  final String text;
  TextStyle style;

  _CodeCharacter(Size size, Color color, {this.text})
      : style = TextStyle(
          fontSize: size.height * _FONT_SIZE_FRACTION,
          fontFamily: 'MatrixCode',
          fontWeight: FontWeight.normal,
          // letterSpacing: widget.cubeSize * 0.2,
          color: color,
        ),
        super(size) {
    addChild(Label(text ?? randomSign(),
        textStyle: style, textAlign: TextAlign.center));
  }
}

class _PrintingCodeCharacter extends _CodeCharacter {
  Label label;

  double updateTime;

  _PrintingCodeCharacter(
    Size size,
    Color color,
  ) : super(
          size,
          color,
        ) {
    style = style.copyWith(
      fontWeight: FontWeight.bold,
    );
    label = Label(randomSign(), textStyle: style, textAlign: TextAlign.center);
    updateTime = 0.0;
    addChild(label);
  }

  void update(double dt) {
    updateTime += dt;
    if (updateTime >= _PRINTING_CODE_DELAY) {
      label.text = randomSign();
      updateTime = 0.0;
    }
  }
}
