# MGuard State Management
MGuard 프로젝트의 상태관리에 대한 문서입니다.

## Bloc

Bloc 의 경우 다음과 같은 코드를 기반으로 구성합니다.
```dart 
import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';

part 'example_event.dart';
part 'example_state.dart';
part 'generated/example_bloc.g.dart';

class ExampleBloc extends Bloc<CommonEvent, ExampleState> {
  ExampleBloc() : super(const ExampleState()) {
    on<Initial>(_onInitial);
    on<Loading>(_onLoading);
  }
  
  _onInitial(Initial event, Emitter<ExampleState> emit) {
    emit(state.copyWith(status: Status.initial));
  }
}
``` 
```dart
part of 'example_bloc.dart';

class ExampleEvent extends CommonEvent {
  const ExampleEvent();
}

class ListFetched extends ExampleEvent {
  const ListFetched();
}

/// 코드 커스텀시 이후 내용 추가
/// `CommonEvent`에서 상속받아 사용
/// 만약 커스텀할 필요가 없다면 `CommonEvent`만 사용
/// class 명에 on은 붙이지 않음
``` 

```dart
part of 'example_bloc.dart';

@CopyWith()
class EventState extends CommonState {
  const EventState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.meta,
    super.orderType,
    super.page,
    super.query,
    this.exmple,
    this.examples = const [],
  });

  final Example? example;
  final List<Example> examples;

  @override
  List<Object?> get props => [events, eventDetail, ...super.props];
}
```

### 유의사항
- bloc event 는 `CommonEvent`를 상속받아 사용합니다.
- bloc state 는 `CommonState`를 상속받아 사용합니다.
- copy_with_extension 을 사용하여 state 를 구성합니다.
- bloc 의 event 할당은 순서에 맞게 작성합니다.

