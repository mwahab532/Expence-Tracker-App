import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_expence_tracker/core/utils/safe_call.dart';
import 'package:flutter_expence_tracker/data/models/group_model.dart';
import 'package:flutter_expence_tracker/domain/Repositries.dart';

class GroupProvider extends ChangeNotifier {
  final GroupRepository _groupRepository;
  final String uid;

  GroupProvider({required GroupRepository groupRepository, required this.uid})
      : _groupRepository = groupRepository {
    _subscribe();
  }

  void _subscribe() {
    _sub?.cancel();
    _isLoading = true;
    notifyListeners();
    _sub = _groupRepository.watchGroups(uid).listen(
      (data) {
        _groups = data;
        _isLoading = false;
        notifyListeners();
      },
      onError: (_) {
        _isLoading = false;
        _errorMessage = 'Failed to load groups';
        notifyListeners();
      },
    );
  }

  Future<void> refresh() async {
    _subscribe();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  StreamSubscription<List<GroupModel>>? _sub;

  List<GroupModel> _groups = [];
  List<GroupModel> get groups => _groups;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _saving = false;
  bool get isSaving => _saving;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> addGroup(String name) async {
    _saving = true;
    _errorMessage = null;
    notifyListeners();

    final success = await safeCall(
      () async => (await _groupRepository.addGroup(uid, name)).when(
        success: (_) => true,
        failure: (f) {
          _errorMessage = f.message;
          return false;
        },
      ),
      onError: (msg) => _errorMessage = msg,
    );

    _saving = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteGroup(String groupId) async {
    final success = await safeCall(
      () async => (await _groupRepository.deleteGroup(uid, groupId)).when(
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
