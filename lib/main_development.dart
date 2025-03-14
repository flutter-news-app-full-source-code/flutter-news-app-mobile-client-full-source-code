import 'package:ht_headlines_inmemory/ht_headlines_inmemory.dart';
import 'package:ht_headlines_repository/ht_headlines_repository.dart';
import 'package:ht_main/app/app.dart';
import 'package:ht_main/bootstrap.dart';

void main() {
  final headlinesClient = HtInMemoryHeadlinesClient();
  final headlinesRepository = HtHeadlinesRepository(client: headlinesClient);
  bootstrap(() => AppPage(htHeadlinesRepository: headlinesRepository));
}
