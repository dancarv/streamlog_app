import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'collection_details_screen.dart';

// ignore: use_key_in_widget_constructors
class HomeScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? userToken;
  List<Map<String, dynamic>> collections = [];

  @override
  void initState() {
    super.initState();
    _loadUserToken();
  }

  Future<void> _loadUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userToken = prefs.getString('jwt_token');
    });
    if (userToken != null) {
      _fetchCollections();
    }
  }

  Future<void> _fetchCollections() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/collections/available'),
      headers: {'Authorization': 'Bearer $userToken'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);
      setState(() {
        collections = responseData.cast<Map<String, dynamic>>();
      });
    } else {
      // ignore: avoid_print
      print('Erro ao buscar coletas: ${response.statusCode}');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tela Principal'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: userToken == null
          ? Center(child: CircularProgressIndicator())
          : collections.isEmpty
              ? Center(child: Text('Nenhuma coleta disponível'))
              : ListView.builder(
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    return Card(
                      child: ListTile(
                        title: Text('Coleta ID: ${collection['id']}'),
                        subtitle: Text('Status: ${collection['status']}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CollectionDetailsScreen(collection: collection),
                            ),
                          ).then((_) {
                            _fetchCollections(); // Atualiza a lista APÓS o retorno
                          });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}