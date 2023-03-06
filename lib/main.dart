///
/// Author: @m-f-1998
/// Description: 'Search-as-you-Type' over Google Books API, with Loading Indicator
/// Framework: https://flutter.dev
///

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:book_finder/debouncer.dart';

Future main() async {
  await dotenv.load(fileName: "lib/.env"); // Enviroment File For API Key
  runApp(const BookFinder());
}

// MARK: Framework for State

class BookFinder extends StatelessWidget {
  // Customisation of Theme, Route, etc.
  const BookFinder({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SearchAPI(),
    );
  }
}

class SearchAPI extends StatefulWidget {
  const SearchAPI({super.key});

  @override
  State<SearchAPI> createState() => _SearchState();
}

// MARK: Controllers

class _SearchState extends State<SearchAPI> {
  // MARK: API Constants
  final List<String> _dataFields = [
    'volumeInfo/description',
    'volumeInfo/title',
    'volumeInfo/imageLinks/smallThumbnail'
  ];
  final String _title = 'Book Finder Using Google API';
  final List<Book> _searchResult = [];

  // MARK: Controller Constants
  bool _invalid = false, _loading = false;
  final Debouncer _debouncer = Debouncer(milliseconds: 2000);
  TextEditingController controller = TextEditingController();

  Future<void> getAPI(String query) async {
    query = query.toLowerCase().replaceAll(' ', '-');
    final res = await http.get(Uri.parse(
        'https://googleapis.com/books/v1/volumes?key=${dotenv.env['GOOGLE_API']}&fields=items(${_dataFields.join(',')})&langRestrict=en&q=$query'));
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      setState(() {
        if (data.containsKey('items')) {
          for (Map book in data['items']) {
            _searchResult.add(Book.fromJson(book));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        elevation: 0.0,
      ),
      body: Column(
        children: <Widget>[
          Container(
            color: Theme.of(context).primaryColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.search),
                  title: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      border: InputBorder.none,
                      errorText: (_invalid ? 'Invalid Character' : null),
                    ),
                    onChanged: onSearchTextChanged,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel),
                    onPressed: () {
                      controller.clear();
                      onSearchTextChanged('');
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_searchResult.isEmpty
                      ? const Center(child: Text('No Books To Show'))
                      : ListView.builder(
                          itemCount: _searchResult.length,
                          itemBuilder: (context, i) {
                            return Card(
                              margin: const EdgeInsets.all(0.0),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    _searchResult[i].image,
                                  ),
                                ),
                                title: Text(_searchResult[i].title),
                                subtitle: Text(
                                  _searchResult[i].description,
                                  maxLines: 2,
                                ),
                              ),
                            );
                          },
                        ))),
        ],
      ),
    );
  }

  onSearchTextChanged(String search) async {
    _searchResult.clear();
    setState(() {});
    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(search)) {
      // For Simplicity Sake, No Special Characters
      _invalid = true;
    } else if (search != "") {
      _loading = true;
      _invalid = false;
      _debouncer.run(() => {
            // Wait Until User Stops Typing for 2 Seconds Then Search
            if (search.isNotEmpty)
              {
                getAPI(search).asStream().listen((event) {
                  _loading = false;
                })
              } // If 'search' is empty then results already cleared
          });
    }
  }
}

// MARK: JSON Framework

class Book {
  final String title, description, image;

  Book({required this.title, required this.description, required this.image});

  factory Book.fromJson(Map json) {
    return Book(
        title: json["volumeInfo"]["title"],
        description: json["volumeInfo"]["description"] ?? "",
        image: json["volumeInfo"]["imageLinks"]["smallThumbnail"] ?? "");
  }
}
