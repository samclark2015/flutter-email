import 'dart:convert';

import 'package:email_client/models/conversation.dart';
import 'package:email_client/models/message.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:collection/collection.dart'; // <- required or firstWhereOrNull is not defined

const AUTH_KEY = "GMAIL_AUTH";
const CLIENT_ID =
    "211265239316-cbmqt8svcd8f0svbjjr2pd6dnc7tigrq.apps.googleusercontent.com";
const CLIENT_SECRET = "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";

class GmailConnector {
  final _clientId = ClientId(CLIENT_ID, CLIENT_SECRET);
  final _storage = const FlutterSecureStorage();
  final _unescape = HtmlUnescape();

  AccessCredentials? _creds;
  AuthClient? _client;
  gmail.GmailApi? _api;

  Future<void> init() async {
    final auth = await _storage.read(key: AUTH_KEY);
    if (auth != null) {
      _creds = AccessCredentials.fromJson(jsonDecode(auth));
      if (_creds!.accessToken.hasExpired) {
        _creds = await _refreshCreds(_creds!);
      }
    } else {
      _creds = await _authenticate();
    }

    if (_creds != null) {
      _client = authenticatedClient(http.Client(), _creds!);
      _api = gmail.GmailApi(_client!);
    }
  }

  Future<List<Conversation>> refresh() async {
    final threads = _api?.users.threads;
    final listing = await threads?.list("me", maxResults: 100);

    final List<Conversation> conversations = await Future.wait(
        listing?.threads?.map(loadConversation).toList() ?? []);
    return conversations;
  }

  Future<Conversation> loadConversation(thread) async {
    var tdata = await _api?.users.threads.get("me", thread.id!);
    List<Message> messages =
        await Future.wait(tdata?.messages?.map(loadMessage).toList() ?? []);
    var from = messages.first.from;
    var subject = messages.first.subject;
    var preview = _unescape.convert(thread.snippet ?? "No Preview");

    return Conversation(from, subject, preview, messages);
  }

  Future<Message> loadMessage(gmail.Message message) async {
    var from =
        message.payload?.headers?.firstWhere((h) => h.name == "From").value ??
            "No Sender";
    var subject = message.payload?.headers
            ?.firstWhere((h) => h.name == "Subject")
            .value ??
        "No Subject";
    final decoder = utf8.fuse(base64);
    Widget body;
    // var body =
    //     _unescape.convert(decoder.decode(message?.payload?.body?.data ?? ""));
    if (message.payload?.parts?.isNotEmpty ?? false) {
      gmail.MessagePart? html = message.payload?.parts
          ?.firstWhereOrNull((part) => part.mimeType == "text/html");
      if (html != null) {
        final data = _unescape.convert(decoder.decode(html.body?.data ?? ""));
        body = Html(data: data);
      } else {
        body = Text("Fuck!");
      }
    } else {
      body = Text(
          _unescape.convert(decoder.decode(message.payload?.body?.data ?? "")));
    }
    return Message(from, subject, body);
  }

  Future<AccessCredentials?> _authenticate() async {
    final client = http.Client();
    final creds = await obtainAccessCredentialsViaUserConsent(
        _clientId, [gmail.GmailApi.gmailReadonlyScope], client, _prompt);

    _storage.write(key: AUTH_KEY, value: jsonEncode(creds.toJson()));
    return creds;
  }

  Future<AccessCredentials> _refreshCreds(AccessCredentials creds) async {
    final client = http.Client();
    final newCreds = await refreshCredentials(_clientId, creds, client);
    _storage.write(key: AUTH_KEY, value: jsonEncode(newCreds.toJson()));
    return newCreds;
  }

  void _prompt(String url) async {
    await launchUrl(Uri.parse(url));
  }
}
