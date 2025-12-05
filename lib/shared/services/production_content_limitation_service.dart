import 'package:flutter_news_app_mobile_client_full_source_code/shared/services/content_limitation_service.dart';

/// {@template production_content_limitation_service}
/// A "no-op" implementation of [ContentLimitationService] for production.
///
/// In a production environment, all limit enforcement is handled by the
/// backend. The client's responsibility is to react to `ForbiddenException`
/// errors returned by the API. Therefore, this service always returns
/// [LimitationStatus.allowed], allowing all actions to proceed to the
/// repository layer.
/// {@endtemplate}
class ProductionContentLimitationService implements ContentLimitationService {
  @override
  LimitationStatus checkAction(ContentAction action) {
    return LimitationStatus.allowed;
  }

  @override
  void incrementActionCount(ContentAction action) {
    // No-op for production, as counts are managed by the backend.
    return;
  }
}
