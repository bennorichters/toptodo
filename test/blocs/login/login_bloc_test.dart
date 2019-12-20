import 'package:test/test.dart';

import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:toptodo/blocs/login/bloc.dart';
import 'package:toptodo_data/toptodo_data.dart';

class MockCredentialsProvider extends Mock implements CredentialsProvider {}

class MockSettingsProvider extends Mock implements SettingsProvider {}

class MockTopdeskProvider extends Mock implements TopdeskProvider {}

void main() {
  group('basic flow', () {
    blocTest<LoginBloc, LoginEvent, LoginState>(
      'emits [LoginWaitingForSavedDate] for initial state',
      build: () => LoginBloc(
        credentialsProvider: MockCredentialsProvider(),
        settingsProvider: MockSettingsProvider(),
        topdeskProvider: MockTopdeskProvider(),
      ),
      expect: <LoginState>[const LoginWaitingForSavedData()],
    );

    blocTest<LoginBloc, LoginEvent, LoginState>(
      '...',
      build: () => LoginBloc(
        credentialsProvider: MockCredentialsProvider(),
        settingsProvider: MockSettingsProvider(),
        topdeskProvider: MockTopdeskProvider(),
      ),
      act: (LoginBloc bloc) async => bloc.add(const RememberToggle(null, true)),
      expect: <LoginState>[
        const LoginWaitingForSavedData(),
        const RetrievedSavedData(null, true),
      ],
    );
  });

  group('TryLogin', () {
    const Branch branchA = Branch(id: 'a', name: 'A');
    const Branch branchB = Branch(id: 'b', name: 'B');
    const Caller callerA = Caller(
      id: 'a',
      name: 'CallerA',
      avatar: 'avatarA',
      branch: branchA,
    );
    const Caller callerB = Caller(
      id: 'b',
      name: 'CallerB',
      avatar: 'avatarB',
      branch: branchB,
    );
    const Category categoryA = Category(id: 'a', name: 'A');
    const Category categoryB = Category(id: 'b', name: 'B');
    const SubCategory subCategoryA = SubCategory(
      id: 'a',
      name: 'SubCatA',
      category: categoryA,
    );
    const SubCategory subCategoryB = SubCategory(
      id: 'b',
      name: 'SubCatB',
      category: categoryB,
    );
    const IncidentDuration durationA = IncidentDuration(id: 'a', name: 'A');
    const IncidentOperator operatorA = IncidentOperator(
      id: 'a',
      name: 'A',
      avatar: 'avatarOpA',
    );

    final TopdeskProvider tdp = MockTopdeskProvider();
    when(tdp.caller(id: 'a')).thenAnswer(
      (_) => Future<Caller>.value(callerA),
    );
    when(tdp.caller(id: 'b')).thenAnswer(
      (_) => Future<Caller>.value(
        const Caller(
          id: 'b',
          name: 'CallerB',
          avatar: 'avatarB',
          branch: branchB,
        ),
      ),
    );
    when(tdp.subCategory(id: 'a')).thenAnswer(
      (_) => Future<SubCategory>.value(subCategoryA),
    );
    when(tdp.subCategory(id: 'b')).thenAnswer(
      (_) => Future<SubCategory>.value(
        const SubCategory(id: 'b', name: 'SubCatB', category: categoryB),
      ),
    );

    const Credentials credentials = Credentials(
      url: 'a',
      loginName: 'userA',
      password: 'S3CrEt!',
    );

    Future<void> loginInvalidSettings(
        Settings saved, Settings incomplete) async {
      final SettingsProvider settingsProvider = MockSettingsProvider();

      final LoginBloc bloc = LoginBloc(
        credentialsProvider: MockCredentialsProvider(),
        settingsProvider: settingsProvider,
        topdeskProvider: tdp,
      );

      when(settingsProvider.provide()).thenAnswer(
        (_) => Future<Settings>.value(saved),
      );

      bloc.add(const TryLogin(credentials));

      await emitsExactly<LoginBloc, LoginState>(
        bloc,
        <LoginState>[
          const LoginWaitingForSavedData(),
          const LoginSubmitting(),
          LoginSuccessIncompleteSettings(
            topdeskProvider: tdp,
            settings: incomplete,
          ),
        ],
      );
    }

    test('valid settings', () async {
      final SettingsProvider settingsProvider = MockSettingsProvider();

      final LoginBloc bloc = LoginBloc(
        credentialsProvider: MockCredentialsProvider(),
        settingsProvider: settingsProvider,
        topdeskProvider: tdp,
      );

      const Settings settings = Settings(
        branch: branchA,
        caller: callerA,
        category: categoryA,
        subCategory: subCategoryA,
        incidentDuration: durationA,
        incidentOperator: operatorA,
      );
      when(settingsProvider.provide()).thenAnswer(
        (_) => Future<Settings>.value(settings),
      );

      bloc.add(const TryLogin(credentials));

      await emitsExactly<LoginBloc, LoginState>(
        bloc,
        <LoginState>[
          const LoginWaitingForSavedData(),
          const LoginSubmitting(),
          LoginSuccessValidSettings(
            topdeskProvider: tdp,
            settings: settings,
          ),
        ],
      );
    });

    test('incomplete settings', () async {
      await loginInvalidSettings(
        const Settings(
          branch: branchA,
          caller: callerA,
          category: categoryA,
          subCategory: subCategoryA,
          incidentDuration: durationA,
          incidentOperator: null,
        ),
        const Settings(
          branch: branchA,
          caller: callerA,
          category: categoryA,
          subCategory: subCategoryA,
          incidentDuration: durationA,
          incidentOperator: null,
        ),
      );
    });

    test('invalid settings caller belongs to other branch', () async {
      await loginInvalidSettings(
        const Settings(
          branch: branchA,
          caller: callerB,
          category: categoryA,
          subCategory: subCategoryA,
          incidentDuration: durationA,
          incidentOperator: operatorA,
        ),
        const Settings(
          branch: branchA,
          caller: null,
          category: categoryA,
          subCategory: subCategoryA,
          incidentDuration: durationA,
          incidentOperator: operatorA,
        ),
      );
    });

    test('invalid settings sub category belongs to other category', () async {
      await loginInvalidSettings(
        const Settings(
          branch: branchA,
          caller: callerA,
          category: categoryA,
          subCategory: subCategoryB,
          incidentDuration: durationA,
          incidentOperator: operatorA,
        ),
        const Settings(
          branch: branchA,
          caller: callerA,
          category: categoryA,
          subCategory: null,
          incidentDuration: durationA,
          incidentOperator: operatorA,
        ),
      );
    });

    test('incomplete and invalid settings', () async {
      await loginInvalidSettings(
        const Settings(
          branch: branchA,
          caller: callerB,
          category: categoryA,
          subCategory: subCategoryA,
          incidentDuration: durationA,
          incidentOperator: null,
        ),
        const Settings(
          branch: branchA,
          caller: null,
          category: categoryA,
          subCategory: subCategoryA,
          incidentDuration: durationA,
          incidentOperator: null,
        ),
      );
    });
  });
}
