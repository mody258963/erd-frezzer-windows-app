import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_cubit.dart';
import '../auth/role_permissions.dart';
import '../../data/models/user_role.dart';

extension RoleContext on BuildContext {
  UserRole get userRole =>
      read<AuthCubit>().state.user?.role ?? UserRole.salesperson;

  bool canPerform(AppAction action) =>
      RolePermissions.canPerform(action, userRole);
}
