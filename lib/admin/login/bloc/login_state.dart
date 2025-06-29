part of 'login_bloc.dart';

@CopyWith()
class LoginState extends CommonState {
  const LoginState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
  });

  @override
  List<Object?> get props => [...super.props];
}
