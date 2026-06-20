abstract final class RouteNames {
  // Auth
  static const String welcome = '/welcome';
  static const String verifyOtp = '/verify-otp';
  static const String createProfile = '/create-profile';

  // Tab roots
  static const String feed = '/feed';
  static const String events = '/events';
  static const String growth = '/growth';
  static const String analytics = '/analytics';
  static const String profile = '/profile';

  // Stack routes
  static const String eventDetail = '/event/:id';
  static const String pollDetail = '/event/:id/poll/:pollId';
  static const String challengeDetail = '/challenge/:id';
  static const String recognitionDetail = '/recognition/:id';
  static const String fullRankings = '/analytics/ranking';
  static const String memberProfile = '/profile/:id';
  static const String notifications = '/notifications';

  // Admin
  static const String admin = '/admin';
  static const String adminMembers = '/admin/members';
  static const String adminFlagged = '/admin/flagged';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminAttendance = '/admin/attendance';
  static const String adminConnectBuddy = '/admin/connect-buddy';
}
