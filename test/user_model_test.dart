import 'package:erd_rezzer/data/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseBranchId from top-level branch_id', () {
    expect(
      UserModel.parseBranchId({'branch_id': 'uuid-1'}),
      'uuid-1',
    );
  });

  test('parseBranchId from nested branch.id when branch_id missing', () {
    expect(
      UserModel.parseBranchId({
        'branch': {'id': 'uuid-2', 'name': 'Main'},
      }),
      'uuid-2',
    );
  });

  test('fromJson sets branchId from nested branch', () {
    final user = UserModel.fromJson({
      'id': 'u1',
      'name': 'Test',
      'email': 'a@b.c',
      'role': 'salesperson',
      'branch': {'id': 'uuid-3', 'name': 'Store'},
    });
    expect(user.branchId, 'uuid-3');
    expect(user.branchName, 'Store');
  });
}
