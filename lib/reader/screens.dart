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
  @override
  Widget build(BuildContext context) {
    final flows = context.read<ContentFlows>();
    final screen = flows.screens[0];
    return FlowScreenWidget(
      screen: screen,
      onForward: () => {},
      onSkip: () => {},
      onGuide: () => {},
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

class FlowSimpleScreenWidget extends StatelessWidget {
  final Simple screen;

  const FlowSimpleScreenWidget({super.key, required this.screen});

  @override
  Widget build(BuildContext context) {
    return MarkdownWidgetParser().parse(screen.body);
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
        body: IndexedStack(children: screen.simple.map((simple) => FlowSimpleScreenWidget(screen: simple)).toList()));
  }
}
