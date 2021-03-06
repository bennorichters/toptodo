import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:toptodo/blocs/td_model_search/bloc.dart';
import 'package:toptodo_data/toptodo_data.dart';

/// Business logic component for searching a [TdModel]
class TdModelSearchBloc extends Bloc<TdModelSearchEvent, TdModelSearchState> {
  /// Creates a new instance of [TdModelSearchBloc]
  TdModelSearchBloc({
    this.topdeskProvider,
    Duration debounceTime = const Duration(milliseconds: 500),
  }) : _debouncer = _Debouncer(duration: debounceTime);

  /// the topdesk provider
  final TopdeskProvider topdeskProvider;
  final _Debouncer _debouncer;

  @override
  TdModelSearchState get initialState => TdModelSearchInitialState();

  @override
  Stream<TdModelSearchState> mapEventToState(
    TdModelSearchEvent event,
  ) async* {
    StreamController<TdModelSearchState> controller;

    void addToController() async {
      if (event is NewSearch) {
        controller.add(initialState);
        await controller.close();
      } else if (event is SearchFinishedQuery) {
        controller.add(TdModelSearching());
        await controller.addStream(
          _queryBasedResults(searchInfo: event),
        );
        await controller.close();
      } else if (event is SearchIncompleteQuery) {
        controller.add(TdModelSearching());

        _debouncer.run(() async {
          await controller.addStream(
            _queryBasedResults(searchInfo: event),
          );
          await controller.close();
        });
      }
    }

    controller = StreamController<TdModelSearchState>(
      onListen: addToController,
    );
    yield* controller.stream;
  }

  Stream<TdModelSearchState> _queryBasedResults<T extends TdModel>(
      {SearchInfo searchInfo}) async* {
    if (searchInfo is SearchInfo<TdBranch>) {
      yield TdModelSearchResults<TdBranch>(
        await topdeskProvider.tdBranches(
          startsWith: searchInfo.query,
        ),
      );
    } else if (searchInfo is SearchInfo<TdCaller>) {
      yield TdModelSearchResults<TdCaller>(
        await topdeskProvider.tdCallers(
          tdBranch: searchInfo.linkedTo as TdBranch,
          startsWith: searchInfo.query,
        ),
      );
    } else if (searchInfo is SearchInfo<TdOperator>) {
      yield TdModelSearchResults<TdOperator>(
        await topdeskProvider.tdOperators(
          startsWith: searchInfo.query,
        ),
      );
    }
  }
}

class _Debouncer {
  _Debouncer({this.duration});

  final Duration duration;
  Timer _timer;

  void run(void Function() action) {
    _timer?.cancel();
    _timer = Timer(duration, action);
  }
}
