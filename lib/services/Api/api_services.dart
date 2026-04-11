import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import '../../constants/constants.dart';
import '../../data/models/AddAddressModel/add_address_model.dart';
import '../../data/models/AddToCartModel/addTo_cart_model.dart';
import '../../data/models/AllAddressesModel/all_addresses_model.dart';
import '../../data/models/CommonModel/common_model.dart';
import '../../data/models/FavouritesModel/favourites_model.dart';
import '../../data/models/FetchUserModel/fetch_user_model.dart';
import '../../data/models/HomeModel/home_model.dart';
import '../../data/models/MlmModels/mlm_downlines_model.dart';
import '../../data/models/MyAllServicesModel/my_all_services_model.dart';
import '../../data/models/NearWorkshopModel/near_workshop_model.dart';
import '../../data/models/OrderHistoryModel/order_history_model.dart';
import '../../data/models/ProductModel/product_model.dart';
import '../../data/models/RemFromCartModel/rem_from_cart_model.dart';
import '../../data/models/RemFromFevModel/rem_from_fev_model.dart';
import '../../data/models/SearchModel/search_model.dart';
import '../../data/models/ServicesModel/services_model.dart';
import '../../data/models/TransactionModel/transaction_model.dart';
import '../../data/models/UpdateAddressModel/update_address_model.dart';
import '../../data/models/UpdateCartQuantityModel/update_cart_quantity_model.dart';
import '../../data/models/ViewCartModel/view_cart_model.dart';
import '../../data/models/ViewFavouritesModel/view_favourites_model.dart';
import '../../data/models/Wallet/AllUpiIdModel/add_upi_id_model.dart';
import '../../data/models/Wallet/AllUpiIdModel/delete_upi_id_model.dart';
import '../../data/models/Wallet/AllUpiIdModel/get_all_upi_id_model.dart';
import '../../data/models/Wallet/WithdrawHistoryModel/withdraw_history_model.dart';
import '../../data/models/Wallet/WithdrawModel/withdraw_model.dart';
import '../../data/models/login_and_registration_flow/login/LoginModel.dart';
import '../../data/models/login_and_registration_flow/registration/RegisterModel.dart';
import '../../utils/flutter_toast.dart';
import 'api_constants.dart';
import 'api_repository.dart';
import 'package:http/http.dart' as http;

class ApiService implements ApiRepository {
  final Dio dio;
  var storage = GetStorage();
  final secureStorage = const FlutterSecureStorage();

  ApiService({required this.dio});


  Future<void> firebaseLogin(String firebaseToken) async {
    print("firebaseLogin");

    final url = Uri.parse('${ApiConstants.baseURL}auth/firebase-login');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $firebaseToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'role': 'RESTAURANT',
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final accessToken = data['accessToken'];
      final refreshToken = data['refreshToken'];

      // ✅ Store securely
      await secureStorage.write(
        key: 'accessToken',
        value: accessToken,
      );

      await secureStorage.write(
        key: 'refreshToken',
        value: refreshToken,
      );

      print('Login success');
    } else {
      print('Login failed: ${response.statusCode}');
      print(response.body);
    }
  }

  Future<MenuModel> getMenu() async {
    final response = await dio.get(
      '${ApiConstants.baseURL}categories/menu',
    );

    if (response.statusCode == 200) {
      return MenuModel.fromJson(response.data);
    } else {
      throw Exception("Menu fetch failed");
    }
  }

  Future<LoginModel> login(Map<String, String> request) async {
    try {
      final response = await dio.post(ApiConstants.userLogin, data: request);
      if (response.statusCode == 200) {
        return LoginModel.fromJson(response.data);
      } else {
        return LoginModel(
          status: false,
          message: response.data['message'] ??
              "Unexpected error occurred. Status Code: ${response.statusCode}",
        );
      }
    } on DioException catch (e) {
      return LoginModel(
        status: false,
        message: e.response?.data['message'] ??
            e.response?.statusMessage ??
            "Server error occurred. Please try again.",
      );
    } catch (e) {
      return LoginModel(
        status: false,
        message: "An unexpected error occurred. Please try again.",
      );
    }
  }

  Future<String?> getAccessToken() async {
    return await secureStorage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    return await secureStorage.read(key: 'refreshToken');
  }

  Future<RegisterModel> firebaseRegister(
      Map<String, dynamic> request,
      ) async {
    try {
      // ✅ Get access token from secure storage
      final accessToken = await getAccessToken();

      if (accessToken == null) {
        return RegisterModel(
          status: false,
          message: 'Access token not found. Please login again.',
        );
      }

      final response = await dio.post(
        '${ApiConstants.baseURL}restaurant/register', // ✅ Correct URL
        data: request,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RegisterModel.fromJson(response.data);
      } else {
        return RegisterModel(
          status: false,
          message: response.data['message'] ?? 'Registration failed',
        );
      }
    } on DioException catch (e) {
      return RegisterModel(
        status: false,
        message: e.response?.data['message'] ??
            e.message ??
            'Server error',
      );
    } catch (e) {
      return RegisterModel(
        status: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }




  @override
  Future<RegisterModel> register(Map<String, String> request) async {
    try {
      final response = await dio.post(ApiConstants.userRegister, data: request);
      if (response.data != null && response.data is Map<String, dynamic>) {
        print(" OTP Screen Submit: ${response.data}");
        bool status = response.data['status'] ?? false;

        if (status) {
          return RegisterModel.fromJson(response.data);
        } else {
          return RegisterModel(
            status: false,
            message: response.data['message'] ?? "Unexpected error occurred",
          );
        }
      } else {
        return RegisterModel(
          status: false,
          message: "Invalid response from server",
        );
      }
    } on DioException catch (e) {
      return RegisterModel(
        status: false,
        message: e.response?.data['message'] ?? "Server error",
      );
    } catch (e) {
      return RegisterModel(
        status: false,
        message: "An unexpected error occurred: ${e.toString()}",
      );
    }
  }

  @override
  Future<CommonModel> registerOtp(Map<String, String> request) async {
    try {
      final response = await dio.post(ApiConstants.sendOTP, data: request);
      if (response.statusCode == 200) {
        return CommonModel.fromJson(response.data);
      } else {
        return CommonModel(status: false, message: response.data["message"]);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return CommonModel(status: false, message: e.response?.data["message"]);
      } else {
        Message_Utils.displayToast(e.toString());
      }
    } catch (e) {
      Message_Utils.displayToast(e.toString());
    }
    return CommonModel(status: false, message: "server error");
  }

  @override
  Future<CommonModel> resetPassword(Map<String, String> request) async {
    try {
      final response =
          await dio.post(ApiConstants.resetPassword, data: request);
      if (response.statusCode == 200) {
        return CommonModel.fromJson(response.data);
      } else {
        return CommonModel(status: false, message: response.data["message"]);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return CommonModel(status: false, message: e.response?.data["message"]);
      }
    } catch (e) {
      Message_Utils.displayToast(e.toString());
    }
    return CommonModel(status: false, message: "server error");
  }

  @override
  Future<ProductModel> getAllProductsList() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getProductList,
      );

      if (response.statusCode == 200) {
        return ProductModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch product: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return ProductModel(status: false, message: "server-error");
    }
  }

  @override
  Future<SearchModel> searchProduct(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.searchProduct,
        queryParameters: request,
      );

      if (response.statusCode == 200) {
        return SearchModel.fromJson(response.data);
      } else {
        throw ("Failed to search product: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return SearchModel(status: false, message: "server-error");
    }
  }

  @override
  Future<UpdateAddressModel> updateAddress(
      String addressId, Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }
      String url = '${ApiConstants.updateAddress}$addressId';
      final response = await dio.put(
        url,
        data: request,
      );

      if (response.statusCode == 200) {
        return UpdateAddressModel.fromJson(response.data);
      } else {
        throw ("Failed to update address: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return UpdateAddressModel(
        status: false,
        message: e.toString(),
      );
    }
  }

  @override
  Future<TransactionModel> createOrder(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response = await dio.post(
        ApiConstants.createOrder,
        data: request,
      );

      if (response.statusCode == 201) {
        return TransactionModel.fromJson(response.data);
      } else {
        throw Exception("Failed to process payment: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return TransactionModel(status: false, message: e.toString());
    }
  }

  @override
  Future<CommonModel> verifyOrder(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response = await dio.post(
        ApiConstants.verifyOrder,
        data: request,
      );

      if (response.statusCode == 201) {
        return CommonModel.fromJson(response.data);
      } else {
        throw Exception("Failed to verify order: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    }
  }

  @override
  Future<OrderHistoryModel> myOrderHistory(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response = await dio.get(ApiConstants.orderHistory,
          data: request,
          options: Options(headers: {
            'Authorization': 'Bearer $token',
          }));

      if (response.statusCode == 200) {
        return OrderHistoryModel.fromJson(response.data);
      } else {
        return OrderHistoryModel(
          status: false,
          message: "Failed to load order history: ${response.statusMessage}",
        );
      }
    } on DioException catch (e) {
      return OrderHistoryModel(
        status: false,
        message: e.response?.data['message'] ?? "An unknown error occurred.",
      );
    } catch (e) {
      return OrderHistoryModel(status: false, message: e.toString());
    }
  }

  @override
  Future<NearWorkshopModel> getAllWorkshopList(
      Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getNearWorkshopList,
        data: request,
      );

      if (response.statusCode == 200) {
        return NearWorkshopModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch workshops: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return NearWorkshopModel(status: false, message: e.toString());
    }
  }

  @override
  Future<NearWorkshopModel> getBreakdownList(
      Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getNearWorkshopList,
        data: request,
      );

      if (response.statusCode == 200) {
        return NearWorkshopModel.fromJson(response.data);
      } else {
        throw Exception(
            "Failed to fetch near workshops: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return NearWorkshopModel(status: false, message: e.toString());
    }
  }

  @override
  Future<AddToCartModel> addToCart(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.post(
        ApiConstants.addToCart,
        data: request,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddToCartModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String errorMessage =
            e.response?.data["message"] ?? "Unknown error occurred";
        throw Exception(errorMessage);
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      return AddToCartModel(status: false, message: e.toString());
    }
  }

  @override
  Future<FavouritesModel> addToFavourites(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.post(
        ApiConstants.addToFavourites,
        data: request,
      );

      if (response.statusCode == 200) {
        return FavouritesModel.fromJson(response.data);
      } else {
        throw Exception(
            "Add to Failed favorites product: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return FavouritesModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<ViewCartModel> getAllCartList() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getCartList,
      );

      if (response.statusCode == 200) {
        return ViewCartModel.fromJson(response.data);
      } else {
        throw Exception("${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return ViewCartModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<ViewFavouritesModel> getAllFavouriteList() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getFavouriteList,
      );

      if (response.statusCode == 200) {
        return ViewFavouritesModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch favorites: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return ViewFavouritesModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<void> logOut(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);

      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.post(ApiConstants.logOut, data: request);
    } catch (e) {
      Message_Utils.displayToast("Logout Error:${e.toString()}");
    }
  }

  @override
  Future<RemFromCartModel> removeFromCart(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.delete(
        ApiConstants.removeFromCart,
        data: request,
      );

      if (response.statusCode == 200) {
        return RemFromCartModel.fromJson(response.data);
      } else {
        throw Exception(
            "Failed to remove product from cart: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return RemFromCartModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<RemFromFevModel> removeFromFavourite(
      Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.delete(
        ApiConstants.removeFromFav,
        data: request,
      );

      if (response.statusCode == 200) {
        return RemFromFevModel.fromJson(response.data);
      } else {
        throw Exception(
            "Failed to fetch from wishlist: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return RemFromFevModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<OrderHistoryModel> cancelOrder(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response = await dio.patch(ApiConstants.cancelOrder, data: request);

      if (response.statusCode == 200) {
        return OrderHistoryModel.fromJson(response.data);
      } else {
        return OrderHistoryModel(
          status: false,
          message: "Failed to cancel order: ${response.statusMessage}",
        );
      }
    } on DioException catch (e) {
      return OrderHistoryModel(
        status: false,
        message: e.response?.data['message'] ?? "An unknown error occurred.",
      );
    } catch (e) {
      return OrderHistoryModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<ServiceModel> bookBreakdownService(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response =
          await dio.post(ApiConstants.bookBreakdownService, data: request);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return ServiceModel.fromJson(response.data);
      } else {
        return ServiceModel(
          status: false,
          message: "${response.statusMessage}",
        );
      }
    } on DioException catch (e) {
      return ServiceModel(
        status: false,
        message: e.response?.data['message'] ?? "An unknown error occurred.",
      );
    } catch (e) {
      return ServiceModel(
          status: false, message: "An error occurred: ${e.toString()}");
    }
  }

  @override
  Future<ServiceModel> bookWorkshopService(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response =
          await dio.post(ApiConstants.bookWorkshopService, data: request);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return ServiceModel.fromJson(response.data);
      } else {
        return ServiceModel(
          status: false,
          message: response.data['message'] ?? "Unexpected error occurred.",
        );
      }
    } on DioException catch (e) {
      return ServiceModel(
        status: false,
        message: e.response?.data?['message'] ?? "An unknown error occurred.",
      );
    } catch (e) {
      return ServiceModel(
        status: false,
        message: "An error occurred: ${e.toString()}",
      );
    }
  }

  @override
  Future<void> refreshToken(Map<String, String> request) async {
    try {
      final response = await dio.post(
        ApiConstants.accessTokenNew,
        data: request,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception("Failed to refresh token");
      }
    } catch (e) {
      Message_Utils.displayToast(e.toString());
    }
  }

  @override
  Future<UpdateCartQuantityModel> updateCartQuantity(
      Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response =
          await dio.put(ApiConstants.updateCartQuantity, data: request);

      if (response.statusCode == 200) {
        return UpdateCartQuantityModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage.toString());
      }
    } on DioException catch (e) {
      if (e.response != null) {
        if (e.response?.statusCode == 409) {
          return UpdateCartQuantityModel(
            status: false,
            message: e.response?.data["message"] ??
                "This product's quantity is fixed and cannot be changed.",
          );
        }
        return UpdateCartQuantityModel(
          status: false,
          message: e.response?.data["message"] ?? "Unknown error occurred",
        );
      } else {
        return UpdateCartQuantityModel(
          status: false,
          message: "Network error occurred",
        );
      }
    } catch (e) {
      return UpdateCartQuantityModel(status: false, message: e.toString());
    }
  }

  @override
  Future<HomeModel> getHomeData() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getHomeData,
      );

      if (response.statusCode == 200) {
        return HomeModel.fromJson(response.data);
      } else {
        throw Exception("Failed: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return HomeModel(status: false, message: e.toString());
    }
  }

  @override
  Future<MyAllServicesModel> myAllServices() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.myAllServices,
      );

      if (response.statusCode == 200) {
        return MyAllServicesModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return MyAllServicesModel(status: false, message: e.toString());
    }
  }

  @override
  Future<MyAllServicesModel> cancelService(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }

      final response =
          await dio.patch(ApiConstants.cancelService, data: request);

      if (response.statusCode == 200) {
        return MyAllServicesModel.fromJson(response.data);
      } else {
        return MyAllServicesModel(
          status: false,
          message: "Failed to cancel service: ${response.statusMessage}",
        );
      }
    } on DioException catch (e) {
      return MyAllServicesModel(
        status: false,
        message: e.response?.data['message'] ?? "An unknown error occurred.",
      );
    } catch (e) {
      return MyAllServicesModel(status: false, message: e.toString());
    }
  }

  @override
  Future<HomeModel> getFeaturedWorkshop(Map<String, String> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(ApiConstants.getHomeData, data: request);

      if (response.statusCode == 200) {
        return HomeModel.fromJson(response.data);
      } else {
        throw Exception("Failed: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return HomeModel(status: false, message: e.toString());
    }
  }

  @override
  Future<AllAddressesModel> getAllAddress() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getAllAddresses,
      );

      if (response.statusCode == 200) {
        return AllAddressesModel.fromJson(response.data);
      } else {
        throw Exception("${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return AllAddressesModel(status: false);
    }
  }

  @override
  Future<AddAddressModel> addAddress(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.post(ApiConstants.addAddress, data: request);

      if (response.statusCode == 201) {
        return AddAddressModel.fromJson(response.data);
      } else {
        throw Exception("Failed: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      throw Exception("An error occurred: $e");
    }
  }

  @override
  Future<GetUpiIdModel> getAllUpiId() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(ApiConstants.getAllUpiId);

      if (response.statusCode == 200) {
        return GetUpiIdModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch UPI IDs: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return GetUpiIdModel(
        success: false,
      );
    }
  }

  @override
  Future<AddUpiIdModel> addAllUpiId(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.post(
        ApiConstants.addAllUpiId,
        data: request,
      );

      if (response.statusCode == 200) {
        return AddUpiIdModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String errorMessage =
            e.response?.data["message"] ?? "Unknown error occurred";
        throw Exception(errorMessage);
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      return AddUpiIdModel(success: false, message: e.toString());
    }
  }

  @override
  Future<DeleteUpiIdModel> deleteUpiId(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.delete(
        ApiConstants.deleteUpiId,
        data: request,
      );

      if (response.statusCode == 200) {
        return DeleteUpiIdModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String errorMessage =
            e.response?.data["message"] ?? "Unknown error occurred";
        throw Exception(errorMessage);
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      return DeleteUpiIdModel(
          success: false, message: e.toString(), upiIds: []);
    }
  }

  @override
  Future<MlmDownLinesModel> getAllDownLines(
      Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(
        ApiConstants.getAllDownLines,
        queryParameters: request,
      );

      if (response.statusCode == 200) {
        return MlmDownLinesModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String errorMessage =
            e.response?.data["message"] ?? "Unknown error occurred";
        throw Exception(errorMessage);
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      return MlmDownLinesModel(status: false, message: e.toString());
    }
  }

  @override
  Future<WithdrawModel> createWithdraw(Map<String, dynamic> request) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing. Please log in again.');
      }
      final response = await dio.post(
        ApiConstants.createWithdraw,
        data: request,
      );
      if (response.statusCode == 201) {
        return WithdrawModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage.toString());
      }
    } on DioException catch (e) {
      String errorMessage =
          e.response?.data["message"] ?? "Network error occurred";
      throw Exception(errorMessage);
    } catch (e) {
      return WithdrawModel(status: false, message: e.toString());
    }
  }

  @override
  Future<WithdrawHistoryModel> withdrawalHistory() async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(ApiConstants.withdrawHistory);

      if (response.statusCode == 200) {
        return WithdrawHistoryModel.fromJson(response.data);
      } else {
        throw Exception(
            "Failed to fetch Withdraw History: ${response.statusMessage}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception("Network error occurred");
      }
    } catch (e) {
      return WithdrawHistoryModel(
        status: false,
      );
    }
  }

  @override
  Future<CommonModel> deleteAddress(String id) async {
    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.delete(
        '${ApiConstants.deleteAddress}$id',
      );

      if (response.statusCode == 200) {
        return CommonModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage);
      }
    } on DioException catch (e) {
      if (e.response != null) {
        String errorMessage =
            e.response?.data["message"] ?? "Unknown error occurred";
        throw Exception(errorMessage);
      } else {
        throw Exception(e.message);
      }
    } catch (e) {
      return CommonModel(status: false, message: e.toString());
    }
  }

  @override
  Future<FetchUserModel> fetchUserData() async {

    try {
      String? token = await secureStorage.read(key: Constants.accessToken);
      if (token == null || token.isEmpty) {
        throw Exception('Token is missing in the request map.');
      }

      final response = await dio.get(ApiConstants.fetchUserDetail);

      if (response.statusCode == 200) {
        return FetchUserModel.fromJson(response.data);
      } else {
        throw Exception(response.statusMessage.toString());
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data["message"] ?? "Unknown error occurred");
      } else {
        throw Exception(e.toString());
      }
    } catch (e) {
      return FetchUserModel(status: false, message: e.toString());
    }
  }
}
