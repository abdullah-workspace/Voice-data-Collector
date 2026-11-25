import 'package:flutter/material.dart';

class MetadataValues {
  final String environment;
  final String distance;
  final String noiseLevel;
  final String notes;

  const MetadataValues({
    required this.environment,
    required this.distance,
    required this.noiseLevel,
    required this.notes,
  });
}

/// Metadata input form for the review screen.
class MetadataForm extends StatefulWidget {
  final String initialEnvironment;
  final String initialDistance;
  final String initialNoiseLevel;
  final String initialNotes;
  final ValueChanged<MetadataValues> onChanged;

  const MetadataForm({
    super.key,
    required this.initialEnvironment,
    required this.initialDistance,
    required this.initialNoiseLevel,
    this.initialNotes = '',
    required this.onChanged,
  });

  static const List<String> environments = [
    'bedroom',
    'living room',
    'kitchen',
    'outdoor',
    'street',
    'hallway',
    'other',
  ];

  static const List<String> distances = [
    'near (<1m)',
    'medium (1–3m)',
    'far (>3m)',
  ];

  static const List<String> noiseLevels = [
    'quiet',
    'moderate',
    'noisy',
  ];

  @override
  State<MetadataForm> createState() => _MetadataFormState();
}

class _MetadataFormState extends State<MetadataForm> {
  late String _selectedEnvironment;
  late String _selectedDistance;
  late String _selectedNoiseLevel;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedEnvironment = MetadataForm.environments.contains(widget.initialEnvironment)
        ? widget.initialEnvironment
        : MetadataForm.environments.first;

    _selectedDistance = MetadataForm.distances.contains(widget.initialDistance)
        ? widget.initialDistance
        : MetadataForm.distances[1];

    _selectedNoiseLevel = MetadataForm.noiseLevels.contains(widget.initialNoiseLevel)
        ? widget.initialNoiseLevel
        : MetadataForm.noiseLevels[1];

    _notesController = TextEditingController(text: widget.initialNotes);
    _notesController.addListener(_notify);
  }

  void _notify() {
    widget.onChanged(
      MetadataValues(
        environment: _selectedEnvironment,
        distance: _selectedDistance,
        noiseLevel: _selectedNoiseLevel,
        notes: _notesController.text.trim(),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Environment Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedEnvironment,
          decoration: const InputDecoration(
            labelText: 'Environment',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
          items: MetadataForm.environments.map((env) {
            return DropdownMenuItem<String>(
              value: env,
              child: Text(env),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedEnvironment = val);
              _notify();
            }
          },
        ),
        const SizedBox(height: 14),

        // Distance Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedDistance,
          decoration: const InputDecoration(
            labelText: 'Distance',
            prefixIcon: Icon(Icons.straighten_outlined),
            border: OutlineInputBorder(),
          ),
          items: MetadataForm.distances.map((dist) {
            return DropdownMenuItem<String>(
              value: dist,
              child: Text(dist),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedDistance = val);
              _notify();
            }
          },
        ),
        const SizedBox(height: 14),

        // Noise Level Dropdown
        DropdownButtonFormField<String>(
          initialValue: _selectedNoiseLevel,
          decoration: const InputDecoration(
            labelText: 'Background Noise Level',
            prefixIcon: Icon(Icons.volume_up_outlined),
            border: OutlineInputBorder(),
          ),
          items: MetadataForm.noiseLevels.map((lvl) {
            return DropdownMenuItem<String>(
              value: lvl,
              child: Text(lvl),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedNoiseLevel = val);
              _notify();
            }
          },
        ),
        const SizedBox(height: 14),

        // Notes Text Field
        TextFormField(
          controller: _notesController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notes (optional)',
            hintText: 'e.g. solid wood door, TV on in background',
            prefixIcon: Icon(Icons.notes_outlined),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
