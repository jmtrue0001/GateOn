import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:stream_transform/stream_transform.dart';

const throttleDuration = Duration(milliseconds: 400);

mixin StreamTransform {
  EventTransformer<E> throttleDroppable<E>() {
    return (events, mapper) {
      return droppable<E>().call(events.throttle(throttleDuration), mapper);
    };
  }
}
