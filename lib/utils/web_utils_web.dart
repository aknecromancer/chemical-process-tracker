import 'dart:convert';
import 'dart:html' as html;

void downloadCSV(String csvData, String filename) {
  final bytes = utf8.encode(csvData);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  
  html.Url.revokeObjectUrl(url);
}