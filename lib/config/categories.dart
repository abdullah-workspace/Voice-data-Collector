import 'package:flutter/material.dart';

/// Represents a sound category for data collection.
class SoundCategory {
  final String id;
  final String displayName;
  final IconData icon;
  final String folderName;
  final String description;

  const SoundCategory({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.folderName,
    required this.description,
  });

  /// All available sound categories for data collection.
  static const List<SoundCategory> allCategories = [
    SoundCategory(
      id: 'clapping',
      displayName: 'Clapping',
      icon: Icons.back_hand,
      folderName: 'clapping',
      description: 'Hand clapping sounds at various speeds and intensities',
    ),
    SoundCategory(
      id: 'doorbell',
      displayName: 'Doorbell',
      icon: Icons.doorbell,
      folderName: 'doorbell',
      description: 'Doorbell ringing sounds from different types of doorbells',
    ),
    SoundCategory(
      id: 'door_knock',
      displayName: 'Door Knock',
      icon: Icons.door_front_door,
      folderName: 'door_knock',
      description: 'Knocking on doors with varying force and patterns',
    ),
    SoundCategory(
      id: 'baby_cry',
      displayName: 'Baby Cry',
      icon: Icons.child_care,
      folderName: 'baby_cry',
      description: 'Baby crying and infant vocal sounds',
    ),
    SoundCategory(
      id: 'microwave_oven',
      displayName: 'Microwave Oven',
      icon: Icons.microwave,
      folderName: 'microwave_oven',
      description: 'Microwave oven beeps, humming, and timer sounds',
    ),
    SoundCategory(
      id: 'background_noise',
      displayName: 'Background Noise',
      icon: Icons.noise_aware,
      folderName: 'background_noise',
      description: 'Ambient background noise for negative class training',
    ),
  ];

  /// Returns the [SoundCategory] matching the given [id], or `null` if not found.
  static SoundCategory? getCategoryById(String id) {
    try {
      return allCategories.firstWhere((category) => category.id == id);
    } on StateError {
      return null;
    }
  }
}
