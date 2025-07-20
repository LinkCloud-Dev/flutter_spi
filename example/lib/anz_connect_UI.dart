import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'anz_state.dart';

class AnzConnectUI extends StatelessWidget {
  const AnzConnectUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnzState>(
      builder: (context, anzState, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.point_of_sale,
                      color: anzState.getStatusColor(),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ANZ Terminal Connection',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current status display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: anzState.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: anzState.getStatusColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: anzState.getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${anzState.getStatusText()}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: anzState.getStatusColor(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        anzState.getConnectionStatusText(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Connection steps indicator
                _buildStepsIndicator(anzState),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: anzState.status.name == 'disconnected' 
                            ? () => anzState.startConnection()
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: anzState.getStatusColor(),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          anzState.status.name == 'disconnected' 
                              ? 'Connect Terminal'
                              : 'Connecting...',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Close button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepsIndicator(AnzState anzState) {
    final steps = [
      {'name': 'Connect', 'status': 'disconnected'},
      {'name': 'Login', 'status': 'connected'},
      {'name': 'Activate', 'status': 'loggedIn'},
      {'name': 'Ready', 'status': 'activated'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Connection Steps:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = _isStepCompleted(anzState, step['status']!);
            final isCurrent = _isCurrentStep(anzState, step['status']!);
            
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted 
                                ? Colors.green 
                                : isCurrent 
                                    ? Colors.orange 
                                    : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: isCompleted 
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : isCurrent 
                                  ? const Icon(Icons.hourglass_empty, color: Colors.white, size: 16)
                                  : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step['name']!,
                          style: TextStyle(
                            fontSize: 10,
                            color: isCompleted || isCurrent 
                                ? Colors.black87 
                                : Colors.grey[500],
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? Colors.green : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isStepCompleted(AnzState anzState, String stepStatus) {
    switch (stepStatus) {
      case 'disconnected':
        return anzState.status.name != 'disconnected';
      case 'connected':
        return ['connected', 'loggingIn', 'loggedIn', 'activating', 'activated']
            .contains(anzState.status.name);
      case 'loggedIn':
        return ['loggedIn', 'activating', 'activated']
            .contains(anzState.status.name);
      case 'activated':
        return anzState.status.name == 'activated';
      default:
        return false;
    }
  }

  bool _isCurrentStep(AnzState anzState, String stepStatus) {
    switch (stepStatus) {
      case 'disconnected':
        return anzState.status.name == 'connecting';
      case 'connected':
        return anzState.status.name == 'loggingIn';
      case 'loggedIn':
        return anzState.status.name == 'activating';
      case 'activated':
        return anzState.status.name == 'activated';
      default:
        return false;
    }
  }
}