import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zedsync/domain/models/deal.dart';
import 'package:zedsync/domain/models/enums.dart';
import 'package:zedsync/domain/models/pending_order.dart';
import 'package:zedsync/domain/models/portfolio.dart';
import 'package:zedsync/domain/models/position.dart';
import 'package:zedsync/domain/models/trading_account.dart';
import 'package:zedsync/ui/features/portfolio/portfolio_controller.dart';

/// Real backend responses captured from the mock connector.
final Map<String, dynamic> fixture =
    jsonDecode(File('test/fixtures/api_snapshot.json').readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> rows(String key) => (fixture[key] as List<dynamic>).cast<Map<String, dynamic>>();

/// Normalizes ints/doubles and date formats so round-trips compare equal.
Object? norm(Object? v) => switch (v) {
      Map m => {for (final e in m.entries) e.key: norm(e.value)},
      List l => l.map(norm).toList(),
      num n => n.toDouble(),
      String s when DateTime.tryParse(s) != null && s.contains('T') => DateTime.parse(s).toUtc().toIso8601String(),
      _ => v,
    };

void main() {
  group('JSON round-trip against backend payloads', () {
    test('TradingAccount', () {
      for (final j in rows('accounts')) {
        expect(norm(TradingAccount.fromJson(j).toJson()), norm(j));
      }
    });

    test('Position', () {
      for (final j in rows('positions')) {
        expect(norm(Position.fromJson(j).toJson()), norm(j));
      }
    });

    test('PendingOrder', () {
      for (final j in rows('orders')) {
        expect(norm(PendingOrder.fromJson(j).toJson()), norm(j));
      }
    });

    test('Deal (keeps only fields the app models)', () {
      for (final j in rows('deals')) {
        final back = Deal.fromJson(j).toJson();
        for (final k in back.keys) {
          expect(norm(back[k]), norm(j[k]), reason: 'field $k');
        }
      }
    });

    test('PortfolioSummary and exposure', () {
      final s = fixture['summary'] as Map<String, dynamic>;
      expect(norm(PortfolioSummary.fromJson(s).toJson()), norm(s));
      for (final j in rows('exposure')) {
        expect(norm(SymbolExposure.fromJson(j).toJson()), norm(j));
      }
    });
  });

  group('parsing details', () {
    test('enums map from backend names', () {
      final a = rows('accounts').map(TradingAccount.fromJson).toList();
      expect(a.map((x) => x.platform).toSet(), {Platform.mt5, Platform.tradelocker, Platform.ctrader});
      expect(a.any((x) => x.connectionStatus == ConnectionStatus.disconnected), isTrue);
    });

    test('deal IN entry maps despite reserved word', () {
      final d = rows('deals').map(Deal.fromJson).firstWhere((d) => d.entry == DealEntry.inEntry);
      expect(d.toJson()['entry'], 'IN');
    });

    test('bad payload throws FormatException naming the key', () {
      final bad = {...rows('positions').first, 'volume': 'lots'};
      expect(() => Position.fromJson(bad),
          throwsA(isA<FormatException>().having((e) => e.message, 'message', contains('volume'))));
    });

    test('summary keeps incomplete flag and stale ids', () {
      final s = PortfolioSummary.fromJson(fixture['summary'] as Map<String, dynamic>);
      expect(s.isComplete, isFalse);
      expect(s.staleAccountIds, ['acc_mt5_f2']);
    });
  });

  group('AccountFilter', () {
    final accounts = rows('accounts').map(TradingAccount.fromJson).toList();
    int count(AccountFilter f) => accounts.where(f.matches).length;

    test('categories', () {
      expect(count(AccountFilter.all), accounts.length);
      expect(count(AccountFilter.funded), 2);
      expect(count(AccountFilter.evaluation), 1);
      expect(count(AccountFilter.demo), 1);
      expect(count(AccountFilter.live) + count(AccountFilter.demo), accounts.length);
      expect(count(AccountFilter.mt5) + count(AccountFilter.tradelocker) + count(AccountFilter.ctrader),
          accounts.length);
    });
  });
}
