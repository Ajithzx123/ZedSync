enum Platform {
  mt5('MT5'),
  tradelocker('TradeLocker'),
  ctrader('cTrader');

  const Platform(this.label);
  final String label;
}

enum AccountType {
  personal('Personal'),
  evaluation('Evaluation'),
  funded('Funded'),
  instantFunded('Instant funded'),
  other('Other');

  const AccountType(this.label);
  final String label;
}

enum Environment { live, demo }

enum ConnectionStatus {
  connected('Connected'),
  syncing('Syncing'),
  delayed('Delayed'),
  disconnected('Disconnected'),
  authExpired('Reconnect required'),
  error('Error'),
  maintenance('Maintenance'),
  notAuthorized('Not authorized');

  const ConnectionStatus(this.label);
  final String label;

  bool get isLive => this == ConnectionStatus.connected;
}

enum Side { buy, sell }

enum OrderType {
  buyLimit('Buy Limit'),
  sellLimit('Sell Limit'),
  buyStop('Buy Stop'),
  sellStop('Sell Stop'),
  buyStopLimit('Buy Stop Limit'),
  sellStopLimit('Sell Stop Limit');

  const OrderType(this.label);
  final String label;
}

enum DealKind { trade, deposit, withdrawal, adjustment }

enum DealEntry { inEntry, out, inout }
