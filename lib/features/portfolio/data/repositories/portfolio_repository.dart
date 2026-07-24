import '../../../../core/supabase/supabase_service.dart';
import '../models/portfolio_transaction.dart';

abstract class PortfolioRepository {
  Future<List<PortfolioTransaction>> getTransactions(String userId);
  Future<void> addTransaction(PortfolioTransaction transaction);
}

class SupabasePortfolioRepository implements PortfolioRepository {
  @override
  Future<List<PortfolioTransaction>> getTransactions(String userId) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase not initialized');

    final response = await client
        .from('portfolio_transactions')
        .select('*, funds(name_ar, name_en)')
        .eq('user_id', userId)
        .order('transaction_date', ascending: false);

    return (response as List).map((e) => PortfolioTransaction.fromJson(e)).toList();
  }

  @override
  Future<void> addTransaction(PortfolioTransaction transaction) async {
    final client = SupabaseService.client;
    if (client == null) throw Exception('Supabase not initialized');

    await client.from('portfolio_transactions').insert(transaction.toJson());
  }
}
