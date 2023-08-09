import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:fk/reader/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flows/flows.dart' as flows;


import '../diagnostics.dart';

class StartFlow {
  final String name;

  const StartFlow({required this.name});
}

class QuickFlow extends StatefulWidget {
  final StartFlow start;

  const QuickFlow({super.key, required this.start});

  @override
  // ignore: library_private_types_in_public_api
  _QuickFlowState createState() => _QuickFlowState();
}

class _QuickFlowState extends State<QuickFlow> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final flows1 = context.read<flows.ContentFlows>();
    final screen = flows1.screens[index];
    return FlowScreenWidget(
      screen: screen,
      onForward: () {
        Loggers.ui.i("forward");
        setState(() {
          index += 1;
        });
      },
      onSkip: () {
        Loggers.ui.i("skip");
      },
      onGuide: () {
        Loggers.ui.i("guide");
      },
    );
  }
}

class ProvideContentFlowsWidget extends StatelessWidget {
  final Widget child;

  const ProvideContentFlowsWidget({super.key, required this.child});

  @override
  Widget build(context) {
    return FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString("resources/flows/flows.json"),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            final flows1 = flows.ContentFlows.get(snapshot.data!);
            Loggers.ui.i("flows:ready $flows1");
            return Provider<flows.ContentFlows>(
              create: (context) => flows1,
              dispose: (context, value) => {},
              lazy: false,
              child: child,
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}

class FlowScreenWidget extends StatelessWidget {
  final flows.Screen screen;
  final VoidCallback? onForward;
  final VoidCallback? onSkip;
  final VoidCallback? onGuide;

  const FlowScreenWidget({Key? key, required this.screen, this.onForward, this.onSkip, this.onGuide}) : super(key: key);

  @override
  Widget build(context) {
    Loggers.ui.i("screen: $screen");

    return Scaffold(
      appBar: AppBar(
        title: Text(screen.header?.title ?? ""),
      ),
      body: Column(children: [
        ...screen.simple.expand((simple) {
          List<Widget> widgets = [];
          // Add markdown content widget if the body is not null or empty
          if ((simple.body ?? '').isNotEmpty) {
            widgets.add(FlowSimpleScreenWidget(screen: simple));
          }
          // Add carousel widget if there are any images
          if (simple.images.isNotEmpty) {
            widgets.add(FlowImagesWidget(screen: simple));
          }
          return widgets;
        }).toList(),
          
          Container(
            margin: const EdgeInsets.all(10.0), // CSS-like margin
            child: Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.fromLTRB(80.0, 18.0, 80.0, 18.0),
                  backgroundColor: const Color(0xffce596b), // CSS background-color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.0), // CSS border-radius
                  ),
                ),
                onPressed: onForward, 
                                    child: Text(
                                      screen.forward,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Avenir',
                                        fontSize: 18.0,
                                        color: Colors.white,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ),
            ]),
          ),
          if (screen.skip != null) TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.fromLTRB(80.0, 18.0, 80.0, 18.0),
                ),
                onPressed: onSkip, 
                child: Text(
                  screen.skip!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Avenir',
                      fontSize: 15.0,
                      color: Colors.grey[850], // Dark gray
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
          if (screen.guideTitle != null) 
            ElevatedButton(
              onPressed: onGuide, 
              child: Text(screen.guideTitle!)
              ),
        ]));
  }
}

class FlowSimpleScreenWidget extends StatelessWidget {
  final flows.Simple screen;

  const FlowSimpleScreenWidget({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    return MarkdownWidgetParser(logger: Loggers.markDown).parse(screen.body);
  }
}


class FlowImagesWidget extends StatefulWidget {
  final flows.Simple screen;

  const FlowImagesWidget({Key? key, required this.screen}) : super(key: key);

  @override
  _FlowImagesWidgetState createState() => _FlowImagesWidgetState();
}

class _FlowImagesWidgetState extends State<FlowImagesWidget> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 3), // Change duration if needed
      (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.screen.images.length;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'resources/flows/${widget.screen.images[_currentIndex].url}',
      fit: BoxFit.cover,
    );
  }
}
