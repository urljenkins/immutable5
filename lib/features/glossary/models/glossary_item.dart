class GlossaryItem {
  final String term;
  final String? arabic;
  final String definition;
  final String category;

  GlossaryItem({
    required this.term,
    this.arabic,
    required this.definition,
    required this.category,
  });

  factory GlossaryItem.fromJson(Map<String, dynamic> json) {
    return GlossaryItem(
      term: json['term'] as String,
      arabic: json['arabic'] as String?,
      definition: json['definition'] as String,
      category: json['category'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'term': term,
      'arabic': arabic,
      'definition': definition,
      'category': category,
    };
  }
}
