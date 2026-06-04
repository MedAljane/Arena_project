class AiChatMessage {
  final String   role;      // 'user' | 'assistant'
  final String   content;
  final DateTime timestamp;
  final List<AiAction> actions; // populated for assistant messages

  const AiChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.actions = const [],
  });

  Map<String, dynamic> toHistoryJson() => {
        'role':    role,
        'content': content,
      };

  AiChatMessage copyWith({List<AiAction>? actions}) => AiChatMessage(
        role:      role,
        content:   content,
        timestamp: timestamp,
        actions:   actions ?? this.actions,
      );
}

class AiAction {
  final String                tool;
  final Map<String, dynamic>  params;

  const AiAction({required this.tool, required this.params});

  factory AiAction.fromJson(Map<String, dynamic> json) => AiAction(
        tool:   json['tool'] as String? ?? '',
        params: (json['params'] as Map<String, dynamic>?) ?? {},
      );
}

class AiChatResponse {
  final String       reply;
  final List<AiAction> actionsPerformed;

  const AiChatResponse({required this.reply, required this.actionsPerformed});

  factory AiChatResponse.fromJson(Map<String, dynamic> json) => AiChatResponse(
        reply: json['reply'] as String? ?? '',
        actionsPerformed: ((json['actionsPerformed'] as List<dynamic>?) ?? [])
            .map((e) => AiAction.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
