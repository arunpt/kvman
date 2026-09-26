class OpticalParameter {
  final String deviceId;
  final String connectionStatusIpv4;
  final String connectionStatusIpv6;
  final String connectionType;
  final num opticalParamRece;
  final num opticalParamTrans;

  OpticalParameter({
    required this.deviceId,
    required this.connectionStatusIpv4,
    required this.connectionStatusIpv6,
    required this.connectionType,
    required this.opticalParamRece,
    required this.opticalParamTrans,
  });

  factory OpticalParameter.fromJson(Map<String, dynamic> json) {
    return OpticalParameter(
      deviceId: json['device_id']?.toString() ?? 'Unknown',
      connectionStatusIpv4:
          json['connection_status_ipv4']?.toString() ?? 'Unknown',
      connectionStatusIpv6:
          json['connection_status_ipv6']?.toString() ?? 'Unknown',
      connectionType: json['connection_type']?.toString() ?? 'Unknown',
      opticalParamRece: json['optical_param_rece'] as num? ?? 0,
      opticalParamTrans: json['optical_param_trans'] as num? ?? 0,
    );
  }
}

class WanInterface {
  final String protocolGroup;
  final String name;
  final String externalIpAddress;
  final String connectionStatus;
  final String connectionType;
  final String dnsServers;
  final String transportType;
  final String landBinding;

  WanInterface({
    required this.protocolGroup,
    required this.name,
    required this.externalIpAddress,
    required this.connectionStatus,
    required this.connectionType,
    required this.dnsServers,
    required this.transportType,
    required this.landBinding,
  });

  factory WanInterface.fromJson(
    Map<String, dynamic> json, {
    String group = '',
  }) {
    return WanInterface(
      protocolGroup: group.toUpperCase(),
      name: json['name']?.toString() ?? '',
      externalIpAddress: json['external_ip_address']?.toString() ?? '',
      connectionStatus: json['connection_status']?.toString() ?? '',
      connectionType: json['connection_type']?.toString() ?? '',
      dnsServers: json['dns_servers']?.toString() ?? '',
      transportType: json['transport_type']?.toString() ?? '',
      landBinding: json['land_binding']?.toString() ?? '',
    );
  }
}

class WanDetails {
  final List<WanInterface> interfaces;

  WanDetails({required this.interfaces});

  factory WanDetails.fromJson(Map<String, dynamic> json) {
    List<WanInterface> extracted = [];

    final groups = ['wanif4', 'wanif6'];

    for (var group in groups) {
      if (json[group] is Map<String, dynamic>) {
        final groupMap = json[group] as Map<String, dynamic>;
        for (var entry in groupMap.entries) {
          final interfaceData = entry.value;
          if (interfaceData is Map<String, dynamic>) {
            extracted.add(WanInterface.fromJson(interfaceData, group: group));
          }
        }
      }
    }

    return WanDetails(interfaces: extracted);
  }
}

class DeviceInfo {
  final String deviceId;
  final String modelName;
  final String vendorName;
  final String onlineStatus;
  final String macAddress;
  final String hardwareVersion;
  final String manufacturerOui;
  final String productClass;
  final String serialNumber;
  final String softwareVersion;

  DeviceInfo({
    required this.deviceId,
    required this.modelName,
    required this.vendorName,
    required this.onlineStatus,
    required this.macAddress,
    required this.hardwareVersion,
    required this.manufacturerOui,
    required this.productClass,
    required this.serialNumber,
    required this.softwareVersion,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['device_id']?.toString() ?? '',
      modelName: json['model_name']?.toString() ?? '',
      vendorName: json['vendor_name']?.toString() ?? '',
      onlineStatus: json['online_status']?.toString() ?? '',
      macAddress: json['mac_address']?.toString() ?? '',
      hardwareVersion: json['hardwareversion']?.toString() ?? '',
      manufacturerOui: json['ManufacturerOUI']?.toString() ?? '',
      productClass: json['ProductClass']?.toString() ?? '',
      serialNumber: json['SerialNumber']?.toString() ?? '',
      softwareVersion: json['SoftwareVersion']?.toString() ?? '',
    );
  }
}

class WifiParameter {
  final String id;
  final String name;
  final String maxBitRate;
  final String radioEnabled;
  final String possibleChannels;
  final String channelsInUse;
  final String ssid;
  final String status;
  final String beaconType;
  final String totalBytesReceived;
  final String totalBytesSent;
  final num transmitPower;
  final bool ssidAdvertisementEnabled;

  WifiParameter({
    required this.id,
    required this.name,
    required this.maxBitRate,
    required this.radioEnabled,
    required this.possibleChannels,
    required this.channelsInUse,
    required this.ssid,
    required this.status,
    required this.beaconType,
    required this.totalBytesReceived,
    required this.totalBytesSent,
    required this.transmitPower,
    required this.ssidAdvertisementEnabled,
  });

  factory WifiParameter.fromJson(String id, Map<String, dynamic> json) {
    return WifiParameter(
      id: id,
      name: json['name']?.toString() ?? '',
      maxBitRate: json['MaxBitRate']?.toString() ?? '',
      radioEnabled: json['RadioEnabled']?.toString() ?? '',
      possibleChannels: json['PossibleChannels']?.toString() ?? '',
      channelsInUse: json['ChannelsInUse']?.toString() ?? '',
      ssid: json['SSID']?.toString() ?? '',
      status: json['Status']?.toString() ?? '',
      beaconType: json['BeaconType']?.toString() ?? '',
      totalBytesReceived: json['TotalBytesReceived']?.toString() ?? '',
      totalBytesSent: json['TotalBytesSent']?.toString() ?? '',
      transmitPower: json['TransmitPower'] as num? ?? 0,
      ssidAdvertisementEnabled:
          json['SSIDAdvertisementEnabled'] == true ||
          json['SSIDAdvertisementEnabled']?.toString().toLowerCase() == 'true',
    );
  }
}
