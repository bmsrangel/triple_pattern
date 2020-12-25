import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:triple/triple.dart';

abstract class StreamStore<State extends Object, Error extends Object>
    extends Store<State, Error> {
  final _tripleController =
      StreamController<Triple<State, Error>>.broadcast(sync: true);

  late final Stream<State> selectState = _tripleController.stream
      .where((triple) => triple.event == TripleEvent.state)
      .map((triple) => triple.state);

  late final Stream<Error> selectError = _tripleController.stream
      .where((triple) => triple.event == TripleEvent.error)
      .where((triple) => triple.error != null)
      .map((triple) => triple.error!);

  late final Stream<bool> selectLoading = _tripleController.stream
      .where((triple) => triple.event == TripleEvent.loading)
      .map((triple) => triple.loading);

  StreamStore(State initialState, {int historyLimit = 256})
      : super(initialState, historyLimit: historyLimit);

  @protected
  @override
  void propagate(Triple<State, Error> _triple) {
    _tripleController.add(triple);
  }

  @override
  Future destroy() async {
    await _tripleController.close();
  }

  @override
  Disposer observer({
    void Function()? onState,
    void Function()? onLoading,
    void Function()? onError,
  }) {
    final _sub = _tripleController.stream.listen((triple) {
      if (triple.event == TripleEvent.state) {
        onState?.call();
      } else if (triple.event == TripleEvent.error) {
        onError?.call();
      } else if (triple.event == TripleEvent.loading) {
        onLoading?.call();
      }
    });

    return () async {
      await _sub.cancel();
    };
  }
}
