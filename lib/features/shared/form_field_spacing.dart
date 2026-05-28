import 'package:flutter/material.dart';

/// Default vertical gap between stacked fields in dialogs and forms.
const double kFormFieldSpacing = 20;

/// Standard [AlertDialog] insets so labels and actions are not cramped.
const EdgeInsets kDialogTitlePadding = EdgeInsets.fromLTRB(24, 24, 24, 0);
const EdgeInsets kDialogContentPadding = EdgeInsets.fromLTRB(24, 16, 24, 12);
const EdgeInsets kDialogActionsPadding = EdgeInsets.fromLTRB(20, 8, 20, 20);

/// Inserts [kFormFieldSpacing] between each child so outlined labels do not overlap.
List<Widget> spacedFormFields(List<Widget> fields) {
  if (fields.isEmpty) return fields;
  final result = <Widget>[fields.first];
  for (var i = 1; i < fields.length; i++) {
    result.add(const SizedBox(height: kFormFieldSpacing));
    result.add(fields[i]);
  }
  return result;
}
