import '../shared/api_client.dart';

class PantryService {
  final ApiClient _apiClient = ApiClient.instance;

  // Get user's pantry items
  Future<List<Map<String, dynamic>>> getPantryItems({
    String? category,
    bool? showExpired = false,
  }) async {
    try {
      final queryParams = <String, String>{
        if (category != null) 'category': category,
        if (showExpired != null) 'showExpired': showExpired.toString(),
      };
      
      final response = await _apiClient.get('/pantry', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get pantry items: $e');
    }
    
    return [];
  }

  // Add pantry item
  Future<Map<String, dynamic>?> addPantryItem({
    required String name,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expirationDate,
    DateTime? purchaseDate,
    String? brand,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post('/pantry/items', data: {
        'name': name,
        if (category != null) 'category': category,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (expirationDate != null) 'expirationDate': expirationDate.toIso8601String(),
        if (purchaseDate != null) 'purchaseDate': purchaseDate.toIso8601String(),
        if (brand != null) 'brand': brand,
        if (notes != null) 'notes': notes,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to add pantry item: $e');
    }
    
    return null;
  }

  // Scan barcode to add item
  Future<Map<String, dynamic>?> scanBarcode({
    required String barcode,
    int? quantity,
    DateTime? expirationDate,
  }) async {
    try {
      final response = await _apiClient.post('/pantry/scan-barcode', data: {
        'barcode': barcode,
        if (quantity != null) 'quantity': quantity,
        if (expirationDate != null) 'expirationDate': expirationDate.toIso8601String(),
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to scan barcode: $e');
    }
    
    return null;
  }

  // Update pantry item
  Future<bool> updatePantryItem({
    required String itemId,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    DateTime? expirationDate,
    DateTime? purchaseDate,
    String? brand,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.put('/pantry/items/$itemId', data: {
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit,
        if (expirationDate != null) 'expirationDate': expirationDate.toIso8601String(),
        if (purchaseDate != null) 'purchaseDate': purchaseDate.toIso8601String(),
        if (brand != null) 'brand': brand,
        if (notes != null) 'notes': notes,
      });
      
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to update pantry item: $e');
      return false;
    }
  }

  // Mark item as finished/used up
  Future<bool> markItemFinished({
    required String itemId,
    String? usageNotes,
  }) async {
    try {
      final response = await _apiClient.post('/pantry/items/$itemId/finished', data: {
        if (usageNotes != null) 'usageNotes': usageNotes,
        'finishedAt': DateTime.now().toIso8601String(),
      });
      
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to mark item as finished: $e');
      return false;
    }
  }

  // Get expiring items
  Future<List<Map<String, dynamic>>> getExpiringItems({
    int daysAhead = 7,
  }) async {
    try {
      final queryParams = <String, String>{
        'daysAhead': daysAhead.toString(),
      };
      
      final response = await _apiClient.get('/pantry/expiring', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get expiring items: $e');
    }
    
    return [];
  }

  // Get low stock items
  Future<List<Map<String, dynamic>>> getLowStockItems({
    int? threshold,
  }) async {
    try {
      final queryParams = <String, String>{
        if (threshold != null) 'threshold': threshold.toString(),
      };
      
      final response = await _apiClient.get('/pantry/low-stock', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to get low stock items: $e');
    }
    
    return [];
  }

  // Generate shopping list
  Future<Map<String, dynamic>?> generateShoppingList({
    bool includeExpiring = true,
    bool includeLowStock = true,
    List<String>? plannedMeals,
    int? daysAhead,
  }) async {
    try {
      final response = await _apiClient.post('/pantry/shopping-list/generate', data: {
        'includeExpiring': includeExpiring,
        'includeLowStock': includeLowStock,
        if (plannedMeals != null) 'plannedMeals': plannedMeals,
        if (daysAhead != null) 'daysAhead': daysAhead,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to generate shopping list: $e');
    }
    
    return null;
  }

  // Get pantry analytics
  Future<Map<String, dynamic>?> getPantryAnalytics({
    String period = 'month', // week, month, quarter, year
  }) async {
    try {
      final response = await _apiClient.get('/pantry/analytics', queryParameters: {
        'period': period,
      });
      
      if (response.data != null) {
        return response.data;
      }
    } catch (e) {
      print('Failed to get pantry analytics: $e');
    }
    
    return null;
  }

  // Delete pantry item
  Future<bool> deletePantryItem(String itemId) async {
    try {
      final response = await _apiClient.delete('/pantry/items/$itemId');
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to delete pantry item: $e');
      return false;
    }
  }

  // Search pantry items
  Future<List<Map<String, dynamic>>> searchPantryItems({
    String? query,
    String? category,
    bool? expiringSoon,
    bool? lowStock,
  }) async {
    try {
      final queryParams = <String, String>{
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null) 'category': category,
        if (expiringSoon != null) 'expiringSoon': expiringSoon.toString(),
        if (lowStock != null) 'lowStock': lowStock.toString(),
      };
      
      final response = await _apiClient.get('/pantry/search', queryParameters: queryParams);
      
      if (response.data != null && response.data is List) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      print('Failed to search pantry items: $e');
    }
    
    return [];
  }

  // Get pantry categories
  Future<List<String>> getPantryCategories() async {
    try {
      final response = await _apiClient.get('/pantry/categories');
      
      if (response.data != null && response.data is List) {
        return List<String>.from(response.data);
      }
    } catch (e) {
      print('Failed to get pantry categories: $e');
    }
    
    return [];
  }

  // Bulk update pantry items
  Future<bool> bulkUpdatePantryItems({
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final response = await _apiClient.post('/pantry/bulk-update', data: {
        'items': items,
      });
      
      return response.data?['success'] == true;
    } catch (e) {
      print('Failed to bulk update pantry items: $e');
      return false;
    }
  }
}