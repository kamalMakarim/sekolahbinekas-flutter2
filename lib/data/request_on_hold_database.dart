import 'package:sekolahbinekas/data/user_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_on_hold.dart';
import '../models/request_on_hold_detail.dart';

class RequestOnHoldDatabase {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<RequestOnHold>> getRequestOnHolds() async {
    final response = await _client.from('request_on_hold').select();
    return (response as List)
        .map((e) => RequestOnHold.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RequestOnHoldDetail>> getRequestOnHoldDetails() async {
    final response = await _client.from('request_on_hold_detail').select();
    return (response as List)
        .map((e) => RequestOnHoldDetail.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}