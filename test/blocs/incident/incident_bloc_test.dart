import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:toptodo_data/toptodo_data.dart';

import 'package:toptodo/blocs/incident/bloc.dart';

import '../../test_constants.dart' as test_constants;

class MockSettingsProvider extends Mock implements SettingsProvider {}

class MockTopdeskProvider extends Mock implements TopdeskProvider {}

void main() {
  group('incident bloc', () {
    final sp = MockSettingsProvider();
    when(sp.provide()).thenAnswer((_) => Future.value(test_constants.settings));

    final tdp = MockTopdeskProvider();
    when(tdp.currentTdOperator())
        .thenAnswer((_) => Future.value(test_constants.currentOperator));
    when(tdp.createTdIncident(
      briefDescription: anyNamed('briefDescription'),
      request: anyNamed('request'),
      settings: anyNamed('settings'),
    )).thenAnswer((_) => Future.value('1'));

    blocTest<IncidentBloc, IncidentEvent, IncidentState>(
      'initial state',
      build: () => IncidentBloc(
        settingsProvider: sp,
        topdeskProvider: tdp,
      ),
      expect: [IncidentState(currentOperator: null)],
    );

    blocTest<IncidentBloc, IncidentEvent, IncidentState>(
      'IncidentShowForm emits OperatorLoaded',
      build: () => IncidentBloc(
        settingsProvider: sp,
        topdeskProvider: tdp,
      ),
      act: (bloc) async => {bloc.add(IncidentInit())},
      expect: [
        IncidentState(currentOperator: null),
        IncidentState(currentOperator: test_constants.currentOperator),
      ],
    );

    blocTest<IncidentBloc, IncidentEvent, IncidentState>(
      'create incident normal flow current operator unknown',
      build: () => IncidentBloc(
        settingsProvider: sp,
        topdeskProvider: tdp,
      ),
      act: (bloc) async => {
        bloc.add(IncidentSubmit(
          briefDescription: 'bd',
          request: '',
        ))
      },
      expect: [
        IncidentState(currentOperator: null),
        IncidentSubmitted(currentOperator: null),
        IncidentCreated(
          currentOperator: test_constants.currentOperator,
          number: '1',
        ),
      ],
    );

    blocTest<IncidentBloc, IncidentEvent, IncidentState>(
      'create incident normal flow current operator known',
      build: () => IncidentBloc(
        settingsProvider: sp,
        topdeskProvider: tdp,
      ),
      act: (bloc) async {
        bloc.add(IncidentInit());
        bloc.add(IncidentSubmit(
          briefDescription: 'bd',
          request: '',
        ));
      },
      expect: [
        IncidentState(currentOperator: null),
        IncidentState(currentOperator: test_constants.currentOperator),
        IncidentSubmitted(currentOperator: test_constants.currentOperator),
        IncidentCreated(
          currentOperator: test_constants.currentOperator,
          number: '1',
        ),
      ],
    );

    test('create incident TdException', () async {
      final timeOutTdProvider = MockTopdeskProvider();
      final exc = TdTimeOutException('error test');
      when(timeOutTdProvider.currentTdOperator())
          .thenAnswer((_) => Future.value(test_constants.currentOperator));
      when(timeOutTdProvider.createTdIncident(
        briefDescription: anyNamed('briefDescription'),
        request: anyNamed('request'),
        settings: anyNamed('settings'),
      )).thenAnswer(
        (_) => Future.delayed(Duration.zero, () => throw exc),
      );

      final bloc = IncidentBloc(
        settingsProvider: sp,
        topdeskProvider: timeOutTdProvider,
      );

      final actual = <IncidentState>[];
      final subscription = bloc.listen(actual.add);

      bloc.add(IncidentSubmit(
        briefDescription: 'bd',
        request: '',
      ));

      await bloc.close();
      await subscription.cancel();

      expect(
        actual,
        [
          IncidentState(currentOperator: null),
          IncidentSubmitted(currentOperator: null),
          IncidentCreationError(
            cause: exc,
            stackTrace: null,
            currentOperator: null,
          ),
        ],
      );
    });

    test('IncidentEvent equals', () {
      final e1 = IncidentInit();
      final e2 = IncidentInit();

      expect(e1 == e2, isTrue);
    });

    test('IncidentSubmit equals', () {
      final e1 = IncidentSubmit(briefDescription: 'a', request: 'b');
      final e2 = IncidentSubmit(briefDescription: 'a', request: 'b');

      expect(e1 == e2, isTrue);
    });

    test('WithOperatorState toString contains operator', () {
      expect(
          IncidentState(
            currentOperator: TdOperator(
              id: 'a',
              name: 'the operator',
              avatar: 'av',
              firstLine: true,
              secondLine: true,
            ),
          ).toString().contains('the operator'),
          isTrue);
    });
  });
}
