import 'package:flutter/material.dart';

import '../models/inventory_models.dart';

class InventoryProductAutocompleteField extends StatefulWidget {
  const InventoryProductAutocompleteField({
    super.key,
    required this.controller,
    required this.options,
    required this.onSelected,
    required this.onChanged,
    this.decoration = const InputDecoration(
      labelText: 'Produit',
      hintText: 'Tapez le nom ou code CIP…',
      border: OutlineInputBorder(),
      prefixIcon: Icon(Icons.medication),
    ),
    this.maxOptionsHeight = 260,
  });

  final TextEditingController controller;
  final List<InventoryProductSnapshot> options;
  final ValueChanged<InventoryProductSnapshot> onSelected;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final double maxOptionsHeight;

  @override
  State<InventoryProductAutocompleteField> createState() =>
      _InventoryProductAutocompleteFieldState();
}

class _InventoryProductAutocompleteFieldState
    extends State<InventoryProductAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<InventoryProductSnapshot>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      displayStringForOption: (o) => '${o.name} (${o.code})',
      optionsBuilder: (textEditingValue) {
        final q = textEditingValue.text.trim().toLowerCase();
        if (q.isEmpty) return widget.options;
        return widget.options.where((snap) {
          final code = snap.code.trim().toLowerCase();
          final name = snap.name.toLowerCase();
          return name.contains(q) || code.contains(q);
        });
      },
      onSelected: widget.onSelected,
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: widget.decoration,
          onChanged: widget.onChanged,
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onOptionSelected, options) {
        final optionList = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: widget.maxOptionsHeight),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: optionList.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = optionList[index];
                  return InkWell(
                    onTap: () => onOptionSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text('${option.name} (${option.code})'),
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
