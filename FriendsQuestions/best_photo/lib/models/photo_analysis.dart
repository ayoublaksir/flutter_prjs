class PhotoAnalysis {
  final String imagePath;
  final double score;
  final List<String> strengths;
  final List<String> improvements;
  final String recommendation;

  PhotoAnalysis({
    required this.imagePath,
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.recommendation,
  });
}