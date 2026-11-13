/// Game API endpoint. On Vercel the app and the function share an origin.
/// For `flutter run` against `vercel dev`, pass
/// `--dart-define=API_URL=http://localhost:3000/api/game`.
Uri apiUri() {
  const override = String.fromEnvironment('API_URL');
  if (override.isNotEmpty) return Uri.parse(override);
  return Uri.base.resolve('/api/game');
}

/// Link encoded in the lobby QR code. Set `--dart-define=PUBLIC_URL=...`
/// when the page isn't opened from its public address.
String joinUrlFor(String pin) {
  const publicUrl = String.fromEnvironment('PUBLIC_URL');
  final base = publicUrl.isNotEmpty ? Uri.parse(publicUrl) : Uri.base;
  return Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.port,
    path: '/',
    queryParameters: {'pin': pin},
  ).toString();
}
