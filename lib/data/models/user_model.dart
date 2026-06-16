import 'dart:convert';

import 'package:logging/logging.dart';

import 'user_role.dart';

final _userLog = Logger('UserModel');

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.branchId,
    this.isActive = true,
    this.branchName,
    this.canSelectBranch = false,
    this.accessibleBranchIds,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? branchId;
  final bool isActive;
  final String? branchName;
  /// From `can_select_branch` — show branch picker (admin).
  final bool canSelectBranch;
  /// `null` = all branches (admin); otherwise only these UUIDs.
  final List<String>? accessibleBranchIds;

  /// Reads branch UUID from `branch_id` or nested `branch.id` (API may send either).
  static String? parseBranchId(Map<String, dynamic> json) {
    final top = json['branch_id'];
    if (top != null && top.toString().trim().isNotEmpty) {
      return top.toString();
    }
    final branch = json['branch'];
    if (branch is Map) {
      final id = branch['id'];
      if (id != null && id.toString().trim().isNotEmpty) {
        return id.toString();
      }
    }
    return null;
  }

  static String? parseBranchName(Map<String, dynamic> json) {
    final branch = json['branch'];
    if (branch is Map) {
      final name = branch['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        return name.toString();
      }
    }
    final flat = json['branch_name'];
    if (flat != null && flat.toString().trim().isNotEmpty) {
      return flat.toString();
    }
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final branchId = parseBranchId(json);
    final branchName = parseBranchName(json);

    if (json['branch_id'] == null && branchId != null) {
      _userLog.info(
        'Resolved branchId from nested branch.id=$branchId '
        '(top-level branch_id was null)',
      );
    } else if (branchId == null && json['branch'] != null) {
      _userLog.warning(
        'User ${json['id']} has branch object but no branch id: ${json['branch']}',
      );
    }

    return UserModel(
      id: '${json['id']}',
      name: '${json['name']}',
      email: '${json['email']}',
      role: UserRole.fromString('${json['role']}'),
      branchId: branchId,
      isActive: json['is_active'] as bool? ?? true,
      branchName: branchName,
      canSelectBranch: json['can_select_branch'] as bool? ?? false,
      accessibleBranchIds: _parseAccessibleBranchIds(json['accessible_branch_ids']),
    );
  }

  static List<String>? _parseAccessibleBranchIds(dynamic raw) {
    if (raw == null) return null;
    if (raw is! List) return null;
    final ids = raw.map((e) => '$e').where((s) => s.isNotEmpty).toList();
    return ids.isEmpty ? null : ids;
  }

  /// Branches the user may use in dropdowns (`null` = unrestricted).
  List<String>? get allowedBranchIdFilter => accessibleBranchIds;

  bool get isAdmin => role.name == 'admin';

  /// Non-admin users locked to [branchId]; branch picker must stay hidden.
  bool get isBranchLocked => !canSelectBranch && branchId != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'branch_id': branchId,
        'is_active': isActive,
        'can_select_branch': canSelectBranch,
        'accessible_branch_ids': accessibleBranchIds,
        if (branchName != null)
          'branch': {'id': branchId, 'name': branchName},
      };

  String toJsonString() => jsonEncode(toJson());

  static UserModel? fromJsonString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
