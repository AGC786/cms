/// Runs [action] over every item in [items], [batchSize] at a time
/// concurrently, awaiting each batch before starting the next.
///
/// Firing hundreds of requests all at once via a single `Future.wait`
/// (e.g. marking every unread notification as read for an account with
/// 200+ unseen items) saturates the HTTP client's connection pool —
/// requests start timing out or failing outright, which both makes the
/// operation feel stuck and can silently leave some items unmarked on
/// the backend even though the UI reports success. Chunking keeps a
/// bounded number of requests in flight at once instead.
Future<void> runInBatches<T>(
  List<T> items,
  Future<void> Function(T item) action, {
  int batchSize = 8,
}) async {
  for (var i = 0; i < items.length; i += batchSize) {
    final batch = items.skip(i).take(batchSize);
    await Future.wait(batch.map(action));
  }
}
