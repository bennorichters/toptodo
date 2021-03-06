import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:toptodo/blocs/init/bloc.dart';
import 'package:toptodo_data/toptodo_data.dart';

/// Business logic component that takes care of initializing the TOPtodo
/// application.
class InitBloc extends Bloc<InitEvent, InitState> {
  /// Creates an [InitBloc]
  InitBloc({
    @required this.credentialsProvider,
    @required this.topdeskProvider,
    @required this.settingsProvider,
  });

  /// The [CredentialsProvider]
  final CredentialsProvider credentialsProvider;

  /// The [TopdeskProvider]
  final TopdeskProvider topdeskProvider;

  /// The [SettingsProvider]
  final SettingsProvider settingsProvider;

  InitData _initData;

  @override
  InitState get initialState => const InitData.empty();

  @override
  Stream<InitState> mapEventToState(InitEvent event) async* {
    if (event is RequestInitData) {
      StreamController<InitState> controller;

      void addToController() async {
        final credentials = await credentialsProvider.provide();

        controller.add(_initData = InitData(credentials: credentials));
        if (credentials.isComplete()) {
          _finishLoadingData(controller, credentials);
        } else {
          await controller.close();
        }
      }

      controller = StreamController<InitState>(
        onListen: addToController,
      );

      yield* controller.stream;
    }
  }

  void _finishLoadingData(
    StreamController<InitState> controller,
    Credentials credentials,
  ) {
    settingsProvider.init(credentials.url, credentials.loginName);
    settingsProvider.provide().then((value) async {
      if (!controller.isClosed) {
        controller.add(
          _initData = _initData.update(updatedSettings: value),
        );
      }

      if (_initData.isReady()) {
        await controller.close();
      }
    });

    topdeskProvider
        .init(credentials)
        .then((_) => topdeskProvider.currentTdOperator())
        .then((tdOperator) async {
      controller.add(
        _initData = _initData.update(updatedCurrentOperator: tdOperator),
      );

      if (_initData.isReady()) {
        await controller.close();
      }
    }).catchError((e) async {
      controller.add(LoadingDataFailed(e, StackTrace.current));
      await controller.close();
    });
  }
}
