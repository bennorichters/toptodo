import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import 'package:toptodo_data/toptodo_data.dart';

import 'package:toptodo/blocs/incident/bloc.dart';

class IncidentBloc extends Bloc<IncidentEvent, IncidentState> {
  IncidentBloc({
    @required this.topdeskProvider,
    @required this.settingsProvider,
  });
  final TopdeskProvider topdeskProvider;
  final SettingsProvider settingsProvider;

  TdOperator _currentOperator;

  @override
  IncidentState get initialState => const IncidentState(currentOperator: null);

  @override
  Stream<IncidentState> mapEventToState(
    IncidentEvent event,
  ) async* {
    if (event is IncidentInit) {
      _currentOperator = await topdeskProvider.currentTdOperator();
      yield IncidentState(currentOperator: _currentOperator);
    } else if (event is IncidentSubmit) {
      yield SubmittingIncident(currentOperator: _currentOperator);

      try {
        final results = await Future.wait([
          topdeskProvider.createTdIncident(
            briefDescription: event.briefDescription,
            request: event.request.isEmpty ? null : event.request,
            settings: await settingsProvider.provide(),
          ),
          topdeskProvider.currentTdOperator(),
        ]);

        final number = results[0];
        _currentOperator = results[1];

        yield IncidentCreated(
            number: number, currentOperator: _currentOperator);
      } catch (error) {
        yield IncidentCreationError(
          cause: error,
          currentOperator: _currentOperator,
        );
      }
    }
  }
}
