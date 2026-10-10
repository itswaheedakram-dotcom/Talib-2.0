import 'package:flutter/material.dart';

Future<String?> searchChoice(BuildContext context, String title, Map<String, String> choices) =>
  showSearch<String>(context: context, delegate: _ChoiceSearch(title, choices));

class _ChoiceSearch extends SearchDelegate<String> {
  final Map<String, String> choices;
  _ChoiceSearch(String title, this.choices) : super(searchFieldLabel: title);
  @override List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty) IconButton(tooltip: 'Clear search', onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];
  @override Widget buildLeading(BuildContext context) => IconButton(tooltip: 'Back', onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));
  Widget results(BuildContext context) {
    final filtered = choices.entries.where((e) => e.value.toLowerCase().contains(query.toLowerCase())).toList();
    if (filtered.isEmpty) return const Center(child: Text('No matches. Try another name.'));
    return ListView.builder(itemCount: filtered.length, itemBuilder: (_, i) =>
      ListTile(title: Text(filtered[i].value), onTap: () => close(context, filtered[i].key)));
  }
  @override Widget buildResults(BuildContext context) => results(context);
  @override Widget buildSuggestions(BuildContext context) => results(context);
}
