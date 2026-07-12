/// Client-side gate for the admin panel.
///
/// IMPORTANT — read before shipping:
/// The Vibe Connect backend currently has **no authentication layer**
/// (see the API guide's "Production Hardening" section) — every
/// endpoint, including "delete any profile", is open to anyone who has
/// the base URL. This PIN only stops *casual* taps into the admin
/// screen from inside this app; it is not real security and will not
/// stop someone calling the API directly.
///
/// Before a public launch:
///   1. Add real auth (API key / JWT) on the server.
///   2. Gate `/api/admin/*` and bulk profile access behind it.
///   3. Replace this constant with a server-verified admin check.
///
/// Change this PIN before distributing the app to anyone else.
const String kAdminPin = '2580';
