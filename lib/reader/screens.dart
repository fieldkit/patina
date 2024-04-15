import 'package:fk/common_widgets.dart';
import 'package:fk/reader/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flows/flows.dart' as flows;

import '../diagnostics.dart';

class QuickFlow extends StatefulWidget {
  final flows.StartFlow start;

  const QuickFlow({super.key, required this.start});

  @override
  State<QuickFlow> createState() => _QuickFlowState();
}

class _QuickFlowState extends State<QuickFlow> {
  int index = 0;

  void onBack() {
    if (index > 0) {
      Loggers.ui.i("back");
      setState(() {
        index -= 1;
      });
    } else {
      Loggers.ui.i("back:exit");
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowsContent = context.read<flows.ContentFlows>();
    final screens = flowsContent.getScreens(widget.start);
    final screen = screens[index];

    final body = FlowScreenWidget(
      screen: screen,
      onForward: () {
        Loggers.ui.i("forward");
        setState(() {
          index += 1;
        });
      },
      onBack: onBack,
      onSkip: () {
        Loggers.ui.i("skip");
      },
      onGuide: () {
        Loggers.ui.i("guide");
      },
    );

    return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          onBack();
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed:
                  onBack, // If onBack is not provided, the IconButton will be disabled.
            ),
            title: Text(screen.header?.title ?? ""),
          ),
          body: body,
        ));
  }
}

class ProvideContentFlowsWidget extends StatelessWidget {
  final Widget child;

  const ProvideContentFlowsWidget({super.key, required this.child});

  @override
  Widget build(context) {
    final Locale active = Localizations.localeOf(context);
    final String path = "resources/flows/flows_${active.languageCode}.json";

    Loggers.ui.i("loading $path");

    return FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString(path),
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.hasData) {
            final flowsContent = flows.ContentFlows.get(snapshot.data!);
            Loggers.ui.i("flows:ready $flowsContent");
            return Provider<flows.ContentFlows>(
              create: (context) => flowsContent,
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
  final VoidCallback? onBack;

  const FlowScreenWidget(
      {super.key,
      required this.screen,
      this.onForward,
      this.onSkip,
      this.onGuide,
      this.onBack});

  List<Widget> buttons() {
    return [
      Container(
        margin: const EdgeInsets.all(10.0),
        child: Column(children: [
          ElevatedTextButton(
            onPressed: onForward,
            text: screen.forward,
          ),
        ]),
      ),
      if (screen.skip != null)
        TextButton(
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
              color: Colors.grey[850],
              letterSpacing: 0.1,
            ),
          ),
        ),
      if (screen.guideTitle != null)
        ElevatedTextButton(onPressed: onGuide, text: screen.guideTitle!),
    ];
  }

  @override
  Widget build(context) {
    Loggers.ui.i("screen: $screen");

    assert(screen.simple.length == 1);
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(children: [
          Expanded(
              child: Column(children: [
            FlowSimpleScreenWidget(screen: screen.simple[0]),
            ...buttons(),
          ]))
        ]));
  }
}

class FlowSimpleScreenWidget extends StatelessWidget {
  final flows.Simple screen;

  const FlowSimpleScreenWidget({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    return MarkdownWidgetParser(logger: Loggers.markDown, images: screen.images)
        .parse(screen.body);
  }
}

class FlowNamedScreenWidget extends StatelessWidget {
  final String name;
  final VoidCallback? onForward;
  final VoidCallback? onSkip;
  final VoidCallback? onGuide;
  final VoidCallback? onBack;

  const FlowNamedScreenWidget(
      {super.key,
      required this.name,
      this.onForward,
      this.onSkip,
      this.onGuide,
      this.onBack});

  @override
  Widget build(BuildContext context) {
    final flowsContent = context.read<flows.ContentFlows>();
    final screen = flowsContent.getScreen(name);

    return FlowScreenWidget(
      screen: screen,
      onForward: onForward,
      onSkip: onSkip,
      onGuide: onGuide,
      onBack: onBack,
    );
  }
}
