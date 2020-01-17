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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:matrix_code_clock/model.dart';

class ClockFaceMask extends StatelessWidget {
  const ClockFaceMask({
    Key key,
    @required this.textStyle,
    @required this.offset,
  }) : super(key: key);

  final TextStyle textStyle;
  final double offset;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _ClockFace(
        textStyle: textStyle,
      );
    } else {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(Color(0x90000000), BlendMode.srcOut),
        child: _ClockFace(
          textStyle: textStyle,
        ),
      );
    }
  }
}

class _ClockFace extends StatefulWidget {
  const _ClockFace({
    Key key,
    @required this.textStyle,
  }) : super(key: key);

  final TextStyle textStyle;

  @override
  _ClockFaceState createState() => _ClockFaceState();
}

class _ClockFaceState extends State<_ClockFace> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute.
      _timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateFormat(
            Provider.of<ClockModel>(context).is24HourFormat ? 'HH' : 'hh')
        .format(_dateTime);
    final minute = DateFormat('mm').format(_dateTime);
    return Container(
      constraints: BoxConstraints.expand(),
      alignment: Alignment.center,
      color: Color(0x01000000),
      child: DefaultTextStyle(
        style: widget.textStyle,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Flexible(child: Text(hour), flex: 1),
            Text(':'),
            Flexible(child: Text(minute), flex: 1),
          ],
        ),
      ),
      // ),
    );
  }
}