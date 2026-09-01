// This interface is intentionally kept at the domain boundary even with one method so the data layer can remain replaceable/testable
// ignore_for_file: one_member_abstracts

import 'package:milestone/core/utils/typedefs.dart';

abstract interface class UsecaseWithParams<ReturnType, Params> {
  const UsecaseWithParams();

  ResultFuture<ReturnType> call(Params params);
}

abstract interface class UsecaseWithoutParams<ReturnType> {
  const UsecaseWithoutParams();

  ResultFuture<ReturnType> call();
}

abstract interface class StreamUsecaseWithParams<ReturnType, Params> {
  const StreamUsecaseWithParams();

  ResultStream<ReturnType> call(Params params);
}

abstract interface class StreamUsecaseWithoutParams<ReturnType> {
  const StreamUsecaseWithoutParams();

  ResultStream<ReturnType> call();
}
