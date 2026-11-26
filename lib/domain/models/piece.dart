import '../enums/piece_status.dart';

/// Domain model for a musical piece.
class Piece {
  const Piece({
    required this.id,
    this.userId,
    required this.title,
    this.composer,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String? userId;
  final String title;
  final String? composer;
  final PieceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Piece copyWith({
    String? id,
    String? userId,
    String? title,
    String? composer,
    bool clearComposer = false,
    PieceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Piece(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      composer: clearComposer ? null : (composer ?? this.composer),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

