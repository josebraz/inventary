
extension StringExtension on String {

  String onEmpty(String text) {
    if (this.isEmpty) {
      return text;
    } else {
      return this;
    }
  }
}