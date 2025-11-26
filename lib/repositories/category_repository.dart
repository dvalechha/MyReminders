import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category.dart';

/// Repository for Category operations with Supabase
class CategoryRepository {
  final SupabaseClient _client;

  CategoryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Get all categories
  /// Categories are read-only for all authenticated users
  Future<List<Category>> getAll() async {
    try {
      final response = await _client
          .from('category')
          .select()
          .order('name');

      return (response as List)
          .map((json) => Category.fromMap(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get a category by ID
  Future<Category?> getById(String id) async {
    try {
      final response = await _client
          .from('category')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Category.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Failed to fetch category: $e');
    }
  }

  /// Get a category by name
  Future<Category?> getByName(String name) async {
    try {
      final response = await _client
          .from('category')
          .select()
          .eq('name', name)
          .maybeSingle();

      if (response == null) return null;
      return Category.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Failed to fetch category by name: $e');
    }
  }
}

