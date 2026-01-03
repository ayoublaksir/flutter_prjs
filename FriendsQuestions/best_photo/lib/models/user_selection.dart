class UserSelection {
  final List<String> imagePaths;
  final String purpose;
  final String additionalNotes;

  UserSelection({
    required this.imagePaths,
    required this.purpose,
    this.additionalNotes = '',
  });
}