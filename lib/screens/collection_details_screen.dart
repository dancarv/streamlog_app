// ignore_for_file: avoid_print, use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CollectionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> collection;

  const CollectionDetailsScreen({Key? key, required this.collection}) : super(key: key);

  @override
  _CollectionDetailsScreenState createState() => _CollectionDetailsScreenState();
}

class _CollectionDetailsScreenState extends State<CollectionDetailsScreen> {
  Map<String, dynamic>? collectionDetails;
  bool isLoading = true;
  String? userToken;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userToken = prefs.getString('jwt_token');
      userId = int.parse(prefs.getString('user_Id').toString()); // Assumindo que o ID do usuário foi salvo no login
    });
    _fetchCollectionDetails();
  }

  Future<void> _fetchCollectionDetails() async {
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/collections/${widget.collection['id']}'),
      headers: {'Authorization': 'Bearer $userToken'},
    );

    if (response.statusCode == 200) {
      setState(() {
        collectionDetails = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      print('Erro ao buscar detalhes da coleta: ${response.statusCode}');
    }
  }

  Future<void> _acceptCollection() async {
    print(userId);
    if (userId == null) return;
    final response = await http.put(
      Uri.parse('http://localhost:8080/api/collections/${widget.collection['id']}/accept?coletorId=$userId'),
      headers: {'Authorization': 'Bearer $userToken'},
    );

    if (response.statusCode == 200) {
      setState(() {
        collectionDetails!['status'] = 'em andamento';
      });
      print('Coleta aceita com sucesso!');
    } else {
      print('Erro ao aceitar coleta: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes da Coleta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : collectionDetails == null
                ? Center(child: Text('Erro ao carregar detalhes.'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID da Coleta: ${collectionDetails!['id']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text('Status: ${collectionDetails!['status']}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      Text('Endereço de Coleta: ${collectionDetails!['enderecoColetaId']}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      Text('Endereço de Entrega: ${collectionDetails!['enderecoEntregaId']}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      Text('Data de Criação: ${collectionDetails!['dataCriacao']}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 10),
                      Text('Temperatura Inicial: ${collectionDetails!['initialTemperature'] ?? 'N/A'}°C',
                          style: TextStyle(fontSize: 16, color: Colors.blue)),
                      SizedBox(height: 10),
                      Text('Temperatura Final: ${collectionDetails!['endTemperature'] ?? 'N/A'}°C',
                          style: TextStyle(fontSize: 16, color: Colors.red)),
                      SizedBox(height: 10),
                      Text('Observações: ${collectionDetails!['observacoes'] ?? 'Nenhuma observação'}',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      if (collectionDetails!['status'] == 'pendente')
                        ElevatedButton(
                          onPressed: _acceptCollection,
                          child: Text('Aceitar Coleta'),
                        ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Voltar'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
