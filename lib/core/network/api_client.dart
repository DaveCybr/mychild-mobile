// core/network/api_client.dart

import 'package:dio/dio.dart';
import 'package:retrofit/http.dart';
// import 'package:retrofit/retrofit.dart';

import '../../shared/models/family_model.dart';
import '../../shared/models/user_model.dart';
import '../constants/api_constants.dart';
import '../error/error_logger.dart';
import 'api_interceptor.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: ApiConstants.baseUrl)
abstract class ApiClient {
  factory ApiClient(Dio dio, {String baseUrl, ParseErrorLogger? errorLogger}) = _ApiClient;

  // Auth Endpoints
  @POST(ApiConstants.login)
  Future<ApiResponse<UserModel>> login(@Body() Map<String, dynamic> loginData);

  @POST(ApiConstants.register)
  Future<ApiResponse<UserModel>> register(@Body() Map<String, dynamic> registerData);

  @POST(ApiConstants.logout)
  Future<ApiResponse<dynamic>> logout();

  @GET(ApiConstants.user)
  Future<ApiResponse<UserModel>> getCurrentUser();

  @PUT(ApiConstants.profile)
  Future<ApiResponse<UserModel>> updateProfile(@Body() Map<String, dynamic> profileData);

  // Family Endpoints
  @POST(ApiConstants.familyCreate)
  Future<ApiResponse<FamilyModel>> createFamily(@Body() Map<String, dynamic> familyData);

  @POST(ApiConstants.familyJoin)
  Future<ApiResponse<FamilyModel>> joinFamily(@Body() Map<String, dynamic> joinData);

  @GET(ApiConstants.familyInfo)
  Future<ApiResponse<FamilyModel>> getFamilyInfo();

  @GET(ApiConstants.familyMembers)
  Future<ApiResponse<List<UserModel>>> getFamilyMembers();

  @DELETE(ApiConstants.familyLeave)
  Future<ApiResponse<dynamic>> leaveFamily();

  @PUT(ApiConstants.familyUpdate)
  Future<ApiResponse<FamilyModel>> updateFamily(@Body() Map<String, dynamic> familyData);

  // Location Endpoints
  @POST(ApiConstants.locationUpdate)
  Future<ApiResponse<dynamic>> updateLocation(@Body() Map<String, dynamic> locationData);

  @GET('${ApiConstants.locationTrack}/{childId}')
  Future<ApiResponse<Map<String, dynamic>>> trackChild(@Path() String childId);

  @GET('${ApiConstants.locationHistory}/{childId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getLocationHistory(
    @Path() String childId,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  );

  // Dashboard Endpoints
  @GET(ApiConstants.dashboardChild)
  Future<ApiResponse<Map<String, dynamic>>> getChildDashboard();

  @GET('${ApiConstants.dashboardAnalytics}/{childId}')
  Future<ApiResponse<Map<String, dynamic>>> getChildAnalytics(@Path() String childId);

  // Settings Endpoints
  @GET('${ApiConstants.settings}/{childId}')
  Future<ApiResponse<Map<String, dynamic>>> getSettings(@Path() String childId);

  @PUT('${ApiConstants.settingsUpdate}/{childId}')
  Future<ApiResponse<Map<String, dynamic>>> updateSettings(
    @Path() String childId,
    @Body() Map<String, dynamic> settings,
  );

  // Alert Endpoints
  @GET(ApiConstants.alertList)
  Future<ApiResponse<List<Map<String, dynamic>>>> getAlerts();

  @POST(ApiConstants.alertTrigger)
  Future<ApiResponse<dynamic>> triggerAlert(@Body() Map<String, dynamic> alertData);

  @POST(ApiConstants.alertMarkRead)
  Future<ApiResponse<dynamic>> markAlertAsRead(@Body() Map<String, dynamic> data);

  @GET(ApiConstants.alertUnreadCount)
  Future<ApiResponse<Map<String, dynamic>>> getUnreadAlertCount();

  // Notification Endpoints
  @POST(ApiConstants.notificationSend)
  Future<ApiResponse<dynamic>> sendNotification(@Body() Map<String, dynamic> notificationData);

  @POST(ApiConstants.notificationMarkRead)
  Future<ApiResponse<dynamic>> markNotificationAsRead(@Body() Map<String, dynamic> data);

  // Camera Endpoints
  @POST(ApiConstants.cameraStore)
  Future<ApiResponse<Map<String, dynamic>>> storeCapture(@Body() FormData captureData);

  @GET('${ApiConstants.cameraList}/{childId}')
  Future<ApiResponse<List<Map<String, dynamic>>>> getCameraCaptures(@Path() String childId);

  // Screen Endpoints
  @POST(ApiConstants.screenStartSession)
  Future<ApiResponse<Map<String, dynamic>>> startScreenSession(@Body() Map<String, dynamic> data);

  @POST(ApiConstants.screenEndSession)
  Future<ApiResponse<dynamic>> endScreenSession(@Body() Map<String, dynamic> data);

  @POST(ApiConstants.screenScreenshot)
  Future<ApiResponse<dynamic>> sendScreenshot(@Body() FormData screenshotData);
}
