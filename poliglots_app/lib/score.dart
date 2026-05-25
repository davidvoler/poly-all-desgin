/// Local mirror of the server's score calculation in
/// `server/src/routers/user_data.py::calculate_score`. The server is
/// still the source of truth for what gets stored in `user_data.results`;
/// this client copy exists so pages can display the score live without a
/// round-trip (per-question mark, end-of-lesson totals, etc.).
///
/// If the server formula changes, update this in lockstep.
double calculateScore({
  required double correctRatio,
  required int incorrectCount,
  required int attempts,
}) {
  if (correctRatio == 1 && incorrectCount == 0) {
    return attempts == 1 ? 1.0 : 0.9;
  }
  if (correctRatio == 0) {
    return -1.0;
  }
  final raw = -(correctRatio + 0.2 * incorrectCount);
  return raw < -1.0 ? -1.0 : raw;
}
