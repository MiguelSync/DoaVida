import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/instituicao.dart';
import '../../services/location_service.dart';
import '../../state/app_state.dart';
import '../../theme/tema.dart';
import '../../utils/formatos.dart';
import '../../widgets/comuns.dart';
import 'novo_agendamento_screen.dart';

/// RF05 — Mapa com hemocentros e hospitais mais próximos do doador.
class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  /// Centro de Rio do Sul — usado quando a localização não está disponível.
  static final _centroPadrao = LatLng(-27.2142, -49.6431);

  final _mapa = MapController();
  LatLng? _usuario;
  bool _localizando = false;
  String? _aviso;
  String? _selecionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _localizar();
    });
  }

  Future<void> _localizar() async {
    setState(() {
      _localizando = true;
      _aviso = null;
    });
    final r = await LocationService.obterPosicao();
    if (!mounted) return;
    setState(() {
      _localizando = false;
      final p = r.posicao;
      if (p != null) {
        _usuario = LatLng(p.latitude, p.longitude);
      } else {
        _aviso = '${r.erro} Distâncias calculadas a partir do centro de Rio do Sul.';
      }
    });
    if (_usuario != null) _mover(_usuario!, 10.5);
  }

  void _mover(LatLng ponto, double zoom) {
    try {
      _mapa.move(ponto, zoom);
    } catch (_) {
      // O mapa ainda não foi desenhado; ignora.
    }
  }

  double _distancia(Instituicao i) {
    final o = _usuario ?? _centroPadrao;
    return LocationService.distancia(o.latitude, o.longitude, i.lat, i.lng);
  }

  void _selecionar(Instituicao i) {
    setState(() => _selecionada = i.id);
    _mover(LatLng(i.lat, i.lng), 13);
  }

  Future<void> _rota(Instituicao i) async {
    final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${i.lat},${i.lng}');
    var ok = false;
    try {
      ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok && mounted) avisar(context, 'Não foi possível abrir o mapa.');
  }

  void _agendar(Instituicao i) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NovoAgendamentoScreen(instituicaoId: i.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final estado = context.watch<AppState>();
    final instituicoes = [...estado.instituicoes]
      ..sort((a, b) => _distancia(a).compareTo(_distancia(b)));
    final podeAgendar = estado.doadorAtual != null &&
        estado.agendamentoAtivoDe(estado.doadorAtual!.id) == null;

    final mapa = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapa,
            options: MapOptions(
              initialCenter: _usuario ?? _centroPadrao,
              initialZoom: 9.4,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.edu.unidavi.doa_sangue',
              ),
              MarkerLayer(
                markers: [
                  for (final i in instituicoes)
                    Marker(
                      point: LatLng(i.lat, i.lng),
                      width: 48,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _selecionar(i),
                        child: _Pino(
                          instituicao: i,
                          selecionado: _selecionada == i.id,
                        ),
                      ),
                    ),
                  if (_usuario != null)
                    Marker(
                      point: _usuario!,
                      width: 26,
                      height: 26,
                      child: const _PontoUsuario(),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              color: Colors.white.withValues(alpha: 0.8),
              child: const Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 10)),
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: FloatingActionButton.small(
              heroTag: 'minha_localizacao',
              tooltip: 'Minha localização',
              backgroundColor: Colors.white,
              onPressed: _localizando ? null : _localizar,
              child: _localizando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location, color: AppCores.vermelho),
            ),
          ),
        ],
      ),
    );

    final lista = ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        if (_aviso != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Cartao(
              cor: AppCores.baixo.withValues(alpha: 0.06),
              corBorda: AppCores.baixo.withValues(alpha: 0.25),
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Icon(Icons.location_off_outlined, color: AppCores.baixo),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(_aviso!, style: const TextStyle(fontSize: 13))),
              ]),
            ),
          ),
        for (final i in instituicoes) ...[
          _ItemInstituicao(
            instituicao: i,
            distancia: _distancia(i),
            selecionada: _selecionada == i.id,
            podeAgendar: podeAgendar,
            onTap: () => _selecionar(i),
            onRota: () => _rota(i),
            onAgendar: () => _agendar(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 900) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mapa),
              const SizedBox(width: 8),
              SizedBox(width: 400, child: lista),
            ],
          ),
        );
      }
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: SizedBox(height: c.maxHeight * 0.42, child: mapa),
          ),
          Expanded(child: lista),
        ],
      );
    });
  }
}

class _Pino extends StatelessWidget {
  const _Pino({required this.instituicao, required this.selecionado});
  final Instituicao instituicao;
  final bool selecionado;

  @override
  Widget build(BuildContext context) {
    final cor = instituicao.temEstoqueCritico
        ? AppCores.critico
        : AppCores.vermelhoEscuro;
    return AnimatedScale(
      scale: selecionado ? 1.25 : 1,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: cor, width: selecionado ? 4 : 3),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Icon(
          instituicao.tipo == TipoInstituicao.hemocentro
              ? Icons.water_drop
              : Icons.local_hospital,
          color: cor,
          size: 22,
        ),
      ),
    );
  }
}

class _PontoUsuario extends StatelessWidget {
  const _PontoUsuario();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppCores.info,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
    );
  }
}

class _ItemInstituicao extends StatelessWidget {
  const _ItemInstituicao({
    required this.instituicao,
    required this.distancia,
    required this.selecionada,
    required this.podeAgendar,
    required this.onTap,
    required this.onRota,
    required this.onAgendar,
  });

  final Instituicao instituicao;
  final double distancia;
  final bool selecionada;
  final bool podeAgendar;
  final VoidCallback onTap;
  final VoidCallback onRota;
  final VoidCallback onAgendar;

  @override
  Widget build(BuildContext context) {
    final i = instituicao;
    final criticos = i.tiposNoNivel(NivelEstoque.critico);
    final baixos = i.tiposNoNivel(NivelEstoque.baixo);
    return Cartao(
      onTap: onTap,
      corBorda: selecionada ? AppCores.vermelho : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                i.tipo == TipoInstituicao.hemocentro
                    ? Icons.water_drop_outlined
                    : Icons.local_hospital_outlined,
                color: AppCores.vermelho,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.nome,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    Text('${i.tipo.label} · ${i.cidade}',
                        style: const TextStyle(color: AppCores.textoSuave)),
                    const SizedBox(height: 2),
                    Text(i.horario,
                        style: const TextStyle(
                            fontSize: 12, color: AppCores.textoSuave)),
                  ],
                ),
              ),
              Text(fDistancia(distancia),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          if (criticos.isNotEmpty || baixos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in criticos)
                  Etiqueta('${t.label} crítico', cor: AppCores.critico),
                for (final t in baixos)
                  Etiqueta('${t.label} baixo', cor: AppCores.baixo),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRota,
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Rota'),
              ),
              const SizedBox(width: 4),
              FilledButton.tonalIcon(
                onPressed: podeAgendar ? onAgendar : null,
                icon: const Icon(Icons.event_available),
                label: const Text('Agendar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
