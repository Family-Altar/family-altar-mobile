import 'package:family_altar/screens/reader/domain/text_highlight.dart';

/// Where in the reader to scroll once the requested date has loaded.
class HighlightScrollTarget {
  const HighlightScrollTarget({required this.field, required this.highlight});

  final HighlightField field;
  final TextHighlight highlight;
}

/// `extra` payload for the `/reader` route. Existing call sites keep
/// passing a bare [DateTime]; this richer payload is only used when the
/// caller also wants to scroll to a specific highlight (e.g. from the
/// highlights list screen).
class ReaderRouteArgs {
  const ReaderRouteArgs({required this.date, this.scrollTarget});

  final DateTime date;
  final HighlightScrollTarget? scrollTarget;
}
