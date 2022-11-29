import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:iWarden/helpers/logging.dart';

final serviceURL = dotenv.get(
  'SERVICE_URL',
);

class DioHelper {
  static Dio get defaultApiClient => ApiClientBuilder()
      .ofUrl(serviceURL)
      .setDefaultHeader()
      .addInterceptor(Logging())
      .create();
}

class ApiClientBuilder {
  static const int defaultTimeout = 15000;

  Dio dio = Dio(BaseOptions(
      connectTimeout: defaultTimeout,
      receiveTimeout: defaultTimeout,
      sendTimeout: defaultTimeout));

  ApiClientBuilder addInterceptor(Interceptor interceptor) {
    dio.interceptors.add(interceptor);
    return this;
  }

  ApiClientBuilder ofUrl(String url) {
    dio.options.baseUrl = url;
    return this;
  }

  ApiClientBuilder setTimeout(int timeout) {
    dio.options.connectTimeout = timeout;
    dio.options.sendTimeout = timeout;
    dio.options.receiveTimeout = timeout;
    return this;
  }

  ApiClientBuilder setDefaultHeader() {
    // SharedPreferencesHelper.getStringValue(AuthProvider.JWT_KEY).then((value) {
    //   if (value != null) {
    //     jwt = value;
    //     dio.options.headers['content-Type'] = 'application/json';
    //     dio.options.headers["authorization"] = "Bearer $value";
    //     print("value $value");
    //   }
    //   return this;
    // });
    dio.options.headers['content-Type'] = 'application/json';
    dio.options.headers["authorization"] =
        "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IjJaUXBKM1VwYmpBWVhZR2FYRUpsOGxWMFRPSSJ9.eyJhdWQiOiI5ZTAyYzVlZi05ZmFkLTQ2ZTAtYWRjMy1lNjc0Zjc0Mjc5ODciLCJpc3MiOiJodHRwczovL2xvZ2luLm1pY3Jvc29mdG9ubGluZS5jb20vMGJhYmJhYjktMjU2MS00OGYwLWE1ZGUtMGI0YWM2NDczOTUxL3YyLjAiLCJpYXQiOjE2Njk2ODM1NDgsIm5iZiI6MTY2OTY4MzU0OCwiZXhwIjoxNjY5Njg3NDQ4LCJhaW8iOiJBVFFBeS84VEFBQUFybTI3Z052YjBPZUtSc2prRGZLS3pqMmQyQWFQME9CVVNZWkw5UlY4TTBnVlNPRnQ0SnNjcTVBVmRxZUpmV1c0IiwibmFtZSI6IkJhbmcgTmd1eWVuIiwibm9uY2UiOiI0NmIwN2QxMC1mNjY1LTRiNmYtYWE2YS01MDI1ZDE1ZDU0N2EiLCJvaWQiOiI4MmFhYmEyYy1mZWFmLTQ1ODMtYWQ0Yy04Y2U5YmQwNzZjZjUiLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJiYW5nLm5ndXllbkB1a3Bhcmtpbmdjb250cm9sLmNvbSIsInJoIjoiMC5BVjRBdWJxckMyRWw4RWlsM2d0S3hrYzVVZV9GQXA2dG4tQkdyY1BtZFBkQ2VZZGVBQ00uIiwic3ViIjoiNTdJY21vY0hVZ2ExUFZETlBSNEFDQUFKQV81eUZXcWxSUHVfLUVFUDlEUSIsInRpZCI6IjBiYWJiYWI5LTI1NjEtNDhmMC1hNWRlLTBiNGFjNjQ3Mzk1MSIsInV0aSI6Ink0cDdOWnJ6YmsyUU9oZzYxUEowQVEiLCJ2ZXIiOiIyLjAifQ.eurxO9wQoly7iv--HQdFDM05xPqy4W4RsIa7xJYINZmjigoigON9rzB3aEVYs2c_dSmSXyJPKpQ_rM9J9X96vbFslUO5CSBIeX-PWaCuc6xMYyZ6RcAmHmgK04jIxH7CY-5PeroSBrQHyc79AQ8fyKCpPe-BZrVREAJS65nUgQ39wCrWJSCxqIpT7KNm4RJKr0sMkLN0gWQg0L_L04s5TkUv2oLUfyN_BPFBlDqvvfIzcD9BN333epB9FMoT53ZRUH16Jw3tw1bblxDMkg3sthhoVMUF84yxs8napfHt_C-XcGaU-wUYN3IK-tIHCBkLtOD2HDaZMOU9i4p6nVzSBA";
    return this;
  }

  Dio create() {
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
    return dio;
  }
}

extension Builder on Dio {
  ApiClientBuilder newBuilder() {
    ApiClientBuilder builder = ApiClientBuilder();
    builder.dio = this;
    return builder;
  }
}
