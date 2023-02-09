class Pagination {
  int page;
  int pageSize;
  int total;
  int totalPages;
  List<dynamic> rows;

  Pagination({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
    required this.rows,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) =>
      _$PaginationFromJson(json);

  Map<String, dynamic> toJson() => {
        'page': page,
        'pageSize': pageSize,
        'total': total,
        'totalPages': totalPages,
        'rows': rows,
      };
}

Pagination _$PaginationFromJson(Map<String, dynamic> json) {
  return Pagination(
    page: json['page'],
    pageSize: json['pageSize'],
    total: json['total'],
    totalPages: json['totalPages'],
    rows: json['rows'],
  );
}
