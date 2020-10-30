import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class WavePainter extends CustomPainter {
  double frequency = 880;
  double amplitude = 1;
  double offset = 0;
  WaveType waveType = WaveType.sine;
  bool outputting = true;
  var buffer = [];

  WavePainter(this.frequency, this.amplitude, this.offset, this.waveType,
      this.outputting, this.buffer);

  @override
  void paint(Canvas canvas, Size size) {
    var wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = Colors.blue
      ..isAntiAlias = true;

    var pointPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.25
      ..color = Colors.red
      ..isAntiAlias = true;

    var axisPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 0.5
      ..color = Colors.white
      ..isAntiAlias = true;

    Path wavePath = new Path();
    wavePath.moveTo(0, size.height / 2);

    Path fromNativePath = new Path();
    fromNativePath.moveTo(0, size.height / 2);

    int scale = pow(10, log(frequency) ~/ log(10));
    double graphWidth = (size.width - (size.width / 4));
    double graphOffset = (size.width / 10);

    int resolution = 144;

    /*
    // Code used for viewing the actually buffer output to the aux (only usable if you have filled the local buffer)
    if (buffer != null) {
      var stepSize = (1);
      if (outputting) debugPrint("stepSize: " + stepSize.toString());
      for (int i = 0; i < resolution; i++) {
        var x = i * size.width / resolution;
        var y = size.height / 2 +
            35 * buffer[(i * stepSize) % buffer.length] / 32767;
        fromNativePath.lineTo(x, y);
        canvas.drawCircle(Offset(x, y), 1, pointPaint);
      }
    }*/

    wavePath.moveTo(graphOffset, size.height / 2);
    if (outputting) {
      for (int i = 0; i < resolution; i++) {
        var y;
        var x = graphOffset + i * graphWidth / resolution;
        switch (this.waveType) {
          case WaveType.sine:
            y = amplitude *
                sin(((2 * pi * i * frequency / (scale * resolution)) -
                    (2 * pi * offset)));
            break;

          case WaveType.square:
            y = amplitude *
                sin(((2 * pi * i * frequency / (scale * resolution)) -
                    (2 * pi * offset)));
            y = y.sign;
            break;

          case WaveType.triangle:
            y = (amplitude * 2 / pi) *
                asin(sin(((2 * pi * i * frequency / (scale * resolution)) -
                    (2 * pi * offset))));
            break;

          default:
            y = 0;
        }
        wavePath.lineTo(x, size.height / 2 + size.height / 4 * y);
        //canvas.drawCircle(
        //Offset(x, size.height / 2 + size.height / 4 * y), 1, pointPaint);
      }
    }

    var formattedWaveType = waveType
            .toString()
            .substring(waveType.toString().indexOf(".") + 1,
                waveType.toString().indexOf(".") + 2)
            .toUpperCase() +
        waveType.toString().substring(waveType.toString().indexOf(".") + 2);

    var waveSettingsText;

    if (outputting)
      waveSettingsText = "Wave Type: " +
          formattedWaveType +
          " | Frequency: " +
          frequency.round().toString() +
          " Hz | Amplitude: " +
          amplitude.toString() +
          " | Offset: " +
          offset.toString() +
          "\nScale: " +
          scale.toString();
    else
      waveSettingsText = "This channel is not switched on!";

    // Axis lines
    canvas.drawLine(Offset(graphOffset, size.height / 2),
        Offset(graphOffset + graphWidth, size.height / 2), axisPaint);
    canvas.drawLine(Offset(graphOffset, (size.height / 2) + size.height / 4),
        Offset(graphOffset, (size.height / 2) - size.height / 4), axisPaint);

    TextSpan span = new TextSpan(
        style: new TextStyle(
            color: Colors.white, fontSize: 10.0, fontFamily: 'Roboto'),
        text: waveSettingsText);

    TextPainter tp =
        new TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(0.0, 0.0));

    canvas.drawPath(wavePath, wavePaint);
    canvas.drawPath(fromNativePath, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class CombinedWavePainter extends CustomPainter {
  double leftFrequency = 880;
  double leftAmplitude = 1;
  double leftOffset = 0;
  WaveType leftWaveType = WaveType.sine;
  bool leftOutputting = true;
  var leftBuffer = [];

  double rightFrequency = 880;
  double rightAmplitude = 1;
  double rightOffset = 0;
  WaveType rightWaveType = WaveType.sine;
  bool rightOutputting = true;
  var rightBuffer = [];

  CombinedWavePainter(
      this.leftFrequency,
      this.leftAmplitude,
      this.leftOffset,
      this.leftWaveType,
      this.leftOutputting,
      this.leftBuffer,
      this.rightFrequency,
      this.rightAmplitude,
      this.rightOffset,
      this.rightWaveType,
      this.rightOutputting,
      this.rightBuffer);

  @override
  void paint(Canvas canvas, Size size) {
    var leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = Colors.blue
      ..isAntiAlias = true;

    var rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.75
      ..color = Colors.red
      ..isAntiAlias = true;

    var axisPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 0.5
      ..color = Colors.white
      ..isAntiAlias = true;

    int leftScale = pow(10, log(leftFrequency) ~/ log(10));
    int rightScale = pow(10, log(rightFrequency) ~/ log(10));
    int averageScale = (leftScale + rightScale) ~/ 2;

    double graphWidth = (size.width - (size.width / 4));
    double graphOffset = (size.width / 10);

    int resolution = 144;

    Path leftPath = new Path();
    leftPath.moveTo(graphOffset, size.height / 2);

    Path rightPath = new Path();
    rightPath.moveTo(graphOffset, size.height / 2);

    if (leftOutputting) {
      for (int i = 0; i < resolution; i++) {
        var y;
        var x = graphOffset + i * graphWidth / resolution;
        switch (this.leftWaveType) {
          case WaveType.sine:
            y = leftAmplitude *
                sin(((2 *
                        pi *
                        i *
                        leftFrequency /
                        (averageScale * resolution)) -
                    (2 * pi * leftOffset)));
            break;

          case WaveType.square:
            y = leftAmplitude *
                sin(((2 *
                        pi *
                        i *
                        leftFrequency /
                        (averageScale * resolution)) -
                    (2 * pi * leftOffset)));
            y = y.sign;
            break;

          case WaveType.triangle:
            y = (leftAmplitude * 2 / pi) *
                asin(sin(((2 *
                        pi *
                        i *
                        leftFrequency /
                        (averageScale * resolution)) -
                    (2 * pi * leftOffset))));
            break;

          default:
            y = 0;
        }
        leftPath.lineTo(x, size.height / 2 + size.height / 4 * y);
      }
    }

    if (rightOutputting) {
      for (int i = 0; i < resolution; i++) {
        var y;
        var x = graphOffset + i * graphWidth / resolution;
        switch (this.rightWaveType) {
          case WaveType.sine:
            y = rightAmplitude *
                sin(((2 *
                        pi *
                        i *
                        rightFrequency /
                        (averageScale * resolution)) -
                    (2 * pi * rightOffset)));
            break;

          case WaveType.square:
            y = rightAmplitude *
                sin(((2 *
                        pi *
                        i *
                        rightFrequency /
                        (averageScale * resolution)) -
                    (2 * pi * rightOffset)));
            y = y.sign;
            break;

          case WaveType.triangle:
            y = (rightAmplitude * 2 / pi) *
                asin(sin(((2 *
                        pi *
                        i *
                        rightFrequency /
                        (averageScale * resolution)) -
                    (2 * pi * rightOffset))));
            break;

          default:
            y = 0;
        }
        rightPath.lineTo(x, size.height / 2 + size.height / 4 * y);
      }
    }

    var formattedWaveType = leftWaveType
            .toString()
            .substring(leftWaveType.toString().indexOf(".") + 1,
                leftWaveType.toString().indexOf(".") + 2)
            .toUpperCase() +
        leftWaveType
            .toString()
            .substring(leftWaveType.toString().indexOf(".") + 2);

    var waveSettingsText;

    if (leftOutputting)
      waveSettingsText = "Wave Type: " +
          formattedWaveType +
          " | Frequency: " +
          leftFrequency.round().toString() +
          " Hz | Amplitude: " +
          leftAmplitude.toString() +
          " | Offset: " +
          leftOffset.toString() +
          "\nScale: " +
          leftScale.toString();
    else
      waveSettingsText = "This channel is not switched on!";

    // Axis lines
    canvas.drawLine(Offset(graphOffset, size.height / 2),
        Offset(graphOffset + graphWidth, size.height / 2), axisPaint);
    canvas.drawLine(Offset(graphOffset, (size.height / 2) + size.height / 4),
        Offset(graphOffset, (size.height / 2) - size.height / 4), axisPaint);

    TextSpan span = new TextSpan(
        style: new TextStyle(
            color: Colors.white, fontSize: 10.0, fontFamily: 'Roboto'),
        text: waveSettingsText);

    TextPainter tp =
        new TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(0.0, 0.0));

    canvas.drawPath(leftPath, leftPaint);
    canvas.drawPath(rightPath, rightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

enum WaveType { sine, square, triangle }

class _MyHomePageState extends State<MyHomePage> {
  static const platform =
      const MethodChannel('GDP18Androidtest.example.com/oscilloscope');

  // =======================
  // Left channel settings
  // =======================
  double _currentLeftFrequencyValue = 880;
  double _currentLeftAmplitudeValue = 1;
  double _currentLeftOffsetValue = 0;
  WaveType _currentLeftWaveType = WaveType.sine;
  bool _currentLeftStatus = true;
  var _leftBuffer = [];

  // =======================
  // Right channel settings
  // =======================

  double _currentRightFrequencyValue = 440;
  double _currentRightAmplitudeValue = 1;
  double _currentRightOffsetValue = 0;
  WaveType _currentRightWaveType = WaveType.sine;
  bool _currentRightStatus = true;
  var _rightBuffer = [];

  // =======================
  // General playback functions
  // =======================

  Future<void> _playSound() async {
    try {
      await platform.invokeMethod("playSound");
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }
  }

  Future<void> _pauseSound() async {
    try {
      await platform.invokeMethod("pauseSound");
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }
  }

  // =======================
  // Left Channel Functions
  // =======================

  void _onLeftAmplitudeChange(double value) async {
    try {
      await platform
          .invokeMethod('updateAmplitude', {"value": value, "left": true});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentLeftAmplitudeValue = value;
    });
  }

  void _onLeftFrequencyChange(double value) async {
    try {
      await platform
          .invokeMethod('updateFrequency', {"value": value, "left": true});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentLeftFrequencyValue = value;
    });
  }

  void _onLeftRadioWaveTypeChanged(WaveType value) async {
    var buffer;
    String waveTypeInString =
        value.toString().substring(value.toString().indexOf(".") + 1);

    try {
      buffer = await platform.invokeMethod(
          "updateType", {"value": waveTypeInString, "left": true});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentLeftWaveType = value;
      _leftBuffer = buffer;
    });
  }

  void _onLeftStatusChanged(bool value) async {
    var buffer;
    try {
      buffer = await platform
          .invokeMethod('updateChannelSwitch', {"value": value, "left": true});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentLeftStatus = value;
      _leftBuffer = buffer;
    });
  }

  void _onLeftOffsetChange(double value) async {
    try {
      await platform
          .invokeMethod('updateOffset', {"value": value, "left": true});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentLeftOffsetValue = value;
    });
  }

  void _updateLeftChannel(double value) async {
    var buffer;
    try {
      buffer = await platform.invokeMethod('updateChannel', {"left": true});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _leftBuffer = buffer;
    });
  }

  // =======================
  // Right Channel Functions
  // =======================

  void _onRightAmplitudeChange(double value) async {
    try {
      await platform
          .invokeMethod('updateAmplitude', {"value": value, "left": false});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentRightAmplitudeValue = value;
    });
  }

  void _onRightFrequencyChange(double value) async {
    try {
      await platform
          .invokeMethod('updateFrequency', {"value": value, "left": false});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentRightFrequencyValue = value;
    });
  }

  void _onRightStatusChanged(bool value) async {
    var buffer;
    try {
      buffer = await platform
          .invokeMethod('updateChannelSwitch', {"value": value, "left": false});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentRightStatus = value;
      _rightBuffer = buffer;
    });
  }

  void _onRightRadioWaveTypeChanged(WaveType value) async {
    var buffer;
    String waveTypeInString =
        value.toString().substring(value.toString().indexOf(".") + 1);

    try {
      buffer = await platform.invokeMethod(
          "updateType", {"value": waveTypeInString, "left": false});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentRightWaveType = value;
      _rightBuffer = buffer;
    });
  }

  void _onRightOffsetChange(double value) async {
    try {
      await platform
          .invokeMethod('updateOffset', {"value": value, "left": false});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _currentRightOffsetValue = value;
    });
  }

  void _updateRightChannel(double value) async {
    var buffer;
    try {
      buffer = await platform.invokeMethod('updateChannel', {"left": false});
    } on PlatformException catch (e) {
      debugPrint(e.message);
    }

    setState(() {
      _rightBuffer = buffer;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: LayoutBuilder(
                builder: (_, constraints) => Container(
                  width: constraints.widthConstraints().maxWidth,
                  height: 100,
                  color: Colors.black,
                  child: CustomPaint(
                    painter: WavePainter(
                        _currentLeftFrequencyValue,
                        _currentLeftAmplitudeValue,
                        _currentLeftOffsetValue,
                        _currentLeftWaveType,
                        _currentLeftStatus,
                        _leftBuffer),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: LayoutBuilder(
                builder: (_, constraints) => Container(
                  width: constraints.widthConstraints().maxWidth,
                  height: 100,
                  color: Colors.black,
                  child: CustomPaint(
                    painter: WavePainter(
                        _currentRightFrequencyValue,
                        _currentRightAmplitudeValue,
                        _currentRightOffsetValue,
                        _currentRightWaveType,
                        _currentRightStatus,
                        _rightBuffer),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: LayoutBuilder(
                builder: (_, constraints) => Container(
                  width: constraints.widthConstraints().maxWidth,
                  height: 100,
                  color: Colors.black,
                  child: CustomPaint(
                    painter: CombinedWavePainter(
                        _currentLeftFrequencyValue,
                        _currentLeftAmplitudeValue,
                        _currentLeftOffsetValue,
                        _currentLeftWaveType,
                        _currentLeftStatus,
                        _leftBuffer,
                        _currentRightFrequencyValue,
                        _currentRightAmplitudeValue,
                        _currentRightOffsetValue,
                        _currentRightWaveType,
                        _currentRightStatus,
                        _rightBuffer),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Left Frequency:"),
                Slider(
                  value: _currentLeftFrequencyValue,
                  onChanged: _onLeftFrequencyChange,
                  min: 20,
                  max: 5050,
                  divisions: 503,
                  label: _currentLeftFrequencyValue.round().toString(),
                  onChangeEnd: _updateLeftChannel,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Right Frequency:"),
                Slider(
                  value: _currentRightFrequencyValue,
                  onChanged: _onRightFrequencyChange,
                  min: 20,
                  max: 5050,
                  divisions: 503,
                  label: _currentRightFrequencyValue.round().toString(),
                  onChangeEnd: _updateRightChannel,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Left Amplitude:"),
                Slider(
                  value: _currentLeftAmplitudeValue,
                  onChanged: _onLeftAmplitudeChange,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: _currentLeftAmplitudeValue.round().toString(),
                  onChangeEnd: _updateLeftChannel,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Right Amplitude:"),
                Slider(
                  value: _currentRightAmplitudeValue,
                  onChanged: _onRightAmplitudeChange,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: _currentRightAmplitudeValue.round().toString(),
                  onChangeEnd: _updateRightChannel,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Left Phase Offset:"),
                Slider(
                  value: _currentLeftOffsetValue,
                  onChanged: _onLeftOffsetChange,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: _currentLeftOffsetValue.round().toString(),
                  onChangeEnd: _updateLeftChannel,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text("Right Phase Offset:"),
                Slider(
                  value: _currentRightOffsetValue,
                  onChanged: _onRightOffsetChange,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  label: _currentRightOffsetValue.round().toString(),
                  onChangeEnd: _updateRightChannel,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: _playSound, child: Text("Play")),
                ElevatedButton(onPressed: _pauseSound, child: Text("Pause")),
              ],
            ),
            Text("Select left wave type:"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Radio(
                      value: WaveType.sine,
                      groupValue: _currentLeftWaveType,
                      onChanged: _onLeftRadioWaveTypeChanged,
                    ),
                    Text("Sine"),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: WaveType.square,
                      groupValue: _currentLeftWaveType,
                      onChanged: _onLeftRadioWaveTypeChanged,
                    ),
                    Text("Square"),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: WaveType.triangle,
                      groupValue: _currentLeftWaveType,
                      onChanged: _onLeftRadioWaveTypeChanged,
                    ),
                    Text("Triangle"),
                  ],
                ),
              ],
            ),
            Text("Select right wave type:"),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  children: [
                    Radio(
                      value: WaveType.sine,
                      groupValue: _currentRightWaveType,
                      onChanged: _onRightRadioWaveTypeChanged,
                    ),
                    Text("Sine"),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: WaveType.square,
                      groupValue: _currentRightWaveType,
                      onChanged: _onRightRadioWaveTypeChanged,
                    ),
                    Text("Square"),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: WaveType.triangle,
                      groupValue: _currentRightWaveType,
                      onChanged: _onRightRadioWaveTypeChanged,
                    ),
                    Text("Triangle"),
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    Text("Left:"),
                    Switch(
                      value: _currentLeftStatus,
                      onChanged: _onLeftStatusChanged,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text("Right:"),
                    Switch(
                      value: _currentRightStatus,
                      onChanged: _onRightStatusChanged,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
