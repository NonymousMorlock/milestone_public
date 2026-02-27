import 'package:equatable/equatable.dart';

class URL extends Equatable {
  const URL({
    required this.url,
    required this.title,
  });

  const URL.empty()
      : this(
          url: 'Test String',
          title: 'Test String',
        );

  final String url;
  final String title;

  @override
  List<Object?> get props => [url, title];
}
