
// a == b: 0, a < b: -1, a > b: 1
int compareDay(DateTime a, DateTime b) {
  if (a.year == b.year && a.month == b.month && a.day == b.day) {
    return 0;
  }
  return a.isAfter(b) ? 1 : -1;
}
