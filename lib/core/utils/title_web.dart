// Ignore this rule because this is only called when in a web environment
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;

void setPageTitle(String title) {
  html.document.title = title;
}
