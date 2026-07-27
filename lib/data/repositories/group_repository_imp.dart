import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/core/errors/failures.dart';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/group_model.dart';
import 'package:flutter_expence_tracker/data/services/firestore_service.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class GroupRepositoryImp implements GroupRepository {
  final FirestoreService _firestoreService;
  GroupRepositoryImp({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Stream<List<GroupModel>> watchGroups(String uid) {
    return _firestoreService
        .groupsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GroupModel.fromDoc).toList());
  }

  @override
  Future<Result<void>> addGroup(String uid, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return Result.failure(const ValidationFailure('Group name is required'));
    }
    try {
      await _firestoreService.groupsRef(uid).add(
        GroupModel(id: '', name: trimmed, createdAt: DateTime.now()).toMap(),
      );
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to create group'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to create group'));
    }
  }

  @override
  Future<Result<void>> deleteGroup(String uid, String groupId) async {
    try {
      await _firestoreService.groupsRef(uid).doc(groupId).delete();
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to delete group'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to delete group'));
    }
  }
}
