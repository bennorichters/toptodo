import 'package:test/test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:toptodo/blocs/login/bloc.dart';
import 'package:toptodo_data/toptodo_data.dart';

import '../../test_constants.dart' as test_constants;

class MockCredentialsProvider extends Mock implements CredentialsProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

class MockTopdeskProvider extends Mock implements TopdeskProvider {}

void main() {
  group('login bloc', () {
    CredentialsProvider withoutCredentials = MockCredentialsProvider();
    when(withoutCredentials.provide())
        .thenAnswer((_) => Future.value(Credentials()));

    CredentialsProvider withCredentials = MockCredentialsProvider();
    when(withCredentials.provide())
        .thenAnswer((_) => Future.value(test_constants.credentials));

    group('basic flow', () {
      blocTest<LoginBloc, LoginEvent, LoginState>(
        'emits [LoginWaitingForSavedDate] for initial state',
        build: () => LoginBloc(
          credentialsProvider: withoutCredentials,
          settingsProvider: MockSettingsProvider(),
          topdeskProvider: MockTopdeskProvider(),
        ),
        expect: [AwaitingCredentials()],
      );

      blocTest<LoginBloc, LoginEvent, LoginState>(
        'CredentialsInit - no data - dont remember '
        'user has to explicitly give consent to remember',
        build: () => LoginBloc(
          credentialsProvider: withoutCredentials,
          settingsProvider: MockSettingsProvider(),
          topdeskProvider: MockTopdeskProvider(),
        ),
        act: (LoginBloc bloc) async => bloc.add(CredentialsInit()),
        expect: [
          AwaitingCredentials(),
          RetrievedCredentials(Credentials(), false),
        ],
      );

      blocTest<LoginBloc, LoginEvent, LoginState>(
        'CredentialsInit - with data - remember '
        'user in the past has given explicit consent to remember',
        build: () => LoginBloc(
          credentialsProvider: withCredentials,
          settingsProvider: MockSettingsProvider(),
          topdeskProvider: MockTopdeskProvider(),
        ),
        act: (LoginBloc bloc) async => bloc.add(CredentialsInit()),
        expect: [
          AwaitingCredentials(),
          RetrievedCredentials(test_constants.credentials, true),
        ],
      );

      blocTest<LoginBloc, LoginEvent, LoginState>(
        'toggle remember',
        build: () => LoginBloc(
          credentialsProvider: withoutCredentials,
          settingsProvider: MockSettingsProvider(),
          topdeskProvider: MockTopdeskProvider(),
        ),
        act: (LoginBloc bloc) async => bloc.add(
          RememberToggle(test_constants.credentials),
        ),
        expect: [
          AwaitingCredentials(),
          RetrievedCredentials(test_constants.credentials, true),
        ],
      );

      test('toggle remember to false deletes credentials', () async {
        final TopdeskProvider topdeskProvider = MockTopdeskProvider();
        final SettingsProvider settingsProvider = MockSettingsProvider();

        final bloc = LoginBloc(
          credentialsProvider: withCredentials,
          settingsProvider: settingsProvider,
          topdeskProvider: topdeskProvider,
        );

        bloc.add(CredentialsInit());

        bloc.add(RememberToggle(test_constants.credentials));

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            RetrievedCredentials(test_constants.credentials, true),
            RetrievedCredentials(test_constants.credentials, false),
          ],
        );

        verify(withCredentials.delete()).called(1);
      });

      test('log out', () async {
        final TopdeskProvider topdeskProvider = MockTopdeskProvider();
        final SettingsProvider settingsProvider = MockSettingsProvider();

        final bloc = LoginBloc(
          credentialsProvider: withCredentials,
          settingsProvider: settingsProvider,
          topdeskProvider: topdeskProvider,
        );

        bloc.add(CredentialsInit());
        bloc.add(LogOut());

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            RetrievedCredentials(test_constants.credentials, true),
            AwaitingCredentials(),
            RetrievedCredentials(Credentials(), false),
          ],
        );

        verify(withCredentials.delete()).called(1);
      });

      test(
          'remember flag true when entering loginscreen with saved credentials',
          () async {
        final TopdeskProvider topdeskProvider = MockTopdeskProvider();
        final SettingsProvider settingsProvider = MockSettingsProvider();

        final bloc = LoginBloc(
          credentialsProvider: withCredentials,
          settingsProvider: settingsProvider,
          topdeskProvider: topdeskProvider,
        );

        bloc.add(CredentialsInit());

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            RetrievedCredentials(test_constants.credentials, true)
          ],
        );
      });
    });

    group('TryLogin', () {
      final topdeskProvider = MockTopdeskProvider();
      final SettingsProvider completeSettings = MockSettingsProvider();

      when(completeSettings.provide()).thenAnswer(
        (_) => Future<Settings>.value(test_constants.settings),
      );

      test(
          'valid settings - no prior credentials '
          'no consent to remember - dont save', () async {
        final bloc = LoginBloc(
          credentialsProvider: withoutCredentials,
          settingsProvider: completeSettings,
          topdeskProvider: topdeskProvider,
        );

        bloc.add(CredentialsInit());
        bloc.add(TryLogin(test_constants.credentials));

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            RetrievedCredentials(Credentials(), false),
            LoginSubmitting(),
            LoginSuccess(
              settings: test_constants.settings,
            ),
          ],
        );

        verifyNever(withCredentials.save(any));
      });

      test(
          'valid settings - no prior credentials '
          'toggled to remember - save', () async {
        final bloc = LoginBloc(
          credentialsProvider: withoutCredentials,
          settingsProvider: completeSettings,
          topdeskProvider: topdeskProvider,
        );

        bloc.add(CredentialsInit()); // Make sure `remember` will be true
        bloc.add(RememberToggle(test_constants.credentials));
        bloc.add(TryLogin(test_constants.credentials));

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            RetrievedCredentials(Credentials(), false),
            RetrievedCredentials(test_constants.credentials, true),
            LoginSubmitting(),
            LoginSuccess(
              settings: test_constants.settings,
            ),
          ],
        );

        verify(withoutCredentials.save(test_constants.credentials)).called(1);
      });

      test('fix credentials', () async {
        final bloc = LoginBloc(
          credentialsProvider: withCredentials,
          settingsProvider: completeSettings,
          topdeskProvider: topdeskProvider,
        );

        bloc.add(CredentialsInit()); // Make sure `remember` will be true
        final original = Credentials(
          url: 'a.b///',
          loginName: 'a',
          password: 'a',
        );

        final fixed = Credentials(
          url: 'https://a.b',
          loginName: 'a',
          password: 'a',
        );

        bloc.add(TryLogin(original));

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            RetrievedCredentials(test_constants.credentials, true),
            LoginSubmitting(),
            LoginSuccess(settings: test_constants.settings),
          ],
        );

        verify(withCredentials.save(fixed)).called(1);
      });

      test('incomplete settings', () async {
        final saved = Settings(
          tdBranchId: 'a',
          tdCallerId: 'a',
          tdCategoryId: 'a',
          tdSubcategoryId: 'a',
          tdDurationId: 'a',
          tdOperatorId: null,
        );

        final incomplete = Settings(
          tdBranchId: 'a',
          tdCallerId: 'a',
          tdCategoryId: 'a',
          tdSubcategoryId: 'a',
          tdDurationId: 'a',
          tdOperatorId: null,
        );

        final TopdeskProvider topdeskProvider = MockTopdeskProvider();
        final SettingsProvider settingsProvider = MockSettingsProvider();

        final bloc = LoginBloc(
          credentialsProvider: MockCredentialsProvider(),
          settingsProvider: settingsProvider,
          topdeskProvider: topdeskProvider,
        );

        when(settingsProvider.provide()).thenAnswer(
          (_) => Future<Settings>.value(saved),
        );

        bloc.add(TryLogin(test_constants.credentials));

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            LoginSubmitting(),
            LoginSuccess(settings: incomplete),
          ],
        );
      });
    });

    group('TryLogin errors', () {
      Future<void> testException(Exception e) async {
        final topdeskProvider = MockTopdeskProvider();
        when(topdeskProvider.currentTdOperator()).thenThrow(e);

        final bloc = LoginBloc(
          credentialsProvider: MockCredentialsProvider(),
          settingsProvider: MockSettingsProvider(),
          topdeskProvider: topdeskProvider,
        );

        bloc.add(TryLogin(test_constants.credentials));

        await emitsExactly<LoginBloc, LoginState>(
          bloc,
          [
            AwaitingCredentials(),
            LoginSubmitting(),
            isA<LoginFailed>(),
          ],
        );
      }

      test('not authorized', () async {
        await testException(TdNotAuthorizedException(''));
      });

      test('time out', () async {
        await testException(const TdTimeOutException(''));
      });

      test('time out', () async {
        await testException(const TdServerException(''));
      });
    });

    group('equals', () {
      test('CredentialsInit', () {
        expect(CredentialsInit() == CredentialsInit(), isTrue);
        expect(
            RememberToggle(test_constants.credentials) ==
                RememberToggle(test_constants.credentials),
            isTrue);
        expect(
            TryLogin(test_constants.credentials) ==
                TryLogin(test_constants.credentials),
            isTrue);
      });
    });

    group('toString', () {
      test('CredentialsInit', () {
        expect(CredentialsInit() == CredentialsInit(), isTrue);
        expect(
          RememberToggle(test_constants.credentials) ==
              RememberToggle(test_constants.credentials),
          isTrue,
        );
        expect(
            TryLogin(test_constants.credentials) ==
                TryLogin(test_constants.credentials),
            isTrue);
        expect(
          LoginFailed(
                savedData: test_constants.credentials,
                remember: true,
                cause: 1,
                stackTrace: null,
              ) ==
              LoginFailed(
                savedData: test_constants.credentials,
                remember: true,
                cause: 1,
                stackTrace: null,
              ),
          isTrue,
        );
      });
    });

    group('toString', () {
      test('WithSavedData', () {
        expect(
          RetrievedCredentials(Credentials(), true).toString().contains('true'),
          isTrue,
        );
      });
    });
  });
}
