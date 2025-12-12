import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pharmaxy/app_theme.dart';
import 'package:pharmaxy/models/patient_model.dart';
import 'package:pharmaxy/widgets/patient_autocomplete_field.dart';

void main() {
  testWidgets('PatientAutocompleteField shows suggestions and selects one', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    final patients = [
      const PatientModel(
        id: '1',
        name: 'Jean Dupont',
        phone: '99 12 34 56',
        nir: 'NIR123',
        mutuelle: '',
        email: '',
        dateOfBirthIso: '',
      ),
      const PatientModel(
        id: '2',
        name: 'Alice Martin',
        phone: '77 00 00 00',
        nir: '',
        mutuelle: '',
        email: '',
        dateOfBirthIso: '',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final palette = ThemeColors.from(context);
              return Padding(
                padding: const EdgeInsets.all(16),
                child: PatientAutocompleteField(
                  palette: palette,
                  patients: patients,
                  controller: controller,
                  focusNode: focusNode,
                  labelText: 'Client',
                  hintText: 'Rechercher…',
                  onChanged: (_) {},
                  onSelected: (_) {},
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'je');
    await tester.pumpAndSettle();

    expect(find.text(patients.first.displayLabel), findsOneWidget);
    await tester.tap(find.text(patients.first.displayLabel));
    await tester.pumpAndSettle();

    expect(controller.text, patients.first.displayLabel);

    focusNode.dispose();
    controller.dispose();
  });

  testWidgets('PatientAutocompleteField hides options when empty', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              final palette = ThemeColors.from(context);
              return PatientAutocompleteField(
                palette: palette,
                patients: const [],
                controller: controller,
                focusNode: focusNode,
                labelText: 'Client',
                hintText: 'Rechercher…',
                onChanged: (_) {},
                onSelected: (_) {},
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'zz');
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsNothing);

    focusNode.dispose();
    controller.dispose();
  });
}
