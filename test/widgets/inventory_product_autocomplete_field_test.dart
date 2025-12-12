import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharmaxy/models/inventory_models.dart';
import 'package:pharmaxy/widgets/inventory_product_autocomplete_field.dart';

void main() {
  testWidgets('InventoryProductAutocompleteField suggests and selects', (
    tester,
  ) async {
    final controller = TextEditingController();

    final options = [
      const InventoryProductSnapshot(
        medicamentId: 'm1',
        code: 'CIP123',
        name: 'Paracetamol',
        theoreticalQty: 10,
        purchasePrice: 100,
        salePrice: 150,
        lot: '',
        expiry: null,
        category: '',
        location: '',
      ),
      const InventoryProductSnapshot(
        medicamentId: 'm2',
        code: 'CIP999',
        name: 'Ibuprofen',
        theoreticalQty: 5,
        purchasePrice: 200,
        salePrice: 250,
        lot: '',
        expiry: null,
        category: '',
        location: '',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: InventoryProductAutocompleteField(
              controller: controller,
              options: options,
              onSelected: (_) {},
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'para');
    await tester.pumpAndSettle();

    expect(find.text('Paracetamol (CIP123)'), findsOneWidget);
    await tester.tap(find.text('Paracetamol (CIP123)'));
    await tester.pumpAndSettle();

    expect(controller.text, 'Paracetamol (CIP123)');
    controller.dispose();
  });
}
