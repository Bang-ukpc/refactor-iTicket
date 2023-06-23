import 'package:iWarden/helpers/check_turn_on_net_work.dart';
import 'package:iWarden/helpers/logger.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:ntp/ntp.dart';

class NTPHelper {
  Logger logger = Logger<NTPHelper>();
  String keySharedPreferences = 'keyOffset';
  Future<int> getOffset() async {
    bool netWorkTurnOn = await checkTurnOnNetWork.turnOnWifiAndMobile();
    if (netWorkTurnOn) {
      int offset = 0;
      try {
        offset = await NTP.getNtpOffset(
          localTime: DateTime.now(),
          lookUpAddress: 'time.google.com',
          timeout: const Duration(seconds: 4),
        );
      } catch (e) {
        String offsetOffline = await SharedPreferencesHelper.getStringValue(
                keySharedPreferences) ??
            "0";
        offset = int.parse(offsetOffline);
      }
      SharedPreferencesHelper.setStringValue(
          keySharedPreferences, offset.toString());
      return offset;
    } else {
      String offsetOffline =
          await SharedPreferencesHelper.getStringValue(keySharedPreferences) ??
              "0";
      return int.parse(offsetOffline);
    }
  }

  getTimeNTP() async {
    int offset = await getOffset();
    logger.info("OFFSET $offset");
    DateTime now = DateTime.now();
    DateTime ntpTime = now.add(Duration(milliseconds: offset));
    logger.info("NTP $ntpTime");
    return ntpTime.toUtc();
  }
}

final ntpHelper = NTPHelper();
