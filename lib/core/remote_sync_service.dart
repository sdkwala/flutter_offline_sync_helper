import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/sync_status.dart';

abstract class RemoteSyncService<T> {
  Future<SyncResult> sync(List<T> models, {List<SyncAction>? actions});
}

class HttpSyncService<T> implements RemoteSyncService<T> {
  final String endpoint;
  final Map<String, dynamic> Function(T model) serializer;

  HttpSyncService(this.endpoint,this.serializer);
  @override
  Future<SyncResult> sync(List<T> models, {List<SyncAction>? actions}) async {
    final failed = <T>[];
    final conflicts = <T>[];

    for (int i = 0; i < models.length; i++) {
      final model = models[i];
      final action = actions != null && actions.length > i ? actions[i] : SyncAction.create;
      try {
        final data = serializer(model);
        print("Sending: $data with action: $action");
        http.Response response;
        if (action == SyncAction.create) {
          response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
        } else if (action == SyncAction.update) {
          print(":::::::::::updated id:::${data['id']}:::");
          response = await http.put(
            Uri.parse('$endpoint/${data['id']}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
        } else if (action == SyncAction.delete) {
          print(":::::::::::deleted id:::${data['id']}:::");
          response = await http.delete(
            Uri.parse('$endpoint/${data['id']}'),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          response = await http.post(
            Uri.parse(endpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          );
        }
        if (response.statusCode != 201 && response.statusCode != 200) {
          failed.add(model);
        }
      } catch (e) {
        failed.add(model);
      }
    }

    return SyncResult(
      success: failed.isEmpty,
      syncedCount: models.length - failed.length,
      failedCount: failed.length,
      conflicts: conflicts,
    );
  }

//
//   @override
// Future<SyncResult> sync(List<T> models) async {
//     try {
//       final response = await http.post(
//         Uri.parse(endpoint),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'data': models}),
//       );
//       if (response.statusCode == 200) {
//         return SyncResult(success: true);
//       } else {
//         return SyncResult(success: false, error: response.body);
//       }
//     } catch (e) {
//       return SyncResult(success: false, error: e.toString());
//     }
//   }
}