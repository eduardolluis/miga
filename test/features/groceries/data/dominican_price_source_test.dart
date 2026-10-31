import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:miga/features/groceries/data/dominican_price_source.dart';

const _csv =
    'Report;;;;;;\r\nId;Producto;Tipo;Precio;Mes;Año;establecimiento\r\n'
    '1;"Arroz; Selecto";Funda 10 Lb.;333.74;Septiembre;2026;supermercados grandes\r\n'
    '2;Pollo;Libra;no-price;Septiembre;2026;supermercados grandes\r\n'
    '3;Plátano;Unidad;20.10;Agosto;2026;colmados\r\n'
    '4;"Leche\nentera";Litro;85.01;Julio;2026;supermercados pequeños\r\n';

void main() {
  test(
    'Parses periodic supermarket references with units and original period',
    () {
      final refs = DominicanPriceSource.parseCsv(
        _csv,
        'https://proconsumidor.gob.do/prices.csv',
      );
      expect(refs, hasLength(2));
      expect(refs.first.product, 'Arroz; Selecto');
      expect(refs.first.priceCents, 33374);
      expect(refs.first.presentation, 'Funda 10 Lb.');
      expect(refs.first.month, 'Septiembre');
      expect(refs.first.year, 2026);
      expect(refs.first.countryCode, 'DO');
      expect(refs.last.product, 'Leche\nentera');
    },
  );

  test(
    'Fetches the official CSV through CKAN metadata and caches success',
    () async {
      var calls = 0;
      final source = DominicanPriceSource(
        client: MockClient((request) async {
          calls++;
          if (request.url.host == 'datos.gob.do') {
            return http.Response(
              jsonEncode({
                'success': true,
                'result': {
                  'resources': [
                    {
                      'format': 'JSON',
                      'url': 'https://proconsumidor.gob.do/prices.json',
                    },
                    {
                      'format': 'CSV',
                      'url': 'https://proconsumidor.gob.do/prices.csv',
                    },
                  ],
                },
              }),
              200,
            );
          }
          return http.Response(
            _csv,
            200,
            headers: {'content-type': 'text/csv; charset=utf-8'},
          );
        }),
      );
      final requests = await Future.wait([source.load(), source.load()]);
      expect(requests.first, hasLength(2));
      expect(requests.last, requests.first);
      expect(await source.load(), requests.first);
      expect(calls, 2);
    },
  );

  test('Fails on unavailable or changed data without fabricating prices; retries work', () async {
    var working = false;
    final source = DominicanPriceSource(
      client: MockClient((request) async {
        if (!working) return http.Response('unavailable', 503);
        if (request.url.host == 'datos.gob.do') {
          return http.Response(
            jsonEncode({
              'success': true,
              'result': {
                'resources': [
                  {
                    'format': 'CSV',
                    'url': 'https://proconsumidor.gob.do/prices.csv',
                  },
                ],
              },
            }),
            200,
          );
        }
        return http.Response(
          _csv,
          200,
          headers: {'content-type': 'text/csv; charset=utf-8'},
        );
      }),
    );
    await expectLater(source.load(), throwsStateError);
    working = true;
    expect(await source.load(), hasLength(2));
  });

  test('Rejects a CSV resource outside the official HTTPS host', () async {
    final source = DominicanPriceSource(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'result': {
              'resources': [
                {'format': 'CSV', 'url': 'https://other.example/prices.csv'},
              ],
            },
          }),
          200,
        ),
      ),
    );
    await expectLater(source.load(), throwsStateError);
  });
}
