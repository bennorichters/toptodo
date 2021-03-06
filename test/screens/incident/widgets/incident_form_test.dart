import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toptodo/blocs/incident/bloc.dart';
import 'package:toptodo/screens/incident/widgets/incident_form.dart';
import 'package:toptodo/constants/keys.dart' as ttd_keys;

import '../../../test_helper.dart';
import '../../../test_constants.dart' as test_constants;

class MockIncidentBloc extends MockBloc<IncidentEvent, IncidentState>
    implements IncidentBloc {}

void main() {
  group('IncidentForm', () {
    IncidentBloc bloc;

    void pumpForm(
      WidgetTester tester,
      IncidentState state,
    ) async {
      await tester.pumpWidget(
        BlocProvider.value(
          value: bloc,
          child: TestableWidgetWithMediaQuery(
            child: IncidentForm(state),
          ),
        ),
      );
    }

    setUp(() {
      bloc = MockIncidentBloc();
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('find one button when not submitting',
        (WidgetTester tester) async {
      await pumpForm(
        tester,
        IncidentState(
          currentOperator: test_constants.currentOperator,
        ),
      );
      expect(find.byKey(Key(ttd_keys.incidentSubmitButton)), findsOneWidget);
    });

    testWidgets('find no button when submitting', (WidgetTester tester) async {
      await pumpForm(
        tester,
        IncidentSubmitted(
          currentOperator: test_constants.currentOperator,
        ),
      );
      expect(find.byKey(Key(ttd_keys.incidentSubmitButton)), findsNothing);
    });

    testWidgets('tap button', (WidgetTester tester) async {
      when(bloc.state).thenReturn(IncidentState(currentOperator: null));
      await pumpForm(
        tester,
        IncidentState(
          currentOperator: test_constants.currentOperator,
        ),
      );

      await tester.enterText(
        find.byKey(Key(ttd_keys.incidentBriefDescriptionField)),
        'todo',
      );
      await tester.enterText(
        find.byKey(Key(ttd_keys.incidentRequestField)),
        'more text',
      );
      await tester.tap(find.byKey(Key(ttd_keys.incidentSubmitButton)));
      await tester.pumpAndSettle();

      verify(bloc.add(
        IncidentSubmit(
          briefDescription: 'todo',
          request: 'more text',
        ),
      ));
    });
  });
}
