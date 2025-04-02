import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio();

  final String baseUrl =
      "https://hubeau.eaufrance.fr/api/v2/hydrometrie/observations_tr?code_station=V437401001&size=10";

  Future<dynamic> fetchData() async {
    try {
      final response = await _dio.get(baseUrl);

      if (response.statusCode == 200 || response.statusCode == 206) {
        return response.data; // Avec Dio, c’est déjà un objet JSON
      } else {
        throw Exception("Erreur ${response.statusCode} : Données non récupérées.");
      }
    } on DioException catch (e) {
      // Gère les erreurs spécifiques à Dio
      throw Exception("Erreur Dio : ${e.message}");
    } catch (e) {
      throw Exception("Erreur générale : $e");
    }
  }
}
