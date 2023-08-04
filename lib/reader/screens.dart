import 'package:flows/flows.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../diagnostics.dart';
import 'widgets.dart';

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
    final flows = context.read<ContentFlows>();
    final screen = flows.screens[index];
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
            final flows = ContentFlows.get(snapshot.data!);
            Loggers.ui.i("flows:ready $flows");
            return Provider<ContentFlows>(
              create: (context) => flows,
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
  final Screen screen;
  final VoidCallback? onForward;
  final VoidCallback? onSkip;
  final VoidCallback? onGuide;

  const FlowScreenWidget({super.key, required this.screen, this.onForward, this.onSkip, this.onGuide});

  @override
  Widget build(context) {
    Loggers.ui.i("screen: $screen");

    return Scaffold(
        appBar: AppBar(
          title: Text(screen.header?.title ?? ""),
        ),
        body: Column(children: [
          IndexedStack(children: screen.simple.map((simple) => FlowSimpleScreenWidget(screen: simple)).toList()),
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
                      fontSize: 18.0,
                      color: Colors.grey[850], // Dark gray
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
          if (screen.guideTitle != null) ElevatedButton(onPressed: onGuide, child: Text(screen.guideTitle!
                                    )),
        ]));
  }
}

class FlowSimpleScreenWidget extends StatelessWidget {
  final Simple screen;

  const FlowSimpleScreenWidget({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    return MarkdownWidgetParser(logger: Loggers.markDown).parse(screen.body);
  }
}
