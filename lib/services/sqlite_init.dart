import 'sqlite_init_stub.dart' if (dart.library.io) 'sqlite_init_io.dart' as impl;

/// Sets up the SQLite factory on desktop. No-op on mobile and web.
void initSqliteFactory() => impl.initSqliteFactory();
