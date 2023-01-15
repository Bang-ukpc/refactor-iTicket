import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:iWarden/helpers/dio_helper.dart';
import 'package:iWarden/helpers/shared_preferences_helper.dart';
import 'package:iWarden/models/abort_pcn.dart';
import 'package:iWarden/models/contravention.dart';
import 'package:iWarden/models/pagination.dart';

class AbortController {
  static final dio = DioHelper.defaultApiClient;

  Future<List<CancellationReason>> getCancellationReasonList() async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.get(
          '/contravention/list-cancellation-reason',
        );
        List<dynamic> temp = response.data;
        List<CancellationReason> cancellationReasons =
            temp.map((model) => CancellationReason.fromJson(model)).toList();
        final String encodedData = json.encode(
          cancellationReasons.map((i) => CancellationReason.toJson(i)).toList(),
        );
        SharedPreferencesHelper.setStringValue(
            'cancellationReasonDataLocal', encodedData);
        return cancellationReasons;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? data = await SharedPreferencesHelper.getStringValue(
          'cancellationReasonDataLocal');
      if (data != null) {
        final List<CancellationReason> cancellationReasons =
            (json.decode(data) as List<dynamic>)
                .map<CancellationReason>(
                    (item) => CancellationReason.fromJson(item))
                .toList();
        return cancellationReasons;
      }
      return [];
    }
  }

  Future<void> abortPCN(AbortPCN abortPcn) async {
    ConnectivityResult connectionStatus =
        await (Connectivity().checkConnectivity());
    if (connectionStatus == ConnectivityResult.wifi ||
        connectionStatus == ConnectivityResult.mobile) {
      try {
        final response = await dio.post(
          '/contravention/abort-pcn',
          data: abortPcn.toJson(),
        );
        return response.data;
      } on DioError catch (error) {
        print(error.response);
        rethrow;
      }
    } else {
      final String? dataAbortPCN =
          await SharedPreferencesHelper.getStringValue('abortPCNDataLocal');
      final String? contraventionList =
          await SharedPreferencesHelper.getStringValue(
              'contraventionDataLocal');

      final String encodedNewData = json.encode(abortPcn.toJson());

      if (dataAbortPCN == null) {
        List<String> newData = [];
        newData.add(encodedNewData);
        if (contraventionList != null) {
          final contraventions =
              json.decode(contraventionList) as Map<String, dynamic>;
          Pagination fromJsonContravention =
              Pagination.fromJson(contraventions);
          var position = fromJsonContravention.rows
              .indexWhere((i) => i['Id'] == abortPcn.contraventionId);
          if (position != -1) {
            fromJsonContravention.rows[position]['Status'] =
                ContraventionStatus.Cancelled.index;
          }
          final String encodedDataList =
              json.encode(Pagination.toJson(fromJsonContravention));
          SharedPreferencesHelper.setStringValue(
              'contraventionDataLocal', encodedDataList);
        }
        final newVehicle = json.encode(newData);
        SharedPreferencesHelper.setStringValue('abortPCNDataLocal', newVehicle);
      } else {
        var createdData = json.decode(dataAbortPCN) as List<dynamic>;
        createdData.add(encodedNewData);
        if (contraventionList != null) {
          final contraventions =
              json.decode(contraventionList) as Map<String, dynamic>;
          Pagination fromJsonContravention =
              Pagination.fromJson(contraventions);
          var position = fromJsonContravention.rows
              .indexWhere((i) => i['Id'] == abortPcn.contraventionId);
          if (position != -1) {
            fromJsonContravention.rows[position]['Status'] =
                ContraventionStatus.Cancelled.index;
          }
          final String encodedDataList =
              json.encode(Pagination.toJson(fromJsonContravention));
          SharedPreferencesHelper.setStringValue(
              'contraventionDataLocal', encodedDataList);
        }
        final encodedCreatedData = json.encode(createdData);
        SharedPreferencesHelper.setStringValue(
            'abortPCNDataLocal', encodedCreatedData);
      }
      return;
    }
  }
}

final abortController = AbortController();
