import 'dart:ui';

class Theme8 {
  final Color primary;
  final Color accent;
  final bool inverted;
  final String name;

  Theme8(this.primary, this.accent, this.name, {this.inverted = false});

  Theme8 copyWith(
      {Color? primary, Color? accent, String? name, bool? inverted}) {
    return Theme8(
        primary ?? this.primary, accent ?? this.accent, name ?? this.name,
        inverted: inverted ?? this.inverted);
  }
}
