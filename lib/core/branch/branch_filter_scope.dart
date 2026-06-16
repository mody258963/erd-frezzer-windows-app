import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/user_model.dart';
import '../auth/auth_cubit.dart';
import 'branch_filter_cubit.dart';

/// Active `branch_id` for API calls (admin filter or user's assigned branch).
String? apiBranchIdFromContext(BuildContext context) {
  final user = context.read<AuthCubit>().state.user;
  return context.read<BranchFilterCubit>().apiBranchId(user);
}

String? apiBranchIdForUser(BuildContext context, UserModel? user) {
  return context.read<BranchFilterCubit>().apiBranchId(user);
}

/// Branch id required on create endpoints when admin has no filter but has an assigned branch.
String? requiredBranchIdFromContext(BuildContext context) {
  return apiBranchIdFromContext(context) ??
      context.read<AuthCubit>().state.user?.branchId;
}
