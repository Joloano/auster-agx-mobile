typedef JsonMap = Map<String, dynamic>;

class PageResponse<T> {
  const PageResponse({
    required this.items,
    required this.totalItems,
    required this.totalPages,
    required this.page,
    required this.pageSize,
  });

  factory PageResponse.fromJson(
    JsonMap json,
    T Function(JsonMap json) decode,
  ) {
    final rawItems = json['conteudo'];
    return PageResponse<T>(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => decode(Map<String, dynamic>.from(item)))
              .toList(growable: false)
          : const [],
      totalItems: _asInt(json['totalElementos']),
      totalPages: _asInt(json['totalPaginas']),
      page: _asInt(json['pagina']),
      pageSize: _asInt(json['tamanho'], fallback: 20),
    );
  }

  final List<T> items;
  final int totalItems;
  final int totalPages;
  final int page;
  final int pageSize;

  bool get hasNextPage => page + 1 < totalPages;
  bool get hasPreviousPage => page > 0;
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
