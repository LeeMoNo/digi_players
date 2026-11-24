import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api/api_client.dart';

/// 用和档案相同的网络客户端把已经上传的头像拉下来。
Future<Uint8List?> fetchAvatarBytes(String url) async {
  try {
    final response = await ApiClient.dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    if (data is Uint8List) return data;
    return Uint8List.fromList(data);
  } catch (e) {
    debugPrint('[档案] 头像图片下载失败：$e');
    return null;
  }
}
