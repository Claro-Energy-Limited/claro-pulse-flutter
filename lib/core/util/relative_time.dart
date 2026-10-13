/// Time helpers, ported from the Kotlin `RelativeTime.kt`.
///
/// Every server timestamp is ISO-8601 UTC, with or without milliseconds;
/// `DateTime.tryParse` handles both.

library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "just now" / "2 min ago" / "3 hr ago" / "2 days ago" / "Sep 10": plain language.
/// Returns the input unchanged if it can't be parsed, so a server format change
/// degrades to something visible rather than silently vanishing.
String formatRelativeTime(String iso, {DateTime? now}) {
  final then = DateTime.tryParse(iso);
  if (then == null) return iso;
  final diff = (now ?? DateTime.now()).toUtc().difference(then.toUtc());
  final minutes = diff.inMinutes;

  if (diff.isNegative || minutes < 1) return 'just now';
  if (minutes < 60) return '$minutes min ago';
  if (minutes < 60 * 24) return '${minutes ~/ 60} hr ago';
  if (minutes < 60 * 24 * 7) {
    final days = minutes ~/ (60 * 24);
    return '$days day${days == 1 ? '' : 's'} ago';
  }
  final local = then.toLocal();
  return '${_months[local.month - 1]} ${local.day}';
}

/// Parses an activity bucket's `bucketStart` for chart labels. Returns null on
/// failure: a chart axis has no sensible place to show a raw ISO string.
DateTime? parseActivityBucketStart(String iso) => DateTime.tryParse(iso);
