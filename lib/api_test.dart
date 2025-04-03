import 'package:dio/dio.dart';

Future<void> main() async {
  // Initialisation de Dio
  final dio = Dio();
  // Base URL de l'API
  final baseUrl = 'https://hubeau.eaufrance.fr/api/v2/hydrometrie';

  // Liste des endpoints à tester
  final endpoints = [
    '/obs_elab',
    '/obs_elab.csv',
    '/observations_tr',
    '/observations_tr.csv',
    '/observations_tr.xml',
    '/referentiel/sites',
    '/referentiel/sites.csv',
    '/referentiel/sites.xml',
    '/referentiel/stations',
    // Pour récupérer les stations au format CSV (pour affichage des suggestions, par exemple)
    '/referentiel/stations.csv',
    '/referentiel/stations.xml',
  ];

  for (var endpoint in endpoints) {
    final url = '$baseUrl$endpoint';
    print('---\nAppel à l\'endpoint: $url');
    try {
      final response = await dio.get(url);
      final contentType = response.headers.value('content-type') ?? 'inconnu';
      print('Content-Type: $contentType');
      print('Status: ${response.statusCode}');
      
      // Affiche un extrait de la réponse (les 500 premiers caractères)
      String dataStr;
      if (response.data is String) {
        dataStr = response.data;
      } else {
        dataStr = response.data.toString();
      }
      
      final excerpt = dataStr.length > 500 ? dataStr.substring(0, 500) : dataStr;
      print('Réponse (extrait):\n$excerpt\n');
    } catch (e) {
      print('Erreur lors de l\'appel à $url : $e');
    }
  }
}
