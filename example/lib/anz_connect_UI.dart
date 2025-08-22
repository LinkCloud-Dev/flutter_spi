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
                // Header with close button
                Row(
                  children: [
                    Icon(
                      Icons.point_of_sale,
                      color: anzState.getStatusColor(anzState.pairingFlowStatus),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'ANZ Terminal Pairing Progress',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Close button (X) in top right corner
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.black,
                      ),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current status display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: anzState.getStatusColor(anzState.pairingFlowStatus).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: anzState.getStatusColor(anzState.pairingFlowStatus).withOpacity(0.3),
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
                              color: anzState.getStatusColor(anzState.pairingFlowStatus),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pair Status: ${anzState.getStatusText(anzState.pairingFlowStatus)}${anzState.isWaitingForPairingResult ? ' (${anzState.getCurrentLoadingStatus()})' : ''}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: anzState.getStatusColor(anzState.pairingFlowStatus),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        anzState.getStatusText(anzState.connectionStatus),
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

                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepsIndicator(AnzState anzState) {
    final steps = [
      {'name': 'Connect', 'status': ANZPairingFlowStatus.idle, 'flowStatus': ANZPairingFlowStatus.connecting},
      {'name': 'Login', 'status': ANZPairingFlowStatus.connected, 'flowStatus': ANZPairingFlowStatus.loggingIn},
      {'name': 'Activate', 'status': ANZPairingFlowStatus.loggedIn, 'flowStatus': ANZPairingFlowStatus.activating},
      {'name': 'Ready', 'status': ANZPairingFlowStatus.activated, 'flowStatus': ANZPairingFlowStatus.activated},
    ];

    ANZPairingFlowStatus currentStepStatus;
    switch (anzState.pairingFlowStatus) {
      case ANZPairingFlowStatus.idle:
        currentStepStatus = ANZPairingFlowStatus.idle;
        break;
      case ANZPairingFlowStatus.connected:
        currentStepStatus = ANZPairingFlowStatus.connected;
        break;
      case ANZPairingFlowStatus.loggedIn:
        currentStepStatus = ANZPairingFlowStatus.loggedIn;
        break;
      case ANZPairingFlowStatus.activated:
        currentStepStatus = ANZPairingFlowStatus.activated;
        break;
      case ANZPairingFlowStatus.connecting:
        currentStepStatus = ANZPairingFlowStatus.connecting;
        break;
      case ANZPairingFlowStatus.loggingIn:
        currentStepStatus = ANZPairingFlowStatus.loggingIn;
        break;
      case ANZPairingFlowStatus.activating:
        currentStepStatus = ANZPairingFlowStatus.activating;
        break;
      case ANZPairingFlowStatus.failed:
        currentStepStatus = ANZPairingFlowStatus.failed;
        break;
    }

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
            final ANZPairingFlowStatus stepStatus = step['status'] as ANZPairingFlowStatus;
            final ANZPairingFlowStatus flowStatus = step['flowStatus'] as ANZPairingFlowStatus;

            final isCompleted = _isStepCompleted(currentStepStatus, stepStatus);
            final isCurrent = _isCurrentStep(anzState.pairingFlowStatus, stepStatus);

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
                          anzState.pairingFlowStatus == flowStatus ? anzState.getCurrentLoadingStatus() : step['name']!.toString(),
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

  bool _isStepCompleted(ANZPairingFlowStatus currentStatus, ANZPairingFlowStatus stepStatus) {
    // 定义配对流程的正确顺序
    final flowOrder = [
      ANZPairingFlowStatus.idle,
      ANZPairingFlowStatus.connecting,
      ANZPairingFlowStatus.connected,
      ANZPairingFlowStatus.loggingIn,
      ANZPairingFlowStatus.loggedIn,
      ANZPairingFlowStatus.activating,
      ANZPairingFlowStatus.activated,
    ];
    
    final currentIndex = flowOrder.indexOf(currentStatus);
    final stepIndex = flowOrder.indexOf(stepStatus);
    
    // 如果当前状态在流程中，且当前状态索引大于步骤索引，则步骤已完成
    if (currentIndex != -1 && stepIndex != -1) {
      return currentIndex > stepIndex;
    }
    
    // 如果当前状态是 activated，则所有步骤都已完成
    if (currentStatus == ANZPairingFlowStatus.activated) {
      return stepStatus != ANZPairingFlowStatus.activated;
    }
    
    return false;
  }

  bool _isCurrentStep(ANZPairingFlowStatus pairingFlowStatus, ANZPairingFlowStatus stepStatus) {
    // 根据配对流程状态判断当前步骤
    switch (pairingFlowStatus) {
      case ANZPairingFlowStatus.connecting:
        return stepStatus == ANZPairingFlowStatus.idle; // Connect 步骤
      case ANZPairingFlowStatus.connected:
        return stepStatus == ANZPairingFlowStatus.connected; // Connect 已完成
      case ANZPairingFlowStatus.loggingIn:
        return stepStatus == ANZPairingFlowStatus.connected; // Login 步骤
      case ANZPairingFlowStatus.loggedIn:
        return stepStatus == ANZPairingFlowStatus.loggedIn; // Login 已完成
      case ANZPairingFlowStatus.activating:
        return stepStatus == ANZPairingFlowStatus.loggedIn; // Activate 步骤
      case ANZPairingFlowStatus.activated:
        return stepStatus == ANZPairingFlowStatus.activated; // Ready 步骤
      case ANZPairingFlowStatus.failed:
        return false; // 失败时不高亮任何步骤
      case ANZPairingFlowStatus.idle:
        return false; // 空闲时不高亮任何步骤
    }
  }
}