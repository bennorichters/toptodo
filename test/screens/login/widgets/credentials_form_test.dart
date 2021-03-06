import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:toptodo/constants/keys.dart' as ttd_keys;

import 'package:toptodo_data/toptodo_data.dart';

import 'package:toptodo/blocs/login/bloc.dart';
import 'package:toptodo/screens/login/widgets/credentials_form.dart';

import '../../../test_helper.dart';
import '../../../test_constants.dart' as test_constants;

class MockLoginBloc extends MockBloc<LoginEvent, LoginState>
    implements LoginBloc {}

void main() {
  group('CredentialsForm', () {
    LoginBloc bloc;

    setUp(() {
      bloc = MockLoginBloc();
    });

    tearDown(() {
      bloc.close();
    });

    void pumpForm(
      WidgetTester tester, {
      Credentials credentials,
      bool remember,
    }) async {
      await tester.pumpWidget(
        TestableWidgetWithMediaQuery(
          child: BlocProvider.value(
            value: bloc,
            child: CredentialsForm.withSavedDate(
              credentials,
              remember,
            ),
          ),
        ),
      );
    }

    testWidgets('dont remember', (WidgetTester tester) async {
      when(bloc.state).thenReturn(AwaitingCredentials());

      await pumpForm(
        tester,
        credentials: Credentials(),
        remember: false,
      );

      final remember = find.byKey(
        Key(ttd_keys.credentialsFormRememberCheckbox),
      );

      expect(tester.widget<Checkbox>(remember).value, false);
    });

    testWidgets('do remember', (WidgetTester tester) async {
      when(bloc.state).thenReturn(AwaitingCredentials());

      await pumpForm(
        tester,
        credentials: Credentials(),
        remember: true,
      );

      final remember = find.byKey(
        Key(ttd_keys.credentialsFormRememberCheckbox),
      );

      expect(tester.widget<Checkbox>(remember).value, true);
    });

    testWidgets('toggle remember', (WidgetTester tester) async {
      when(bloc.state).thenReturn(AwaitingCredentials());

      await pumpForm(
        tester,
        credentials: Credentials(),
        remember: true,
      );

      final remember = find.byKey(
        Key(ttd_keys.credentialsFormRememberCheckbox),
      );
      await tester.tap(remember);

      verify(bloc.add(RememberToggle(Credentials()))).called(1);
    });

    testWidgets('press button', (WidgetTester tester) async {
      when(bloc.state).thenReturn(AwaitingCredentials());

      await pumpForm(
        tester,
        credentials: test_constants.credentials,
        remember: true,
      );

      final button = find.byKey(
        Key(ttd_keys.credentialsFormLoginButton),
      );

      await tester.tap(button);

      verify(bloc.add(TryLogin(test_constants.credentials))).called(1);
    });
  });
}
