import 'package:equatable/equatable.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.isOnline = false,
    this.hasNetwork = false,
    this.checking = true,
  });

  final bool isOnline;
  final bool hasNetwork;
  final bool checking;

  ConnectivityState copyWith({
    bool? isOnline,
    bool? hasNetwork,
    bool? checking,
  }) {
    return ConnectivityState(
      isOnline: isOnline ?? this.isOnline,
      hasNetwork: hasNetwork ?? this.hasNetwork,
      checking: checking ?? this.checking,
    );
  }

  @override
  List<Object?> get props => [isOnline, hasNetwork, checking];
}
