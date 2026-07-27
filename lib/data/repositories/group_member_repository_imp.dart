import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_expence_tracker/core/errors/failures.dart';
import 'package:flutter_expence_tracker/core/utils/result.dart';
import 'package:flutter_expence_tracker/data/models/group_member_model.dart';
import 'package:flutter_expence_tracker/data/services/firestore_service.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class GroupMemberRepositoryImp implements GroupMemberRepository {
  final FirestoreService _firestoreService;
  GroupMemberRepositoryImp({required FirestoreService firestoreService}) : _firestoreService = firestoreService;

  @override
  Stream<List<GroupMemberModel>> watchMembers(String ownerUid, String groupId) {
    return _firestoreService
        .groupMembersRef(ownerUid, groupId)
        .orderBy('addedAt')
        .snapshots()
        .map((snap) => snap.docs.map(GroupMemberModel.fromDoc).toList());
  }

  @override
  Future<Result<void>> addMember(String ownerUid, String groupId, GroupMemberModel member) async {
    try {
      // Use the member's own uid as the document id so the same person
      // can't accidentally be added to the same group twice.
      await _firestoreService
          .groupMembersRef(ownerUid, groupId)
          .doc(member.uid)
          .set(member.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to add member'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to add member'));
    }
  }

  @override
  Future<Result<void>> removeMember(String ownerUid, String groupId, String memberUid) async {
    try {
      await _firestoreService.groupMembersRef(ownerUid, groupId).doc(memberUid).delete();
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(ServerFailure(e.message ?? 'Failed to remove member'));
    } catch (_) {
      return Result.failure(const UnknownFailure('Failed to remove member'));
    }
  }
}
