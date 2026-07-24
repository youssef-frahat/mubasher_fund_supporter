import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String _supabaseUrl = 'https://maorabzkqtqmlrakqlya.supabase.co';
  static const String _supabaseAnonKey = 'sb_publishable_wok63F-3n02BsQTgPvHPxw_gJTyGWU7'; 

  static Future<void> initialize() async {
 
    await Supabase.initialize(
      url: _supabaseUrl,
      anonKey: _supabaseAnonKey,
    );
    
  }

  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (e) {
      // Return null if not initialized yet
      return null;
    }
  }
}
