import 'package:flutter/material.dart';

import '../../data/models/part_model.dart';

String partOptionLabel(PartModel part) => '${part.code} — ${part.name}';

/// Searchable part picker (code / name) instead of a long dropdown.
class PartSearchField extends StatelessWidget {
  const PartSearchField({
    required this.parts,
    required this.onSelected,
    super.key,
    this.value,
    this.label,
  });

  final List<PartModel> parts;
  final String? value;
  final String? label;
  final ValueChanged<PartModel?> onSelected;

  @override
  Widget build(BuildContext context) {
    PartModel? selected;
    if (value != null) {
      for (final p in parts) {
        if (p.id == value) {
          selected = p;
          break;
        }
      }
    }

    return Autocomplete<PartModel>(
      initialValue: selected != null
          ? TextEditingValue(text: partOptionLabel(selected))
          : null,
      displayStringForOption: partOptionLabel,
      optionsBuilder: (query) {
        final q = query.text.trim().toLowerCase();
        if (q.isEmpty) {
          return parts.take(40);
        }
        return parts.where((p) {
          return p.code.toLowerCase().contains(q) ||
              p.name.toLowerCase().contains(q);
        }).take(40);
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: value != null
                ? IconButton(
                    tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      controller.clear();
                      onSelected(null);
                    },
                  )
                : null,
          ),
          onChanged: (text) {
            if (text.trim().isEmpty) onSelected(null);
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 480),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final part = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(
                      partOptionLabel(part),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: part.unit != null && part.unit!.isNotEmpty
                        ? Text('${part.costPrice} · ${part.unit}')
                        : Text('${part.costPrice}'),
                    onTap: () => onSelected(part),
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
