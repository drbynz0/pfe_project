import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';

class DeviceService {
  static Future<String> getDeviceName() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.name;
      } else if (Platform.isMacOS) {
        MacOsDeviceInfo macosInfo = await deviceInfo.macOsInfo;
        return macosInfo.computerName;
      } else if (Platform.isWindows) {
        WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        return windowsInfo.computerName;
      } else if (Platform.isLinux) {
        LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        return linuxInfo.prettyName;
      } else {
        return "Unknown Device";
      }
    } catch (e) {
      return "Unknown Device";
    }
  }

  static Future<String> getDeviceLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si les services de localisation sont activés
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return "Location services are disabled.";
    }

    // Vérifier les permissions de localisation
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return "Location permissions are denied.";
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return "Location permissions are permanently denied.";
    }

    // Obtenir la position actuelle
    // ignore: deprecated_member_use
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // Utiliser le géocodage inversé pour obtenir le nom du pays
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    String country = placemarks.first.country ?? "Unknown Country";

    return "Lat: ${position.latitude}, Long: ${position.longitude}, Country: $country";
  }

  static Future<String> getDevicePlatform() async {
    return Platform.operatingSystem;
  }

  static Future<Map<String, String>> getDeviceInfo() async {
    String deviceName = await getDeviceName();
    String deviceLocation = await getDeviceLocation();
    String devicePlatform = await getDevicePlatform();

    return {
      'deviceName': deviceName,
      'devicePlatform': devicePlatform,
      'deviceLocation': deviceLocation,

    };
  }
}
