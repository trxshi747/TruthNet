import 'package:flutter/material.dart';

class MinimalDivider extends StatelessWidget {
  final double height;
  final double indent;

  const MinimalDivider({
    super.key,
    this.height = 1.0,
    this.indent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: Theme.of(context).dividerTheme.thickness,
      color: Theme.of(context).dividerTheme.color,
      indent: indent,
      endIndent: indent,
    );
  }
}
