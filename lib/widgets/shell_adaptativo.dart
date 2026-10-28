import 'package:flutter/material.dart';

class DestinoNav {
  const DestinoNav(this.icone, this.iconeSelecionado, this.rotulo, {this.badge = 0});
  final IconData icone;
  final IconData iconeSelecionado;
  final String rotulo;
  final int badge;
}

/// Estrutura de navegação responsiva (RNF04):
/// - celular: barra inferior (NavigationBar);
/// - tablet/web (>= 720 px): menu lateral (NavigationRail).
class ShellAdaptativo extends StatelessWidget {
  const ShellAdaptativo({
    super.key,
    required this.titulo,
    required this.destinos,
    required this.indice,
    required this.aoMudar,
    required this.corpo,
    this.acoes = const [],
  });

  final String titulo;
  final List<DestinoNav> destinos;
  final int indice;
  final ValueChanged<int> aoMudar;
  final Widget corpo;
  final List<Widget> acoes;

  Widget _icone(IconData i, int badge) => badge > 0
      ? Badge(label: Text('$badge'), child: Icon(i))
      : Icon(i);

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
      actions: [...acoes, const SizedBox(width: 4)],
      scrolledUnderElevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );

    return LayoutBuilder(builder: (context, c) {
      final largo = c.maxWidth >= 720;
      if (largo) {
        return Scaffold(
          appBar: appBar,
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: indice,
                onDestinationSelected: aoMudar,
                labelType: NavigationRailLabelType.all,
                backgroundColor: Colors.white,
                destinations: [
                  for (final d in destinos)
                    NavigationRailDestination(
                      icon: _icone(d.icone, d.badge),
                      selectedIcon: _icone(d.iconeSelecionado, d.badge),
                      label: Text(d.rotulo),
                    ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: corpo),
            ],
          ),
        );
      }
      return Scaffold(
        appBar: appBar,
        body: corpo,
        bottomNavigationBar: NavigationBar(
          selectedIndex: indice,
          onDestinationSelected: aoMudar,
          backgroundColor: Colors.white,
          destinations: [
            for (final d in destinos)
              NavigationDestination(
                icon: _icone(d.icone, d.badge),
                selectedIcon: _icone(d.iconeSelecionado, d.badge),
                label: d.rotulo,
              ),
          ],
        ),
      );
    });
  }
}
