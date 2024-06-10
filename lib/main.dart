import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:real_time_chart/real_time_chart.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real Time Chart',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final WebSocket _socket = WebSocket('ws://127.0.0.1:8080/ws');
  final BehaviorSubject<List<double>> _chartStreams = BehaviorSubject();
  final BehaviorSubject<int> _channels = BehaviorSubject();
  final BehaviorSubject<List<BehaviorSubject<double>>> _channelsList =
      BehaviorSubject();
  int channelsCount = 0;

  final List<StreamController<double>> _streamController =
      <StreamController<double>>[];

  Stream<double> getChannelStream(int i) => _streamController[i].stream;

  List<BehaviorSubject<double>> _bufferChannels = [];

  // List<BehaviorSubject<double>> _channelsList = [];
  // behaviorSubject.add(channelsList[i]);

  @override
  void initState() {
    super.initState();

    _socket.onOpen.listen((event) {
      _socket.send('{"type": "manual", "mode": "sinus"}');
    });

    // _chartStreams.listen((List<double> values) {
    //   var _b = <BehaviorSubject<double>>[];
    //   for (var i = 0; i < values.length; i++) {
    //     try {
    //       final channel = _bufferChannels[i];
    //       _b.add(channel);
    //     } catch (e) {
    //       _bufferChannels.add(Stream);
    //       _channelsList.add(_b);
    //     }
    //   }
    // });

    _socket.onClose.listen((event) {
      channelsCount = 0;
    });
    _socket.onMessage.listen((MessageEvent e) {
      var data = e.data as String;
      var values = data.split(',').map((e) => double.parse(e)).toList();

      if (values.isNotEmpty && channelsCount != values.length) {
        for (int i = 0; i < values.length; i++) {
          channelsCount++;
          _channels.add(channelsCount);

          _streamController.add(StreamController<double>());
          _streamController[i].add(values[i]);
        }
      } else {
        for (int i = 0; i < values.length; i++) {
          _streamController[i].add(values[i]);
        }
      }
    });
  }

  @override
  void dispose() {
    _socket.close();

    _channels.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Time Chart'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Expanded(
              child: StreamBuilder<int>(
                  stream: _channels.stream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final channelsCount = snapshot.data;
                      return ListView.builder(
                          itemCount: channelsCount,
                          itemBuilder: (context, i) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height * 0.5,
                              child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: RealTimeGraph(
                                    supportNegativeValuesDisplay: true,
                                    key: Key(i.toString()),
                                    stream: getChannelStream(i),
                                  )),
                            );
                          });
                    } else {
                      return const CircularProgressIndicator();
                    }
                  })),
        ],
      ),
    );
  }
}

// Stream<double> positiveDataStream() {
//   return Stream.periodic(const Duration(milliseconds: 500), (_) {
//     return Random().nextInt(300).toDouble();
//   }).asBroadcastStream();
// }
