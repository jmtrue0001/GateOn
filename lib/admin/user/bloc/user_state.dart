part of 'user_bloc.dart';

@CopyWith()
class UserState extends CommonState {
  const UserState({
    super.status,
    super.errorMessage,
    super.filterType,
    super.hasReachedMax,
    super.orderType,
    super.page,
    super.query,
    super.meta,
    this.users = const [],
    this.userCount,
    this.detail = false,
    this.user,
    this.histories = const [],
    this.detailMeta,
    this.detailQuery,
  });

  final bool detail;
  final List<User> users;
  final UserCount? userCount;
  final User? user;
  final List<History> histories;
  final Meta? detailMeta;
  final String? detailQuery;

  @override
  List<Object?> get props => [...super.props, users, userCount, detail, user, histories, detailMeta, detailQuery];
}
