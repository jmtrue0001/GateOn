import 'package:bloc/bloc.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    FirebaseCrashlytics.instance.log('[BLoC] ${bloc.runtimeType}: ${event.runtimeType}');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: '${bloc.runtimeType} onError',
      fatal: false,
    );
    FirebaseAnalytics.instance.logEvent(
      name: 'bloc_error',
      parameters: {
        'bloc': bloc.runtimeType.toString(),
        'error': error.toString().substring(0, error.toString().length.clamp(0, 100)),
      },
    );
  }
}
