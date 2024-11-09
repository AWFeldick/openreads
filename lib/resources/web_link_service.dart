import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:openreads/model/web_search_result.dart';

class WebLinkService {
  Future<WebSearchResult> getResults({
    required String rawUrl,
  }) async {
    final uri = Uri.parse(rawUrl);

    final response = await get(uri);
    return webSearchResultFromPage(response.body);
  }

  Future<Uint8List?> getCover(String url) async {
    try {
      final response = await get(
        Uri.parse(url),
      );

      // If the response is less than 500 bytes,
      // probably the cover is not available
      if (response.bodyBytes.length < 500) return null;

      return response.bodyBytes;
    } catch (e) {
      return null;
    }
  }
}
