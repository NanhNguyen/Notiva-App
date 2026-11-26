import 'package:flutter/widgets.dart';

/// Corner radius tokens from docs/design.md.
abstract final class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 20.0;
  static const double full = 999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLgTop = BorderRadius.vertical(
    top: Radius.circular(lg),
  );
  static const BorderRadius borderFull = BorderRadius.all(
    Radius.circular(full),
  );
}

