import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:miga/features/groceries/domain/grocery_price_reference.dart';

class DominicanPriceSource {
  DominicanPriceSource({this.client});
  final http.Client? client;
  static final instance = DominicanPriceSource();
  static const catalogUrl =
      'https://datos.gob.do/api/3/action/package_show?id=precios_productos_primera_necesidad';
  List<GroceryPriceReference>? _cached;
  DateTime? _loadedAt;
  Future<List<GroceryPriceReference>>? _pending;

  Future<List<GroceryPriceReference>> load() {
    if (_cached != null &&
        DateTime.now().difference(_loadedAt!) < const Duration(hours: 6)) {
      return Future.value(_cached);
    }
    return _pending ??= _fetch().whenComplete(() => _pending = null);
  }

  Future<List<GroceryPriceReference>> _fetch() async {
    final client = this.client ?? http.Client();
    try {
      final metadata = await client
          .get(Uri.parse(catalogUrl))
          .timeout(const Duration(seconds: 12));
      if (metadata.statusCode != 200) {
        throw StateError('Price catalog unavailable');
      }
      final catalog =
          jsonDecode(utf8.decode(metadata.bodyBytes)) as Map<String, dynamic>;
      if (catalog['success'] != true) {
        throw StateError('Price catalog unavailable');
      }
      final resources =
          (catalog['result'] as Map<String, dynamic>)['resources']
              as List<dynamic>;
      final csv = resources.cast<Map<String, dynamic>>().firstWhere(
        (r) => r['format'] == 'CSV',
      );
      final uri = Uri.parse(csv['url'] as String);
      if (uri.scheme != 'https' ||
          !{
            'proconsumidor.gob.do',
            'www.proconsumidor.gob.do',
          }.contains(uri.host)) {
        throw StateError('Unexpected price source');
      }
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        throw StateError('Price data unavailable');
      }
      final references = parseCsv(
        utf8.decode(response.bodyBytes),
        uri.toString(),
      );
      if (references.isEmpty) throw StateError('Price data format changed');
      _cached = List.unmodifiable(references);
      _loadedAt = DateTime.now();
      return _cached!;
    } finally {
      if (this.client == null) client.close();
    }
  }

  static List<GroceryPriceReference> parseCsv(String text, String sourceUrl) {
    final references = <GroceryPriceReference>[];
    for (final row in _rows(text)) {
      if (row.length < 7 || int.tryParse(row[0].trim()) == null) continue;
      final amount = double.tryParse(row[3].trim().replaceAll(',', ''));
      final year = int.tryParse(row[5].trim());
      if (amount == null ||
          !amount.isFinite ||
          amount <= 0 ||
          year == null ||
          row[1].trim().isEmpty ||
          row[2].trim().isEmpty ||
          row[4].trim().isEmpty ||
          !row[6].toLowerCase().contains('supermercados')) {
        continue;
      }
      references.add(
        GroceryPriceReference(
          product: row[1].trim(),
          presentation: row[2].trim(),
          priceCents: (amount * 100).round(),
          month: row[4].trim(),
          year: year,
          segment: row[6].trim(),
          sourceUrl: sourceUrl,
        ),
      );
    }
    return references;
  }

  // The official export has semicolons, quoted fields, and embedded line breaks.
  static List<List<String>> _rows(String text) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '"') {
        if (quoted && i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && (char == ';' || char == '\n' || char == '\r')) {
        row.add(cell.toString());
        cell = StringBuffer();
        if (char != ';') {
          rows.add(row);
          row = [];
          if (char == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        }
      } else {
        cell.write(char);
      }
    }
    if (quoted) throw const FormatException('Unclosed CSV field');
    if (cell.isNotEmpty || row.isNotEmpty) {
      row.add(cell.toString());
      rows.add(row);
    }
    return rows;
  }
}
