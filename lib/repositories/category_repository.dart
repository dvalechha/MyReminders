import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart' as models;

/// Repository for Category operations with Supabase
class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all categories
  /// Categories are read-only for all authenticated users
  Future<List<models.Category>> getAll() async {
    try {
      final response = await _client
          .from('category')
          .select()
          .order('name');

      return (response as List)
          .map((json) => models.Category.fromMap(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get a category by ID
  Future<models.Category?> getById(String id) async {
    try {
      final response = await _client
          .from('category')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return models.Category.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Get a category by name
  Future<models.Category?> getByName(String name) async {
    try {
      debugPrint('🔍 [CategoryRepository] Looking up category by name: "$name"');
      final response = await _client
          .from('category')
          .select()
          .eq('name', name)
          .maybeSingle();

      debugPrint('🔍 [CategoryRepository] Response: $response');
      
      if (response == null) {
        debugPrint('⚠️ [CategoryRepository] No category found with name: "$name"');
        // Try case-insensitive search
        debugPrint('🔍 [CategoryRepository] Trying case-insensitive search...');
        final allCategories = await getAll();
        debugPrint('🔍 [CategoryRepository] All categories: ${allCategories.map((c) => c.name).toList()}');
        final match = allCategories.where((c) => c.name.toLowerCase() == name.toLowerCase()).firstOrNull;
        if (match != null) {
          debugPrint('✅ [CategoryRepository] Found case-insensitive match: ${match.name} (id: ${match.id})');
          return match;
        }
        return null;
      }
      final category = models.Category.fromMap(Map<String, dynamic>.from(response));
      debugPrint('✅ [CategoryRepository] Found category: ${category.name} (id: ${category.id})');
      return category;
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error fetching category by name: $e');
      throw Exception('Failed to fetch category by name: $e');
    }
  }
}

