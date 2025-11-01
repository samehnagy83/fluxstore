import 'package:graphql/client.dart';
import 'package:hive/hive.dart';

/// Hive TypeAdapter for QueryResult
///
/// Usage:
/// 1. Register adapter in main(): Hive.registerAdapter(QueryResultAdapter());
/// 2. Use directly with Hive box: await box.put('key', queryResult);
/// 3. Retrieve: final result = box.get('key') as QueryResult?;
class QueryResultAdapter extends TypeAdapter<QueryResult> {
  @override
  final int typeId =
      100; // Unique ID for this adapter (0-223 reserved for Hive)

  @override
  QueryResult read(BinaryReader reader) {
    try {
      // Read number of fields to ensure version compatibility
      final numOfFields = reader.readByte();

      final fields = <int, dynamic>{};
      for (var i = 0; i < numOfFields; i++) {
        fields[reader.readByte()] = reader.read();
      }

      // Parse data from fields
      final data =
          fields[0] is Map ? Map<String, dynamic>.from(fields[0]) : null;
      final hasException = fields[1] as bool? ?? false;
      final errorMessage = fields[2] as String?;
      final timestamp =
          fields[3] as int? ?? DateTime.now().millisecondsSinceEpoch;
      final sourceName = fields[4] as String?;

      // Create exception if there's an error
      OperationException? exception;
      if (hasException && errorMessage != null && errorMessage.isNotEmpty) {
        exception = OperationException(
          graphqlErrors: [
            GraphQLError(message: errorMessage),
          ],
        );
      }

      // Parse source
      var source = QueryResultSource.cache;
      if (sourceName != null) {
        switch (sourceName) {
          case 'network':
            source = QueryResultSource.network;
            break;
          case 'optimisticResult':
            source = QueryResultSource.optimisticResult;
            break;
          case 'loading':
            source = QueryResultSource.loading;
            break;
          default:
            source = QueryResultSource.cache;
        }
      }

      return QueryResult.internal(
        data: data,
        exception: exception,
        context: const Context(),
        source: source,
        parserFn: (data) => data,
      )..timestamp = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      // Fallback if there's an error reading data
      return QueryResult.internal(
        data: null,
        exception: OperationException(
          graphqlErrors: [
            GraphQLError(
                message: 'Failed to deserialize cached QueryResult: $e'),
          ],
        ),
        context: const Context(),
        source: QueryResultSource.cache,
        parserFn: (data) => data,
      );
    }
  }

  @override
  void write(BinaryWriter writer, QueryResult obj) {
    // Write number of fields (for future version compatibility)
    writer.writeByte(5); // Currently has 5 fields

    // Field 0: data
    writer.writeByte(0);
    writer.write(obj.data);

    // Field 1: hasException
    writer.writeByte(1);
    writer.write(obj.hasException);

    // Field 2: errorMessage
    writer.writeByte(2);
    writer.write(obj.exception?.toString() ?? '');

    // Field 3: timestamp
    writer.writeByte(3);
    writer.write(obj.timestamp.millisecondsSinceEpoch);

    // Field 4: source
    writer.writeByte(4);
    writer.write(obj.source?.name ?? 'cache');
  }
}
