// This file is automatically generated, so please do not edit it.
// Generated by `flutter_rust_bridge`@ 2.0.0-dev.28.

// ignore_for_file: unused_import, unused_element, unnecessary_import, duplicate_ignore, invalid_use_of_internal_member, annotate_overrides, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_const_literals_to_create_immutables, unused_field

import 'api.dart';
import 'dart:async';
import 'dart:convert';
import 'frb_generated.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated_web.dart';

abstract class RustLibApiImplPlatform extends BaseApiImpl<RustLibWire> {
  RustLibApiImplPlatform({
    required super.handler,
    required super.wire,
    required super.generalizedFrbRustBinding,
    required super.portManager,
  });

  @protected
  AnyhowException dco_decode_AnyhowException(dynamic raw);

  @protected
  String dco_decode_String(dynamic raw);

  @protected
  AddOrUpdatePortalStation dco_decode_add_or_update_portal_station(dynamic raw);

  @protected
  Authenticated dco_decode_authenticated(dynamic raw);

  @protected
  BatteryInfo dco_decode_battery_info(dynamic raw);

  @protected
  bool dco_decode_bool(dynamic raw);

  @protected
  AddOrUpdatePortalStation dco_decode_box_autoadd_add_or_update_portal_station(
      dynamic raw);

  @protected
  DeployConfig dco_decode_box_autoadd_deploy_config(dynamic raw);

  @protected
  DeploymentConfig dco_decode_box_autoadd_deployment_config(dynamic raw);

  @protected
  DownloadProgress dco_decode_box_autoadd_download_progress(dynamic raw);

  @protected
  EphemeralConfig dco_decode_box_autoadd_ephemeral_config(dynamic raw);

  @protected
  FirmwareDownloadStatus dco_decode_box_autoadd_firmware_download_status(
      dynamic raw);

  @protected
  LocalFirmware dco_decode_box_autoadd_local_firmware(dynamic raw);

  @protected
  LoraConfig dco_decode_box_autoadd_lora_config(dynamic raw);

  @protected
  LoraTransmissionConfig dco_decode_box_autoadd_lora_transmission_config(
      dynamic raw);

  @protected
  Schedule dco_decode_box_autoadd_schedule(dynamic raw);

  @protected
  SensorValue dco_decode_box_autoadd_sensor_value(dynamic raw);

  @protected
  StationConfig dco_decode_box_autoadd_station_config(dynamic raw);

  @protected
  Tokens dco_decode_box_autoadd_tokens(dynamic raw);

  @protected
  TransferProgress dco_decode_box_autoadd_transfer_progress(dynamic raw);

  @protected
  TransmissionConfig dco_decode_box_autoadd_transmission_config(dynamic raw);

  @protected
  int dco_decode_box_autoadd_u_32(dynamic raw);

  @protected
  int dco_decode_box_autoadd_u_64(dynamic raw);

  @protected
  UpgradeProgress dco_decode_box_autoadd_upgrade_progress(dynamic raw);

  @protected
  UploadProgress dco_decode_box_autoadd_upload_progress(dynamic raw);

  @protected
  WifiNetworksConfig dco_decode_box_autoadd_wifi_networks_config(dynamic raw);

  @protected
  WifiTransmissionConfig dco_decode_box_autoadd_wifi_transmission_config(
      dynamic raw);

  @protected
  DeployConfig dco_decode_deploy_config(dynamic raw);

  @protected
  DeploymentConfig dco_decode_deployment_config(dynamic raw);

  @protected
  DeviceCapabilities dco_decode_device_capabilities(dynamic raw);

  @protected
  DomainMessage dco_decode_domain_message(dynamic raw);

  @protected
  DownloadProgress dco_decode_download_progress(dynamic raw);

  @protected
  EphemeralConfig dco_decode_ephemeral_config(dynamic raw);

  @protected
  double dco_decode_f_32(dynamic raw);

  @protected
  FirmwareDownloadStatus dco_decode_firmware_download_status(dynamic raw);

  @protected
  FirmwareInfo dco_decode_firmware_info(dynamic raw);

  @protected
  int dco_decode_i_32(dynamic raw);

  @protected
  int dco_decode_i_64(dynamic raw);

  @protected
  List<LocalFirmware> dco_decode_list_local_firmware(dynamic raw);

  @protected
  List<ModuleConfig> dco_decode_list_module_config(dynamic raw);

  @protected
  List<NearbyStation> dco_decode_list_nearby_station(dynamic raw);

  @protected
  List<NetworkConfig> dco_decode_list_network_config(dynamic raw);

  @protected
  List<int> dco_decode_list_prim_u_8_loose(dynamic raw);

  @protected
  Uint8List dco_decode_list_prim_u_8_strict(dynamic raw);

  @protected
  List<RecordArchive> dco_decode_list_record_archive(dynamic raw);

  @protected
  List<SensorConfig> dco_decode_list_sensor_config(dynamic raw);

  @protected
  List<StationConfig> dco_decode_list_station_config(dynamic raw);

  @protected
  List<WifiNetworkConfig> dco_decode_list_wifi_network_config(dynamic raw);

  @protected
  LocalFirmware dco_decode_local_firmware(dynamic raw);

  @protected
  LoraBand dco_decode_lora_band(dynamic raw);

  @protected
  LoraConfig dco_decode_lora_config(dynamic raw);

  @protected
  LoraTransmissionConfig dco_decode_lora_transmission_config(dynamic raw);

  @protected
  ModuleConfig dco_decode_module_config(dynamic raw);

  @protected
  NearbyStation dco_decode_nearby_station(dynamic raw);

  @protected
  NetworkConfig dco_decode_network_config(dynamic raw);

  @protected
  String? dco_decode_opt_String(dynamic raw);

  @protected
  DeploymentConfig? dco_decode_opt_box_autoadd_deployment_config(dynamic raw);

  @protected
  EphemeralConfig? dco_decode_opt_box_autoadd_ephemeral_config(dynamic raw);

  @protected
  LoraConfig? dco_decode_opt_box_autoadd_lora_config(dynamic raw);

  @protected
  Schedule? dco_decode_opt_box_autoadd_schedule(dynamic raw);

  @protected
  SensorValue? dco_decode_opt_box_autoadd_sensor_value(dynamic raw);

  @protected
  Tokens? dco_decode_opt_box_autoadd_tokens(dynamic raw);

  @protected
  TransmissionConfig? dco_decode_opt_box_autoadd_transmission_config(
      dynamic raw);

  @protected
  int? dco_decode_opt_box_autoadd_u_32(dynamic raw);

  @protected
  int? dco_decode_opt_box_autoadd_u_64(dynamic raw);

  @protected
  Uint8List? dco_decode_opt_list_prim_u_8_strict(dynamic raw);

  @protected
  PortalError dco_decode_portal_error(dynamic raw);

  @protected
  RecordArchive dco_decode_record_archive(dynamic raw);

  @protected
  Registered dco_decode_registered(dynamic raw);

  @protected
  Schedule dco_decode_schedule(dynamic raw);

  @protected
  SensorConfig dco_decode_sensor_config(dynamic raw);

  @protected
  SensorValue dco_decode_sensor_value(dynamic raw);

  @protected
  SolarInfo dco_decode_solar_info(dynamic raw);

  @protected
  StationConfig dco_decode_station_config(dynamic raw);

  @protected
  StreamInfo dco_decode_stream_info(dynamic raw);

  @protected
  Tokens dco_decode_tokens(dynamic raw);

  @protected
  TransferProgress dco_decode_transfer_progress(dynamic raw);

  @protected
  TransferStatus dco_decode_transfer_status(dynamic raw);

  @protected
  TransmissionConfig dco_decode_transmission_config(dynamic raw);

  @protected
  TransmissionToken dco_decode_transmission_token(dynamic raw);

  @protected
  int dco_decode_u_32(dynamic raw);

  @protected
  int dco_decode_u_64(dynamic raw);

  @protected
  int dco_decode_u_8(dynamic raw);

  @protected
  void dco_decode_unit(dynamic raw);

  @protected
  UpgradeProgress dco_decode_upgrade_progress(dynamic raw);

  @protected
  UpgradeStatus dco_decode_upgrade_status(dynamic raw);

  @protected
  UploadProgress dco_decode_upload_progress(dynamic raw);

  @protected
  int dco_decode_usize(dynamic raw);

  @protected
  UtcDateTime dco_decode_utc_date_time(dynamic raw);

  @protected
  WifiNetworkConfig dco_decode_wifi_network_config(dynamic raw);

  @protected
  WifiNetworksConfig dco_decode_wifi_networks_config(dynamic raw);

  @protected
  WifiTransmissionConfig dco_decode_wifi_transmission_config(dynamic raw);

  @protected
  AnyhowException sse_decode_AnyhowException(SseDeserializer deserializer);

  @protected
  String sse_decode_String(SseDeserializer deserializer);

  @protected
  AddOrUpdatePortalStation sse_decode_add_or_update_portal_station(
      SseDeserializer deserializer);

  @protected
  Authenticated sse_decode_authenticated(SseDeserializer deserializer);

  @protected
  BatteryInfo sse_decode_battery_info(SseDeserializer deserializer);

  @protected
  bool sse_decode_bool(SseDeserializer deserializer);

  @protected
  AddOrUpdatePortalStation sse_decode_box_autoadd_add_or_update_portal_station(
      SseDeserializer deserializer);

  @protected
  DeployConfig sse_decode_box_autoadd_deploy_config(
      SseDeserializer deserializer);

  @protected
  DeploymentConfig sse_decode_box_autoadd_deployment_config(
      SseDeserializer deserializer);

  @protected
  DownloadProgress sse_decode_box_autoadd_download_progress(
      SseDeserializer deserializer);

  @protected
  EphemeralConfig sse_decode_box_autoadd_ephemeral_config(
      SseDeserializer deserializer);

  @protected
  FirmwareDownloadStatus sse_decode_box_autoadd_firmware_download_status(
      SseDeserializer deserializer);

  @protected
  LocalFirmware sse_decode_box_autoadd_local_firmware(
      SseDeserializer deserializer);

  @protected
  LoraConfig sse_decode_box_autoadd_lora_config(SseDeserializer deserializer);

  @protected
  LoraTransmissionConfig sse_decode_box_autoadd_lora_transmission_config(
      SseDeserializer deserializer);

  @protected
  Schedule sse_decode_box_autoadd_schedule(SseDeserializer deserializer);

  @protected
  SensorValue sse_decode_box_autoadd_sensor_value(SseDeserializer deserializer);

  @protected
  StationConfig sse_decode_box_autoadd_station_config(
      SseDeserializer deserializer);

  @protected
  Tokens sse_decode_box_autoadd_tokens(SseDeserializer deserializer);

  @protected
  TransferProgress sse_decode_box_autoadd_transfer_progress(
      SseDeserializer deserializer);

  @protected
  TransmissionConfig sse_decode_box_autoadd_transmission_config(
      SseDeserializer deserializer);

  @protected
  int sse_decode_box_autoadd_u_32(SseDeserializer deserializer);

  @protected
  int sse_decode_box_autoadd_u_64(SseDeserializer deserializer);

  @protected
  UpgradeProgress sse_decode_box_autoadd_upgrade_progress(
      SseDeserializer deserializer);

  @protected
  UploadProgress sse_decode_box_autoadd_upload_progress(
      SseDeserializer deserializer);

  @protected
  WifiNetworksConfig sse_decode_box_autoadd_wifi_networks_config(
      SseDeserializer deserializer);

  @protected
  WifiTransmissionConfig sse_decode_box_autoadd_wifi_transmission_config(
      SseDeserializer deserializer);

  @protected
  DeployConfig sse_decode_deploy_config(SseDeserializer deserializer);

  @protected
  DeploymentConfig sse_decode_deployment_config(SseDeserializer deserializer);

  @protected
  DeviceCapabilities sse_decode_device_capabilities(
      SseDeserializer deserializer);

  @protected
  DomainMessage sse_decode_domain_message(SseDeserializer deserializer);

  @protected
  DownloadProgress sse_decode_download_progress(SseDeserializer deserializer);

  @protected
  EphemeralConfig sse_decode_ephemeral_config(SseDeserializer deserializer);

  @protected
  double sse_decode_f_32(SseDeserializer deserializer);

  @protected
  FirmwareDownloadStatus sse_decode_firmware_download_status(
      SseDeserializer deserializer);

  @protected
  FirmwareInfo sse_decode_firmware_info(SseDeserializer deserializer);

  @protected
  int sse_decode_i_32(SseDeserializer deserializer);

  @protected
  int sse_decode_i_64(SseDeserializer deserializer);

  @protected
  List<LocalFirmware> sse_decode_list_local_firmware(
      SseDeserializer deserializer);

  @protected
  List<ModuleConfig> sse_decode_list_module_config(
      SseDeserializer deserializer);

  @protected
  List<NearbyStation> sse_decode_list_nearby_station(
      SseDeserializer deserializer);

  @protected
  List<NetworkConfig> sse_decode_list_network_config(
      SseDeserializer deserializer);

  @protected
  List<int> sse_decode_list_prim_u_8_loose(SseDeserializer deserializer);

  @protected
  Uint8List sse_decode_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  List<RecordArchive> sse_decode_list_record_archive(
      SseDeserializer deserializer);

  @protected
  List<SensorConfig> sse_decode_list_sensor_config(
      SseDeserializer deserializer);

  @protected
  List<StationConfig> sse_decode_list_station_config(
      SseDeserializer deserializer);

  @protected
  List<WifiNetworkConfig> sse_decode_list_wifi_network_config(
      SseDeserializer deserializer);

  @protected
  LocalFirmware sse_decode_local_firmware(SseDeserializer deserializer);

  @protected
  LoraBand sse_decode_lora_band(SseDeserializer deserializer);

  @protected
  LoraConfig sse_decode_lora_config(SseDeserializer deserializer);

  @protected
  LoraTransmissionConfig sse_decode_lora_transmission_config(
      SseDeserializer deserializer);

  @protected
  ModuleConfig sse_decode_module_config(SseDeserializer deserializer);

  @protected
  NearbyStation sse_decode_nearby_station(SseDeserializer deserializer);

  @protected
  NetworkConfig sse_decode_network_config(SseDeserializer deserializer);

  @protected
  String? sse_decode_opt_String(SseDeserializer deserializer);

  @protected
  DeploymentConfig? sse_decode_opt_box_autoadd_deployment_config(
      SseDeserializer deserializer);

  @protected
  EphemeralConfig? sse_decode_opt_box_autoadd_ephemeral_config(
      SseDeserializer deserializer);

  @protected
  LoraConfig? sse_decode_opt_box_autoadd_lora_config(
      SseDeserializer deserializer);

  @protected
  Schedule? sse_decode_opt_box_autoadd_schedule(SseDeserializer deserializer);

  @protected
  SensorValue? sse_decode_opt_box_autoadd_sensor_value(
      SseDeserializer deserializer);

  @protected
  Tokens? sse_decode_opt_box_autoadd_tokens(SseDeserializer deserializer);

  @protected
  TransmissionConfig? sse_decode_opt_box_autoadd_transmission_config(
      SseDeserializer deserializer);

  @protected
  int? sse_decode_opt_box_autoadd_u_32(SseDeserializer deserializer);

  @protected
  int? sse_decode_opt_box_autoadd_u_64(SseDeserializer deserializer);

  @protected
  Uint8List? sse_decode_opt_list_prim_u_8_strict(SseDeserializer deserializer);

  @protected
  PortalError sse_decode_portal_error(SseDeserializer deserializer);

  @protected
  RecordArchive sse_decode_record_archive(SseDeserializer deserializer);

  @protected
  Registered sse_decode_registered(SseDeserializer deserializer);

  @protected
  Schedule sse_decode_schedule(SseDeserializer deserializer);

  @protected
  SensorConfig sse_decode_sensor_config(SseDeserializer deserializer);

  @protected
  SensorValue sse_decode_sensor_value(SseDeserializer deserializer);

  @protected
  SolarInfo sse_decode_solar_info(SseDeserializer deserializer);

  @protected
  StationConfig sse_decode_station_config(SseDeserializer deserializer);

  @protected
  StreamInfo sse_decode_stream_info(SseDeserializer deserializer);

  @protected
  Tokens sse_decode_tokens(SseDeserializer deserializer);

  @protected
  TransferProgress sse_decode_transfer_progress(SseDeserializer deserializer);

  @protected
  TransferStatus sse_decode_transfer_status(SseDeserializer deserializer);

  @protected
  TransmissionConfig sse_decode_transmission_config(
      SseDeserializer deserializer);

  @protected
  TransmissionToken sse_decode_transmission_token(SseDeserializer deserializer);

  @protected
  int sse_decode_u_32(SseDeserializer deserializer);

  @protected
  int sse_decode_u_64(SseDeserializer deserializer);

  @protected
  int sse_decode_u_8(SseDeserializer deserializer);

  @protected
  void sse_decode_unit(SseDeserializer deserializer);

  @protected
  UpgradeProgress sse_decode_upgrade_progress(SseDeserializer deserializer);

  @protected
  UpgradeStatus sse_decode_upgrade_status(SseDeserializer deserializer);

  @protected
  UploadProgress sse_decode_upload_progress(SseDeserializer deserializer);

  @protected
  int sse_decode_usize(SseDeserializer deserializer);

  @protected
  UtcDateTime sse_decode_utc_date_time(SseDeserializer deserializer);

  @protected
  WifiNetworkConfig sse_decode_wifi_network_config(
      SseDeserializer deserializer);

  @protected
  WifiNetworksConfig sse_decode_wifi_networks_config(
      SseDeserializer deserializer);

  @protected
  WifiTransmissionConfig sse_decode_wifi_transmission_config(
      SseDeserializer deserializer);

  @protected
  void sse_encode_AnyhowException(
      AnyhowException self, SseSerializer serializer);

  @protected
  void sse_encode_String(String self, SseSerializer serializer);

  @protected
  void sse_encode_add_or_update_portal_station(
      AddOrUpdatePortalStation self, SseSerializer serializer);

  @protected
  void sse_encode_authenticated(Authenticated self, SseSerializer serializer);

  @protected
  void sse_encode_battery_info(BatteryInfo self, SseSerializer serializer);

  @protected
  void sse_encode_bool(bool self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_add_or_update_portal_station(
      AddOrUpdatePortalStation self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_deploy_config(
      DeployConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_deployment_config(
      DeploymentConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_download_progress(
      DownloadProgress self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_ephemeral_config(
      EphemeralConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_firmware_download_status(
      FirmwareDownloadStatus self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_local_firmware(
      LocalFirmware self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_lora_config(
      LoraConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_lora_transmission_config(
      LoraTransmissionConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_schedule(Schedule self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_sensor_value(
      SensorValue self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_station_config(
      StationConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_tokens(Tokens self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_transfer_progress(
      TransferProgress self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_transmission_config(
      TransmissionConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_u_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_u_64(int self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_upgrade_progress(
      UpgradeProgress self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_upload_progress(
      UploadProgress self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_wifi_networks_config(
      WifiNetworksConfig self, SseSerializer serializer);

  @protected
  void sse_encode_box_autoadd_wifi_transmission_config(
      WifiTransmissionConfig self, SseSerializer serializer);

  @protected
  void sse_encode_deploy_config(DeployConfig self, SseSerializer serializer);

  @protected
  void sse_encode_deployment_config(
      DeploymentConfig self, SseSerializer serializer);

  @protected
  void sse_encode_device_capabilities(
      DeviceCapabilities self, SseSerializer serializer);

  @protected
  void sse_encode_domain_message(DomainMessage self, SseSerializer serializer);

  @protected
  void sse_encode_download_progress(
      DownloadProgress self, SseSerializer serializer);

  @protected
  void sse_encode_ephemeral_config(
      EphemeralConfig self, SseSerializer serializer);

  @protected
  void sse_encode_f_32(double self, SseSerializer serializer);

  @protected
  void sse_encode_firmware_download_status(
      FirmwareDownloadStatus self, SseSerializer serializer);

  @protected
  void sse_encode_firmware_info(FirmwareInfo self, SseSerializer serializer);

  @protected
  void sse_encode_i_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_i_64(int self, SseSerializer serializer);

  @protected
  void sse_encode_list_local_firmware(
      List<LocalFirmware> self, SseSerializer serializer);

  @protected
  void sse_encode_list_module_config(
      List<ModuleConfig> self, SseSerializer serializer);

  @protected
  void sse_encode_list_nearby_station(
      List<NearbyStation> self, SseSerializer serializer);

  @protected
  void sse_encode_list_network_config(
      List<NetworkConfig> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8_loose(List<int> self, SseSerializer serializer);

  @protected
  void sse_encode_list_prim_u_8_strict(
      Uint8List self, SseSerializer serializer);

  @protected
  void sse_encode_list_record_archive(
      List<RecordArchive> self, SseSerializer serializer);

  @protected
  void sse_encode_list_sensor_config(
      List<SensorConfig> self, SseSerializer serializer);

  @protected
  void sse_encode_list_station_config(
      List<StationConfig> self, SseSerializer serializer);

  @protected
  void sse_encode_list_wifi_network_config(
      List<WifiNetworkConfig> self, SseSerializer serializer);

  @protected
  void sse_encode_local_firmware(LocalFirmware self, SseSerializer serializer);

  @protected
  void sse_encode_lora_band(LoraBand self, SseSerializer serializer);

  @protected
  void sse_encode_lora_config(LoraConfig self, SseSerializer serializer);

  @protected
  void sse_encode_lora_transmission_config(
      LoraTransmissionConfig self, SseSerializer serializer);

  @protected
  void sse_encode_module_config(ModuleConfig self, SseSerializer serializer);

  @protected
  void sse_encode_nearby_station(NearbyStation self, SseSerializer serializer);

  @protected
  void sse_encode_network_config(NetworkConfig self, SseSerializer serializer);

  @protected
  void sse_encode_opt_String(String? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_deployment_config(
      DeploymentConfig? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_ephemeral_config(
      EphemeralConfig? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_lora_config(
      LoraConfig? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_schedule(
      Schedule? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_sensor_value(
      SensorValue? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_tokens(
      Tokens? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_transmission_config(
      TransmissionConfig? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_u_32(int? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_box_autoadd_u_64(int? self, SseSerializer serializer);

  @protected
  void sse_encode_opt_list_prim_u_8_strict(
      Uint8List? self, SseSerializer serializer);

  @protected
  void sse_encode_portal_error(PortalError self, SseSerializer serializer);

  @protected
  void sse_encode_record_archive(RecordArchive self, SseSerializer serializer);

  @protected
  void sse_encode_registered(Registered self, SseSerializer serializer);

  @protected
  void sse_encode_schedule(Schedule self, SseSerializer serializer);

  @protected
  void sse_encode_sensor_config(SensorConfig self, SseSerializer serializer);

  @protected
  void sse_encode_sensor_value(SensorValue self, SseSerializer serializer);

  @protected
  void sse_encode_solar_info(SolarInfo self, SseSerializer serializer);

  @protected
  void sse_encode_station_config(StationConfig self, SseSerializer serializer);

  @protected
  void sse_encode_stream_info(StreamInfo self, SseSerializer serializer);

  @protected
  void sse_encode_tokens(Tokens self, SseSerializer serializer);

  @protected
  void sse_encode_transfer_progress(
      TransferProgress self, SseSerializer serializer);

  @protected
  void sse_encode_transfer_status(
      TransferStatus self, SseSerializer serializer);

  @protected
  void sse_encode_transmission_config(
      TransmissionConfig self, SseSerializer serializer);

  @protected
  void sse_encode_transmission_token(
      TransmissionToken self, SseSerializer serializer);

  @protected
  void sse_encode_u_32(int self, SseSerializer serializer);

  @protected
  void sse_encode_u_64(int self, SseSerializer serializer);

  @protected
  void sse_encode_u_8(int self, SseSerializer serializer);

  @protected
  void sse_encode_unit(void self, SseSerializer serializer);

  @protected
  void sse_encode_upgrade_progress(
      UpgradeProgress self, SseSerializer serializer);

  @protected
  void sse_encode_upgrade_status(UpgradeStatus self, SseSerializer serializer);

  @protected
  void sse_encode_upload_progress(
      UploadProgress self, SseSerializer serializer);

  @protected
  void sse_encode_usize(int self, SseSerializer serializer);

  @protected
  void sse_encode_utc_date_time(UtcDateTime self, SseSerializer serializer);

  @protected
  void sse_encode_wifi_network_config(
      WifiNetworkConfig self, SseSerializer serializer);

  @protected
  void sse_encode_wifi_networks_config(
      WifiNetworksConfig self, SseSerializer serializer);

  @protected
  void sse_encode_wifi_transmission_config(
      WifiTransmissionConfig self, SseSerializer serializer);
}

// Section: wire_class

class RustLibWire implements BaseWire {
  RustLibWire.fromExternalLibrary(ExternalLibrary lib);
}

@JS('wasm_bindgen')
external RustLibWasmModule get wasmModule;

@JS()
@anonymous
class RustLibWasmModule implements WasmModule {
  @override
  external Object /* Promise */ call([String? moduleName]);

  @override
  external RustLibWasmModule bind(dynamic thisArg, String moduleName);
}
