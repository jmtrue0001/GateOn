part of 'splash_bloc.dart';

@CopyWith()
class SplashState extends CommonState {
  const SplashState({super.status = CommonStatus.initial, super.errorMessage, this.route});

  final String? route;

  @override
  List<Object?> get props => [...super.props, route];
}
