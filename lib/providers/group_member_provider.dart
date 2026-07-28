import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/data/models/app_user_model.dart';
import 'package:flutter_expence_tracker/data/models/group_member_model.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class GroupMemberProvider extends ChangeNotifier {
  final GroupMemberRepository _memberRepository;
  final UserDirectoryRepository _userDirectoryRepository;
  final String ownerUid;
  final String groupId;

  GroupMemberProvider({
    required GroupMemberRepository memberRepository,
    required UserDirectoryRepository userDirectoryRepository,
    required this.ownerUid,
    required this.groupId,
  })  : _memberRepository = memberRepository,
        _userDirectoryRepository = userDirectoryRepository {
    _sub = _memberRepository.watchMembers(ownerUid, groupId).listen(
      (data) {
        _members = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Failed to load members';
        notifyListeners();
      },
    );
  }

  StreamSubscription<List<GroupMemberModel>>? _sub;

  List<GroupMemberModel> _members = [];
  List<GroupMemberModel> get members => _members;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _searching = false;
  bool get isSearching => _searching;

  bool _adding = false;
  bool get isAdding => _adding;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Searches the Firebase user directory by exact email match. Returns
  /// the found user, or null if no registered user has that email.
  Future<AppUserModel?> searchByEmail(String email) async {
    _searching = true;
    _errorMessage = null;
    notifyListeners();

    AppUserModel? found;
    await safeCall(
      () async => (await _userDirectoryRepository.findUserByEmail(email)).when(
        success: (user) {
          found = user;
          return true;
        },
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );

    _searching = false;
    notifyListeners();
    return found;
  }

  Future<bool> addMember(AppUserModel user) async {
    if (_members.any((m) => m.uid == user.uid)) {
      _errorMessage = 'That person is already in this group';
      notifyListeners();
      return false;
    }

    _adding = true;
    _errorMessage = null;
    notifyListeners();

    final member = GroupMemberModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      addedAt: DateTime.now(),
    );

    final success = await safeCall(
      () async => (await _memberRepository.addMember(ownerUid, groupId, member)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );

    _adding = false;
    notifyListeners();
    return success;
  }

  Future<bool> removeMember(String memberUid) async {
    final success = await safeCall(
      () async => (await _memberRepository.removeMember(ownerUid, groupId, memberUid)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );
    notifyListeners();
    return success;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
