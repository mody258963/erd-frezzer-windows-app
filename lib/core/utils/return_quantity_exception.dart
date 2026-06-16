import 'package:dio/dio.dart';

class ReturnQuantityFailure {
  const ReturnQuantityFailure({
    required this.partId,
    required this.requested,
    required this.available,
    this.sold,
    this.alreadyReturned,
  });

  final String partId;
  final int requested;
  final int available;
  final int? sold;
  final int? alreadyReturned;

  factory ReturnQuantityFailure.fromJson(Map<String, dynamic> json) =>
      ReturnQuantityFailure(
        partId: json['part_id'] as String? ?? '',
        requested: (json['requested'] as num?)?.toInt() ?? 0,
        available: (json['available'] as num?)?.toInt() ?? 0,
        sold: (json['sold'] as num?)?.toInt(),
        alreadyReturned: (json['already_returned'] as num?)?.toInt(),
      );
}

class ReturnQuantityException implements Exception {
  ReturnQuantityException(this.failures, {this.message});

  final List<ReturnQuantityFailure> failures;
  final String? message;

  @override
  String toString() =>
      message ?? 'Return quantity exceeds what is available on this document.';
}

ReturnQuantityException? parseReturnQuantityException(DioException e) {
  if (e.response?.statusCode != 422) return null;
  final data = e.response?.data;
  if (data is! Map) return null;
  final failuresRaw = data['failures'];
  if (failuresRaw is! List || failuresRaw.isEmpty) return null;
  final failures = failuresRaw
      .whereType<Map>()
      .map((f) => ReturnQuantityFailure.fromJson(Map<String, dynamic>.from(f)))
      .toList();
  if (failures.isEmpty) return null;
  return ReturnQuantityException(
    failures,
    message: data['message']?.toString(),
  );
}
