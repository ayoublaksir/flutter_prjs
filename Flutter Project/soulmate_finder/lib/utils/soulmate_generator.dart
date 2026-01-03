import '../models/soulmate_profile.dart';
import '../models/user_data.dart';
import 'dart:math';

class SoulmateGenerator {
  static final List<Map<String, dynamic>> soulmateTypes = [
    {
      'type': 'Cosmic Adventurer',
      'description': 'Your soulmate is an interdimensional explorer who collects stardust for fun.',
      'images': ['assets/images/cosmic_1.png', 'assets/images/cosmic_2.png']
    },
    {
      'type': 'Time-Traveling Artist',
      'description': 'They paint masterpieces using colors that haven\'t been invented yet.',
      'images': ['assets/images/artist_1.png', 'assets/images/artist_2.png']
    },
    {
      'type': 'Mystic Chef',
      'description': 'They cook meals that can make you taste memories from your past lives.',
      'images': ['assets/images/chef_1.png', 'assets/images/chef_2.png']
    },
  ];

  static SoulmateProfile generateSoulmate(UserData userData) {
    final random = Random();
    final soulmateType = soulmateTypes[random.nextInt(soulmateTypes.length)];

    return SoulmateProfile(
      name: generateName(),
      age: userData.age + random.nextInt(5) - 2,
      imageAsset: 'assets/images/placeholder.png', // Use a default placeholder image
      description: soulmateType['description'],
      traits: generateTraits(userData),
      compatibilityReason: generateCompatibilityReason(userData),
    );
  }

  static String generateName() {
    final List<String> firstNames = ['Luna', 'Phoenix', 'Storm', 'Echo', 'Zen'];
    final List<String> lastNames = ['Starweaver', 'Moonwhisper', 'Cloudchaser', 'Dreamweaver'];
    final random = Random();
    return '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}';
  }

  static String generateCompatibilityReason(UserData userData) {
    final List<String> reasons = [
      "Your cosmic energy perfectly aligns with their starlight frequency!",
      "The universe has been preparing this match for seven lifetimes!",
      "Your auras dance in perfect harmony!",
      "The celestial alignment confirms you're meant to be!",
    ];

    return reasons[Random().nextInt(reasons.length)];
  }

  static Map<String, String> generateTraits(UserData userData) {
    final Map<String, String> traits = {
      'Cosmic Power': _generateCosmicPower(),
      'Dream Skill': _generateDreamSkill(),
      'Magic Specialty': _generateMagicSpecialty(),
      'Spirit Element': _generateSpiritElement(),
    };
    return traits;
  }

  static String _generateCosmicPower() {
    final powers = [
      'Starlight Whispering',
      'Moonbeam Dancing',
      'Aurora Crafting',
      'Galaxy Painting',
    ];
    return powers[Random().nextInt(powers.length)];
  }

  static String _generateDreamSkill() {
    final skills = [
      'Cloud Surfing',
      'Rainbow Weaving',
      'Meteor Juggling',
      'Constellation Drawing',
    ];
    return skills[Random().nextInt(skills.length)];
  }

  static String _generateMagicSpecialty() {
    final specialties = [
      'Time Bending',
      'Dimension Hopping',
      'Memory Painting',
      'Wish Granting',
    ];
    return specialties[Random().nextInt(specialties.length)];
  }

  static String _generateSpiritElement() {
    final elements = [
      'Stardust',
      'Moonlight',
      'Cosmic Wind',
      'Celestial Fire',
    ];
    return elements[Random().nextInt(elements.length)];
  }
}