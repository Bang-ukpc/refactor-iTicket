import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';

class CheckBackgroundServiceStatusHelper {
  static Logger logger = Logger<CheckBackgroundServiceStatusHelper>();

  Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    var isBackgroundRunning = await service.isRunning();
    bool isSyncFuncActive = await SharedPreferencesHelper.getBoolValue(
            PreferencesKeys.isSyncFuncActive) ??
        false;
    if (!isBackgroundRunning) {
      logger.info('Background running is false');
      return false;
    } else {
      if (!isSyncFuncActive) {
        logger.info('Background running is true but sync function is inactive');
        return false;
      }
    }
    logger.info('Background running is true and sync function is active');
    return true;
  }
}

final checkBackgroundServiceStatusHelper = CheckBackgroundServiceStatusHelper();
