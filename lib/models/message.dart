import 'package:flutter/widgets.dart';

class Message {
  final String from;
  final String subject;
  final Widget body;

  const Message(this.from, this.subject, this.body);
}
