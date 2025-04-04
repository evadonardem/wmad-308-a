import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BreedsScreen extends StatefulWidget {
  final Function(String) onBreedSelect;

  BreedsScreen({required this.onBreedSelect});

  @override
  _BreedsScreenState createState() => _BreedsScreenState();
}

class _BreedsScreenState extends State<BreedsScreen> {
  List<String> breeds = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchBreeds();
  }

  Future<void> fetchBreeds() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response =
          await http.get(Uri.parse('https://dog.ceo/api/breeds/list/all'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body)['message'];
        List<String> fetchedBreeds = [];

        data.forEach((key, value) {
          if ((value as List).isEmpty) {
            fetchedBreeds.add(key);
          } else {
            for (var sub in value) {
              fetchedBreeds.add('$key $sub');
            }
          }
        });

        setState(() {
          breeds = fetchedBreeds..sort();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch breed list');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching breeds. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select a Breed')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child:
                      Text(errorMessage!, style: TextStyle(color: Colors.red)))
              : ListView.builder(
                  itemCount: breeds.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(breeds[index]),
                      onTap: () {
                        widget.onBreedSelect(breeds[index]);
                      },
                    );
                  },
                ),
    );
  }
}
