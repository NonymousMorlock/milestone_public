import 'dart:convert';

import 'package:milestone/core/utils/typedefs.dart';
import 'package:milestone/src/project/domain/entities/u_r_l.dart';

class URLModel extends URL {
  const URLModel({
    required super.url,
    required super.title,
  });

  const URLModel.empty()
      : this(
          url: 'Test String',
          title: 'Test String',
        );

  factory URLModel.fromJson(String source) =>
      URLModel.fromMap(jsonDecode(source) as DataMap);

  URLModel.fromMap(DataMap map)
      : this(
          url: map['url'] as String,
          title: map['title'] as String,
        );

  URLModel copyWith({
    String? url,
    String? title,
  }) {
    return URLModel(
      url: url ?? this.url,
      title: title ?? this.title,
    );
  }

  DataMap toMap() {
    return <String, dynamic>{
      'url': url,
      'title': title,
    };
  }

  String toJson() => jsonEncode(toMap());
}
