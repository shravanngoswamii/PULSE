class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: (json['data'] != null && fromJsonT != null) ? fromJsonT(json['data']) : null,
      message: json['message'],
      errors: json['errors'],
    );
  }
}
