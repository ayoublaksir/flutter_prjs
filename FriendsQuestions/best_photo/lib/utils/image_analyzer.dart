import 'dart:math';
import '../models/photo_analysis.dart';

class ImageAnalyzer {
  static final Map<String, List<String>> _purposeStrengths = {
    'Professional': [
      'Excellent lighting and clarity',
      'Professional attire visible',
      'Neutral background',
      'Confident pose and expression',
    ],
    'Social': [
      'Natural and relaxed expression',
      'Good environmental context',
      'Engaging composition',
      'Authentic moment captured',
    ],
    'Dating': [
      'Genuine smile and expression',
      'Good facial visibility',
      'Flattering angle',
      'Interesting background or setting',
    ],
    'Creative': [
      'Unique composition',
      'Artistic lighting',
      'Creative expression',
      'Distinctive style',
    ],
  };

  static PhotoAnalysis analyzePhotos(List<String> imagePaths, String purpose) {
    // Simulate analysis by randomly selecting a photo and generating analysis
    final random = Random();
    final selectedPath = imagePaths[random.nextInt(imagePaths.length)];
    
    // Generate random score between 75 and 95
    final score = 75.0 + random.nextDouble() * 20.0;
    
    // Get purpose-specific strengths
    final strengths = _purposeStrengths[purpose]!
        .take(random.nextInt(2) + 2)
        .toList();

    final improvements = [
      'Consider adjusting the lighting slightly',
      'Try a different angle next time',
      'Experiment with different expressions',
    ]..shuffle();

    return PhotoAnalysis(
      imagePath: selectedPath,
      score: score,
      strengths: strengths,
      improvements: improvements.take(2).toList(),
      recommendation: _generateRecommendation(purpose),
    );
  }

  static String _generateRecommendation(String purpose) {
    final recommendations = {
      'Professional': 'This photo presents you in the most professional light, with excellent composition and appropriate attire. It is perfect for LinkedIn and business profiles.',
      'Social': 'This photo captures your authentic personality and creates an engaging social media presence. It is relatable and approachable.',
      'Dating': 'This photo shows your best features and personality. It is authentic while remaining appealing and approachable.',
      'Creative': 'This photo showcases your creative side with its unique composition and artistic elements. It is perfect for artistic portfolios.',
    };

    return recommendations[purpose] ?? 'This photo best matches your selected purpose.';
  }
}