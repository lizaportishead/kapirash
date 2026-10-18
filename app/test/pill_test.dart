import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kapiras/theme.dart';

void main() {
  testWidgets('чипы в Wrap занимают ширину по тексту и стоят по несколько в ряд', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: Wrap(spacing: 8, runSpacing: 8, children: [for (final s in ['Еда', 'Быт', 'Юмор', 'IT']) Pill(s, onTap: () {})]),
          ),
        ),
      ),
    );
    final a = t.getTopLeft(find.byType(Pill).at(0)), b = t.getTopLeft(find.byType(Pill).at(1));
    expect(a.dy, b.dy);
    expect(t.getSize(find.byType(Pill).first).width, lessThan(120));
    expect(t.getSize(find.byType(Pill).first).height, 38);
  });
}
