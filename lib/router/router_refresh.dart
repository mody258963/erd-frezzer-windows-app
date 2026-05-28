import 'package:flutter/foundation.dart';

import '../core/auth/auth_cubit.dart';
import '../core/connectivity/connectivity_cubit.dart';

class RouterRefresh extends ChangeNotifier {
  RouterRefresh(this._authCubit, this._connectivityCubit) {
    _authCubit.stream.listen((_) => notifyListeners());
    _connectivityCubit.stream.listen((_) => notifyListeners());
  }

  final AuthCubit _authCubit;
  final ConnectivityCubit _connectivityCubit;
}
