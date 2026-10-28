import 'package:geolocator/geolocator.dart';

/// Geolocalização do doador (RF05).
class LocationService {
  /// Retorna a posição atual ou uma mensagem de erro amigável.
  /// O tempo limite de 10 s atende ao RNF05.
  static Future<({Position? posicao, String? erro})> obterPosicao() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return (posicao: null, erro: 'O serviço de localização está desligado.');
      }
      var permissao = await Geolocator.checkPermission();
      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }
      if (permissao == LocationPermission.denied ||
          permissao == LocationPermission.deniedForever) {
        return (posicao: null, erro: 'Permissão de localização negada.');
      }
      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (posicao: posicao, erro: null);
    } catch (_) {
      return (posicao: null, erro: 'Não foi possível obter sua localização.');
    }
  }

  /// Distância em metros entre dois pontos.
  static double distancia(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}
