enum ChatRole { user, model }

class ChatMessage {
  final ChatRole role;
  final String text;

  ChatMessage({required this.role, required this.text});
}
