import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/util/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 10, 13, 12, 0, 0);

  test('under a minute is just now', () {
    expect(formatRelativeTime('2026-10-13T11:59:30Z', now: now), 'just now');
  });

  test('future timestamps are just now', () {
    expect(formatRelativeTime('2026-10-13T12:05:00Z', now: now), 'just now');
  });

  test('minutes, with and without milliseconds', () {
    expect(formatRelativeTime('2026-10-13T11:58:00Z', now: now), '2 min ago');
    expect(formatRelativeTime('2026-10-13T11:57:30.123Z', now: now), '2 min ago');
  });

  test('hours', () {
    expect(formatRelativeTime('2026-10-13T09:00:00Z', now: now), '3 hr ago');
  });

  test('days, singular and plural', () {
    expect(formatRelativeTime('2026-10-12T12:00:00Z', now: now), '1 day ago');
    expect(formatRelativeTime('2026-10-10T12:00:00Z', now: now), '3 days ago');
  });

  test('a week or more shows the date', () {
    expect(formatRelativeTime('2026-09-10T12:00:00Z', now: now), 'Sep 10');
  });

  test('unparseable input is returned unchanged', () {
    expect(formatRelativeTime('not a date', now: now), 'not a date');
  });
}
