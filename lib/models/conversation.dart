import 'message.dart';

class Conversation {
  final String from;
  final String subject;
  final String preview;
  final List<Message> messages;

  const Conversation(this.from, this.subject, this.preview, this.messages);
}
