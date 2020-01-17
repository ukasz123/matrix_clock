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

import 'package:matrix_code_clock/face.dart';
import 'package:matrix_code_clock/matrix_code.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix_code_clock/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum _Element {
  background,
  text,
  shadow,
  codeTextColor,
  codeTextHighlightedColor,
}

final _darkTheme = {
  _Element.background: Color(0xFF080808),
  _Element.text: Colors.white,
  _Element.shadow: Color(0xFFA78EA6),
  _Element.codeTextColor: Colors.lightGreenAccent.shade400,
  _Element.codeTextHighlightedColor: Colors.lightGreenAccent.shade100,
};

final _webTheme = {
  _Element.background: Color(0xFF182818),
  _Element.text: Color.fromARGB(0xBB, 58, 237, 38),
  _Element.shadow: Color.fromARGB(0xBB, 50, 177, 50),
  _Element.codeTextColor: Colors.green.shade800,
  _Element.codeTextHighlightedColor: Colors.green.shade400,
};

class MatrixClock extends StatefulWidget {
  const MatrixClock(this.model);

  final ClockModel model;

  @override
  _MatrixClockState createState() => _MatrixClockState();
}

class _MatrixClockState extends State<MatrixClock> {
  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateModel();
  }

  @override
  void didUpdateWidget(MatrixClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = kIsWeb ? _webTheme : _darkTheme;

    return LayoutBuilder(builder: (c, constraints) {
      final fontSize = constraints.maxHeight * 4 / 7;
      final offset = fontSize / 12;
      final defaultStyle = TextStyle(
        color: colors[_Element.text],
        fontFamily: 'Miltown',
        fontSize: fontSize,
        shadows: [
          Shadow(
            offset: Offset(offset / 3, 0),
            blurRadius: offset / 6,
            color: colors[_Element.shadow],
          ),
          Shadow(
            blurRadius: offset / 2,
            color: colors[_Element.shadow].withOpacity(0.67),
          ),
        ],
      );
      return ListenableProvider<ClockModel>.value(
        value: widget.model,
        child: Container(
          color: colors[_Element.background],
          child: Stack(
            children: <Widget>[
              MatrixCodeWall(
                codeTextColor: colors[_Element.codeTextColor],
                codeTextHighlightedColor:
                    colors[_Element.codeTextHighlightedColor],
              ),
              ClockFaceMask(
                textStyle: defaultStyle,
                offset: offset,
              ),
            ],
          ),
        ),
      );
    });
  }
}
