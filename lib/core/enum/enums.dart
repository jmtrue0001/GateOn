enum StatusCode { success, notFound, unAuthorized, badRequest, timeout, forbidden, error }

enum CommonStatus { initial, success, loading, failure, error }

enum UploadStatus { initial, success, loading, failure, delete }

enum TokenStatus { initial, hasToken, noToken, guestToken }

enum SignUpStatus { initial, oauth, oauthSuccess, success, failure }

enum OrderType { desc, asc }

enum FilterType { none, name, number, disabledAt, enabledAt, deviceID, createdAt, }

enum NavRailItem { stat, user, notification, setting }

enum NavbarItem { home, myPage }

enum LoginStatus { guest, login, logout }

enum AlertType { notice, like }

enum ImageType { camera, gallery }

enum NotificationType { notice, event }

enum TokenType { none, accessToken, refreshToken, customToken }

enum PermissionType { camera, location, manager, bluetooth }

enum TermType { service, privacy }

enum TickerStatus { initial, run, pause, complete }

enum InteractionType {qr, nfc, beacon, manual, delete,location,init }

enum ChartType { month, year, day }

enum Path { left, right }

enum Role {
  ROLE_ADMIN,
  ROLE_ENTERPRISE,
  ROLE_ENTERPRISE_SUB;

  const Role();

  static Role strToEnum(String? str) {
    if (str == null) {
      return Role.ROLE_ENTERPRISE;
    }
    return Role.values.byName(str);
  }
}

enum AbleType {
  ENABLE('허용'),
  DISABLE('차단');

  const AbleType(this.data);

  final String data;

  static AbleType strToEnum(String? str) {
    if (str == null) {
      return AbleType.DISABLE;
    }
    return AbleType.values.byName(str);
  }
}

enum DeviceActive {
  ACTIVE('활성화'),
  INACTIVE('비활성화');

  const DeviceActive(this.data);

  final String data;

  static DeviceActive strToEnum(String? str) {
    if (str == null) {
      return DeviceActive.INACTIVE;
    }
    return DeviceActive.values.byName(str);
  }
}

enum DeviceType {
  NFC('NFC'),
  BEACON('비콘'),
  QR('QR');

  const DeviceType(this.data);

  final String data;

  static DeviceType strToEnum(String? str) {
    if (str == null) {
      return DeviceType.NFC;
    }
    return DeviceType.values.byName(str);
  }
}
