/// Client-side models and wire protocol. The authoritative game engine lives
/// in TypeScript under /api (Vercel Functions); keep `view.dart` in sync with
/// `viewFor()` in api/_lib/engine.ts.
library;

export 'src/models.dart';
export 'src/protocol.dart';
export 'src/view.dart';
