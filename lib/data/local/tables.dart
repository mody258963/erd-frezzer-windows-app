import 'package:drift/drift.dart';

class Parts extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get unit => text().nullable()();
  RealColumn get sellPrice => real()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class StockRows extends Table {
  TextColumn get partId => text()();
  TextColumn get branchId => text()();
  RealColumn get quantity => real()();

  @override
  Set<Column> get primaryKey => {partId, branchId};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  RealColumn get outstandingBalance =>
      real().withDefault(const Constant(0))();
  TextColumn get settlementCycle => text().nullable()();
  DateTimeColumn get lastSettledAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PendingInvoices extends Table {
  TextColumn get localId => text()();
  TextColumn get customerId => text()();
  TextColumn get branchId => text()();
  TextColumn get paymentType => text()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get subtotal => real()();
  RealColumn get total => real()();
  TextColumn get status => text()();
  TextColumn get serverInvoiceId => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {localId};
}

class PendingInvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get localInvoiceId => text()();
  TextColumn get partId => text()();
  TextColumn get partCode => text()();
  TextColumn get partName => text()();
  RealColumn get quantity => real()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
}

class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
