class ApiConfig {
  // Base server IP and port
  static const String serverIP = '192.168.0.13';
  // static const String serverIP = '192.168.34.254';
  static const String serverPort = '8000';
  
  // Base URL components
  static const String protocol = 'http';
  static const String baseServerUrl = '$protocol://$serverIP:$serverPort';
  
  // API endpoints
  static const String apiBasePath = '/api';
  // static const String baseApiUrl = 'https://findit.pw$apiBasePath';
  static const String baseApiUrl = '$baseServerUrl$apiBasePath';
  
  // Storage paths
  static const String storagePath = '/storage';
  // static const String storageBaseUrl = 'https://findit.pw$storagePath';
  static const String storageBaseUrl = '$baseServerUrl$storagePath';
  
  // Auth endpoints
  static const String loginEndpoint = '$baseApiUrl/login';
  static const String registerEndpoint = '$baseApiUrl/register';
  static const String logoutEndpoint = '$baseApiUrl/logout';
  static const String profileEndpoint = '$baseApiUrl/profile';
  static const String verifyEmailEndpoint = '$baseApiUrl/email/verify';   //no longer used
  static const String verifyEmailCheckEndpoint = '$baseApiUrl/email/verify-check';
  static const String verifyEmailResendEndpoint = '$baseApiUrl/email/verification-notification';
  static const String forgotPasswordEndpoint = '$baseApiUrl/forgot-password';
  static const String resetPasswordEndpoint = '$baseApiUrl/reset-password';
  static const String changePasswordEndpoint = '$baseApiUrl/change-password';
  static const String changeUsernameEndpoint = '$baseApiUrl/change-username';
  
  // Items endpoints
  static const String itemsEndpoint = '$baseApiUrl/items';
  static const String myItemsEndpoint = '$baseApiUrl/items/student-id';
  static const String studentsEndpoint = '$baseApiUrl/students';
  static const String editItemsEndpoint = '$baseApiUrl/items/edit';
  static const String deleteItemsEndpoint = '$baseApiUrl/items/delete';
  static const String claimItemsEndpoint = '$baseApiUrl/items/claim';
  static const String claimMatchEndpoint = '$baseApiUrl/items/claim/match';
  static const String potentialMatchesEndpoint = '$baseApiUrl/items/potential-matches';
  static const String studentClaimByPotentialMatchesEndpoint = '$baseApiUrl/items/potential-matches/claims';
  static const String matchingLostItemEndpoint = '$baseApiUrl/items/found/matching-lost-item-with-score';
  static const String itemRestrictionsEndpoint = '$baseApiUrl/items';  // Will be appended with /{id}/restrictions

  // Characteristics endpoints
  static const String characteristicsBasePath = '$baseApiUrl/characteristics';
  static const String categoriesEndpoint = '$characteristicsBasePath/categories';
  static const String coloursEndpoint = '$characteristicsBasePath/colours';
  static const String locationsEndpoint = '$characteristicsBasePath/locations';
  static const String facultiesEndpoint = '$characteristicsBasePath/faculties';
  
  // Storage endpoints
  static const String foundItemsStoragePath = '$storageBaseUrl/found_items';
  static const String lostItemsStoragePath = '$storageBaseUrl/lost_items';
  // static const String recoveredItemsStoragePath = '$storageBaseUrl/recovered_items';

  //Claim endpoints
  static const String showAllClaimsEndpoint = '$baseApiUrl/claims/student';
  // static const String showClaimByItemEndpoint = '$baseApiUrl/claim/item';
  static const String showClaimDetailsEndpoint = '$baseApiUrl/claim/details';
  
  // Notification endpoints
  static const String notificationsEndpoint = '$baseApiUrl/notifications';
  static const String markNotificationReadEndpoint = '$baseApiUrl/notifications'; // Will append /{id}/read
  static const String markAllNotificationsReadEndpoint = '$baseApiUrl/notifications/read-all';
  
  // FCM token endpoint
  static const String fcmTokenEndpoint = '$baseApiUrl/fcm-token';
  
  // Helper method to get image URL based on item type
  static String getItemImageUrl(String image, String type) {
    switch (type) {
      case 'found':
        return '$foundItemsStoragePath/$image';
      case 'lost':
        return '$lostItemsStoragePath/$image';
      // case 'recovered':
      //   return '$recoveredItemsStoragePath/$image';
      default:
        return '';
    }
  }
} 