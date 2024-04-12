import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class NumberForm extends StatefulWidget {
  final String label;
  final double? original;
  final void Function(double) onValid;
  final VoidCallback onInvalid;

  const NumberForm(
      {super.key,
      required this.label,
      required this.original,
      required this.onValid,
      required this.onInvalid});

  @override
  State<NumberForm> createState() => _NumberFormState();
}

class _NumberFormState extends State<NumberForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
        key: _formKey,
        child: Column(children: [
          Focus(
              onFocusChange: (hasFocus) {
                if (!hasFocus) {
                  if (_formKey.currentState!.saveAndValidate()) {
                    final stringValue = _formKey.currentState!.value['value'];
                    final value = double.parse(stringValue);
                    widget.onValid(value);
                  } else {
                    widget.onInvalid();
                  }
                }
              },
              child: FormBuilderTextField(
                name: 'value',
                initialValue:
                    widget.original == null ? "" : widget.original.toString(),
                keyboardType: const TextInputType.numberWithOptions(
                    signed: true, decimal: true),
                decoration: InputDecoration(labelText: widget.label),
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.numeric(),
                ]),
              ))
        ]));
  }
}
