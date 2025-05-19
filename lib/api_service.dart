// lib/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> uploadImage(File imageFile) async {
  // Replace with your backend's IP or URL
  var uri = Uri.parse('https://5c39-112-134-162-211.ngrok-free.app/predict');
  var request = http.MultipartRequest('POST', uri);

  // Attach the image file with the key 'file'
  request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

  // Send the request and wait for the response
  var response = await request.send();
  if (response.statusCode == 200) {
    // Convert the streamed response into a string then decode the JSON
    var responseData = await response.stream.bytesToString();
    return json.decode(responseData);
  } else {
    throw Exception('Failed to upload image: ${response.statusCode}');
  }
}
