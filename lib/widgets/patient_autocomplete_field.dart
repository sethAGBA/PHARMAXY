import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/patient_model.dart';

class PatientAutocompleteField extends StatelessWidget {
  const PatientAutocompleteField({
    super.key,
    required this.palette,
    required this.patients,
    required this.controller,
    required this.focusNode,
    required this.labelText,
    required this.hintText,
    required this.onChanged,
    required this.onSelected,
    this.onSubmitted,
    this.emptyMessage = 'Aucun résultat',
  });

  final ThemeColors palette;
  final List<PatientModel> patients;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String labelText;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<PatientModel> onSelected;
  final ValueChanged<String>? onSubmitted;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<PatientModel>(
      textEditingController: controller,
      focusNode: focusNode,
      displayStringForOption: (p) => p.displayLabel,
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<PatientModel>.empty();

        final qDigits = q.replaceAll(' ', '');
        return patients.where((p) {
          final nameLower = p.name.toLowerCase();
          final phoneDigits = p.phone.replaceAll(' ', '');
          final nirLower = p.nir.toLowerCase();
          return nameLower.contains(q) ||
              (phoneDigits.isNotEmpty && phoneDigits.contains(qDigits)) ||
              (nirLower.isNotEmpty && nirLower.contains(q));
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          style: TextStyle(color: palette.text),
          onChanged: onChanged,
          onSubmitted: (v) {
            onSubmitted?.call(v);
            onFieldSubmitted();
          },
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: palette.subText),
            hintText: hintText,
            hintStyle: TextStyle(color: palette.subText.withOpacity(0.7)),
            filled: true,
            fillColor: palette.isDark ? Colors.grey[900] : Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onOptionSelected, options) {
        final optionList = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            color: palette.card,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 520),
              child: optionList.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        emptyMessage,
                        style: TextStyle(color: palette.subText),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: optionList.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: palette.divider),
                      itemBuilder: (context, index) {
                        final option = optionList[index];
                        return InkWell(
                          onTap: () => onOptionSelected(option),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Text(
                              option.displayLabel,
                              style: TextStyle(color: palette.text),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
