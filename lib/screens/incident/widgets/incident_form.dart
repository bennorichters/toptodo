import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:toptodo/blocs/incident/bloc.dart';
import 'package:toptodo/constants/keys.dart' as ttd_keys;
import 'package:toptodo/constants/colors.dart' as ttd_colors;
import 'package:toptodo/widgets/landscape_padding.dart';
import 'package:toptodo/widgets/td_button.dart';
import 'package:toptodo/widgets/td_shape.dart';

class IncidentForm extends StatelessWidget {
  IncidentForm(this.state);
  final IncidentState state;

  final _formKey = GlobalKey<FormState>();
  final _briefDescription = TextEditingController();
  final _request = TextEditingController();

  static const _verticalSpace = SizedBox(height: 10);

  @override
  Widget build(BuildContext context) {
    return TdShapeBackground(
      longSide: LongSide.bottom,
      color: ttd_colors.squash,
      child: LandscapePadding(
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  key: const Key(ttd_keys.incidentBriefDescriptionField),
                  controller: _briefDescription,
                  decoration: const InputDecoration(
                    labelText: 'Brief description',
                  ),
                  validator: (value) =>
                      value.isEmpty ? 'Fill in a brief description' : null,
                ),
                _verticalSpace,
                TextFormField(
                  key: const Key(ttd_keys.incidentRequestField),
                  controller: _request,
                  decoration: const InputDecoration(labelText: 'Request'),
                  maxLength: null,
                  maxLines: null,
                ),
                _verticalSpace,
                (state is IncidentSubmitted)
                    ? const CircularProgressIndicator()
                    : TdButton(
                        key: const Key(ttd_keys.incidentSubmitButton),
                        text: 'submit',
                        onTap: () {
                          if (_formKey.currentState.validate()) {
                            BlocProvider.of<IncidentBloc>(context).add(
                              IncidentSubmit(
                                briefDescription: _briefDescription.text,
                                request: _request.text,
                              ),
                            );
                          }
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
