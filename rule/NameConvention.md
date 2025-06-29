# MGuard Name Convention
MGuard 프로젝트의 네이밍 컨벤션에 대한 문서입니다.

## 파일명
파일명은 다음과 같은 형식을 따릅니다.

```
1. [기능]_[타겟]_[역할].dart
2. [타겟]_[형태]_[역할].dart
```

이후 class 명은 파일명과 동일하지만 `snake_case`에서 `PascalCase`로 변경합니다.
함수명은 `lowerCamelCase`를 사용합니다.

``` dart

list_page.dart 

class ListPage extends StatelessWidget { ... }

void addList() { ... }

```

### 역할
파일의 역할에 맞춰 다음과 같은 접미사를 사용합니다.
- page => `[기능]_[타겟]_page.dart`
- widget => `[기능]_[타겟]_widget.dart`
- model => `[기능]_[타겟]_model.dart`
- bloc => `[기능]_[타겟]_bloc.dart`
- event => `[기능]_[타겟]_event.dart`
- state => `[기능]_[타겟]_state.dart`
- repository => `[기능]_[타겟]_repository.dart`
- item => `[타겟]_list_item.dart`

### 타겟
타겟은 보통 루트 폴더의 이름을 따라갑니다.
- event => `[기능]_event_bloc.dart`

### 기능
기능은 타겟에 진행하는 기능에 맞춰 접두사를 구성합니다.
- add => `add_alert_widget.dart`
- delete => `delete_alert_widget.dart`

### 형태
기능(동사)이 아닌 형태(명사 혹은 형용사)의 경우 타겟의 형태에 맞춰 접두사를 구성합니다. (이떄, 타겟이 잡두사가 될 수 있습니다.)
- list => `alert_list_page.dart`
- detail => `alert_detail_page.dart`

## ENUMS
ENUM은 소문자를 사용하여 구분합니다.

```dart
enum StatusCode { success, notFound, unAuthorized, badRequest, timeout, forbidden, error }
```

## Sealed Class
Sealed Class 의 경우 다음과 같은 형식을 따릅니다.

```dart
sealed class ErrorCode {
  final String code;
  final String message;
  final String? description;

  ErrorCode({required this.code, required this.message, required this.description});
}

class Er100 extends ErrorCode {
  Er100() : super(code: 'err100', message: 'STATE_NOT_MATCHED', description: '프로파일 상태와 권한 상태가 일치하지 않음');
}

class Er200 extends ErrorCode {
  Er200() : super(code: 'err200', message: 'PROFILE_NOT_FOUND', description: '권한은 제한되어있지만 프로파일을 찾을 수 없음');
}

class Er300 extends ErrorCode {
  Er300() : super(code: 'err300', message: 'PROFILE_NOT_FOUND', description: '권한은 허용되어있지만 프로파일을 찾을 수 없음');
}

class Er400 extends ErrorCode {
  Er400() : super(code: 'err400', message: 'NETWORK_ERROR', description: '인터넷이 연결되어있지 않음');
}

class Er500 extends ErrorCode {
  Er500() : super(code: 'err500', message: 'UNKNOWN_ERROR', description: '알 수 없는 에러');
}
```

## URL

api url의 경우 baseUrl을 포함하여 작성합니다.<br>
추가로 const 상수로 정의하여 사용합니다.

```dart
const homeUrl = '$serverUrl/home';
```



