import 'dart:io';

import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/configs/configs.dart';
import 'package:iWarden/helpers/logging.dart';

class DioHelper {
  static Dio get defaultApiClient => ApiClientBuilder()
      .ofUrl(ConfigEnvironmentVariable.serviceURL)
      .addInterceptor(Logging())
      .create();
}

class ApiClientBuilder {
  static const int defaultTimeout = 60 * 1000;

  Dio dio = Dio(
    BaseOptions(
        connectTimeout: defaultTimeout,
        receiveTimeout: defaultTimeout,
        sendTimeout: defaultTimeout),
  );

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
