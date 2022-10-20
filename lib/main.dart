import 'package:email_client/connectors/gmail.dart';
import 'package:email_client/models/conversation.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MailboxPage(title: 'Inbox'),
    );
  }
}

class ReaderPage extends StatelessWidget {
  final Conversation conversation;

  const ReaderPage({super.key, required this.conversation});

  @override
  Widget build(BuildContext context) {
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(conversation.from),
          Text(conversation.subject),
          Expanded(
              child: SingleChildScrollView(
                  child: conversation.messages.first.body))
        ]);
  }
}

class MailboxPage extends StatefulWidget {
  final String title;

  const MailboxPage({super.key, required this.title});

  @override
  State<MailboxPage> createState() => _MailboxPageState();
}

class _MailboxPageState extends State<MailboxPage> {
  List<Conversation> threads = [];
  Conversation? selectedConversation;

  @override
  void initState() {
    super.initState();
    setup();
  }

  void setup() async {
    final conn = GmailConnector();
    await conn.init();

    final newThreads = await conn.refresh();
    setState(() {
      threads = newThreads;
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagePane = (selectedConversation == null)
        ? (const Text("No Selected Conversation"))
        : (ReaderPage(conversation: selectedConversation!));
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: threads.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedConversation = threads[index];
                    });
                  },
                  child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(threads[index].from),
                            Text(threads[index].subject),
                            Text(threads[index].preview),
                          ])),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
          Expanded(flex: 3, child: Center(child: messagePane))
        ],
      ),
    );
  }
}
