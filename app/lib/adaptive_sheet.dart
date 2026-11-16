import 'package:flutter/material.dart';

import 'theme.dart';

/// Шторка снизу на телефоне и окно по центру на широком экране (десктоп).
Future<T?> showAdaptiveSheet<T>(BuildContext context, WidgetBuilder builder) {
  if (MediaQuery.sizeOf(context).width >= 720) {
    return showDialog<T>(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: cCard,
        insetPadding: EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 520), child: builder(c)),
      ),
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: cCard,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
    builder: builder,
  );
}
