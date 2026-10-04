class Institute {
  final String id;
  final String name;
  final String type;
  final String city;
  final String address;
  final String description;
  final List<String> programs;
  final String contact;
  const Institute({required this.id, required this.name, required this.type, required this.city, this.address = '', this.description = '', this.programs = const [], this.contact = ''});
}
