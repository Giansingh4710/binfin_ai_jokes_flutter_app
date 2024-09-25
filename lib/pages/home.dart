import 'package:flutter/material.dart';
import 'package:binfin/api_key.dart' as apiKey;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String category = "";
  String setup = "";
  String delivery = "";
  String aiResponse = "";
  String hintText = "Guess the Joke";
  bool showDelivery = false;
  late final TextEditingController controller;

  Future<void> fetchJoke() async {
    String url =
        'https://v2.jokeapi.dev/joke/Any?type=twopart&blacklistFlags=nsfw,racist,sexist,explicit';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      setState(() {
        setup = jsonResponse['setup'];
        delivery = jsonResponse['delivery'];
        category = jsonResponse['category'];
        showDelivery = false;
        aiResponse = '';
        hintText = "Guess the Joke";
        controller.clear();
      });
    } else {
      throw Exception('Failed to load joke');
    }
  }

  Future<void> checkGuess() async {
    if (controller.text.isEmpty) {
      setState(() {
        if (hintText.split(" ")[0] == "Please") {
          hintText = hintText + "!";
        } else {
          hintText = "Please enter your guess";
        }
      });
      return;
    }

    final String userText = controller.text;
    final String prompt =
        """ I will give you a setup and the delivery of a joke.
      Let me know if the user submission is close enough to the joke or not:

      setup: $setup
      delivery: $delivery

      user submission: $userText
      Is the user submission close enough to the joke?
      """;
    print(prompt);

    const String url = 'https://api.anthropic.com/v1/messages';
    final Map<String, dynamic> data = {
      "model": "claude-3-5-sonnet-20240620",
      "max_tokens": 1024,
      "messages": [
        {"role": "user", "content": prompt},
      ]
    };

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "x-api-key": apiKey.claudeApiKey,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: json.encode(data), // Encode the map to JSON string
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final theText = responseData['content'][0]['text'];
      print("Response: $theText");
      setState(() {
        aiResponse = theText;
      });
    } else {
      print('Request failed with status: ${response.statusCode}.');
      print('Response body: ${response.body}');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    fetchJoke(); // Fetch a joke when the widget is created
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            BoxTextWidget(text: "Category: $category", size: 50),
            BoxTextWidget(text: "Setup:\n$setup", size: 150),
            if (showDelivery)
              BoxTextWidget(text: "Delivery:\n$delivery", size: 100),
            if (aiResponse.isNotEmpty)
              BoxTextWidget(text: "AI Response:\n$aiResponse", size: 150),
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: hintText,
                ),
              ),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton(
                    onPressed: fetchJoke, child: const Text('Get New Joke')),
                TextButton(
                    onPressed: () {
                      setState(() {
                        showDelivery = true;
                      });
                    },
                    child: const Text('Get Answer')),
                TextButton(
                    onPressed: checkGuess,
                    child: const Text('Check Guess with AI')),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class BoxTextWidget extends StatelessWidget {
  const BoxTextWidget({super.key, required this.text, this.size = 150.0});
  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        width: 300, // Set a fixed width
        height: size, // Set a fixed height
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue, // Border color
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SingleChildScrollView(
          // Make the text scrollable
          padding: const EdgeInsets.all(8.0), // Optional padding for the text
          child: Text(
            text,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
