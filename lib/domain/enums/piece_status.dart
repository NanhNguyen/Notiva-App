/// Status of a musical piece in the repertoire.
enum PieceStatus {
  planned('Dự định'),
  learning('Đang học'),
  maintaining('Duy trì'),
  completed('Hoàn thành');

  const PieceStatus(this.label);

  final String label;
}

