import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/models/wardens.dart';
import 'package:iWarden/services/cache/user_cached_service.dart';

class UserInfo {
  static final logger = Logger<UserInfo>();
  Wardens? _user;
  final UserCachedService userCachedService;

  UserInfo(this.userCachedService);

  bool get isStsUser {
    if (_user != null) {
      return _user!.wardenType == WardenType.sts.index;
    }
    return false;
  }

  Wardens? get user {
    return _user;
  }

  Future<void> setUser() async {
    try {
      var user = await userCachedService.get();
      if (user != null) {
        _user = user;
      }
    } catch (e) {
      logger.error('[ERROR] $e');
    }
  }
}

final userCachedService = UserCachedService();
final userInfo = UserInfo(userCachedService);
