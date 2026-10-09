/// Deterministic, offline natural-language query parser for Smart Global Search.
/// No network AI or paid inference service is used.
enum GlobalSearchCategory { institutes, admissions, hostels, scholarships, resources, community, people, all }

class ParsedGlobalQuery {
  final String original;
  final String normalized;
  final GlobalSearchCategory category;
  final String? location;
  final String? area;
  final String? program;
  final String? instituteName;
  final String? gender;
  final int? maxBudget;
  final bool wantsOpenAdmissions;
  final bool wantsBestRated;
  final List<String> terms;
  final List<String> understood;
  const ParsedGlobalQuery({
    required this.original,
    required this.normalized,
    required this.category,
    this.location,
    this.area,
    this.program,
    this.instituteName,
    this.gender,
    this.maxBudget,
    this.wantsOpenAdmissions = false,
    this.wantsBestRated = false,
    required this.terms,
    required this.understood,
  });
}

abstract final class SmartSearchParser {
  static const _locations = <String, List<String>>{
    'Lahore': ['lahore', 'lahor'],
    'Islamabad': ['islamabad', 'islambad', 'islam abad'],
    'Rawalpindi': ['rawalpindi', 'pindi'],
    'Multan': ['multan'],
    'Bahawalpur': ['bahawalpur', 'bahawal poor'],
    'Faisalabad': ['faisalabad', 'faisal abad'],
    'Karachi': ['karachi', 'krachi'],
    'Peshawar': ['peshawar', 'peshawer'],
    'Quetta': ['quetta'],
    'Gujranwala': ['gujranwala'],
    'Sialkot': ['sialkot'],
    'Sargodha': ['sargodha'],
    'Johar Town': ['johar town', 'johar town lahore'],
    'Gulberg': ['gulberg'],
    'Bosan Road': ['bosan road', 'bosan'],
    'New Campus': ['new campus'],
    'Baghdad-ul-Jadeed': ['baghdad-ul-jadeed', 'baghdad ul jadeed'],
  };

  static String normalize(String input) {
    var value = input.toLowerCase().trim();
    const replacements = {
      'where are': 'where', 'kahan': 'where', 'kaha': 'where',
      'kidhar': 'where', 'me': 'in', 'mein': 'in', 'main': 'in',
      'achy': 'good', 'acha': 'good', 'achi': 'good',
      'hostel': 'hostel', 'hostels': 'hostel', 'girls': 'female',
      'girl': 'female', 'ladies': 'female', 'boys': 'male',
      'admissions': 'admission', 'scholarships': 'scholarship',
      'universities': 'university', 'colleges': 'college',
      'schools': 'school', 'last date': 'deadline',
      'open hain': 'open', 'open hai': 'open', 'khulay': 'open',
      'under': 'under', 'less than': 'under', 'kam': 'under',
      'fees': 'fee', 'rupees': 'rs', 'pkr': 'rs',
    };
    replacements.forEach((from, to) => value = value.replaceAll(RegExp(r'\b' + RegExp.escape(from) + r'\b'), to));
    value = value.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static ParsedGlobalQuery parse(String input) {
    final normalized = normalize(input);
    final understood = <String>[];
    var category = GlobalSearchCategory.all;
    if (RegExp(r'\b(hostel|accommodation|residence|room|mess)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.hostels;
    } else if (RegExp(r'\b(admission|admit|deadline|last date|entry test)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.admissions;
    } else if (RegExp(r'\b(scholarship|financial aid|stipend|funding)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.scholarships;
    } else if (RegExp(r'\b(resource|notes|past paper|book|study material)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.resources;
    } else if (RegExp(r'\b(community|post|discussion|question)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.community;
    } else if (RegExp(r'\b(people|person|profile|student|user)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.people;
    } else if (RegExp(r'\b(institute|school|college|university|educators|campus)\b').hasMatch(normalized)) {
      category = GlobalSearchCategory.institutes;
    }
    if (category != GlobalSearchCategory.all) understood.add('Category: ${_categoryLabel(category)}');

    String? location;
    String? area;
    for (final entry in _locations.entries) {
      if (entry.value.any((alias) => normalized.contains(alias))) {
        if (entry.key == 'Johar Town' || entry.key == 'Gulberg' || entry.key == 'Bosan Road' || entry.key == 'New Campus' || entry.key == 'Bahhdad-ul-Jadeed') {
          area = entry.key;
        } else {
          location = entry.key;
        }
      }
    }
    if (location != null) understood.add('Location: $location');
    if (area != null) understood.add('Area: $area');

    final budgetMatch = RegExp(r'\b(?:under|below|less than|max|maximum|budget|rs)?\s*(\d{1,3}(?:,\d{3})+|\d{4,6})\b').firstMatch(normalized);
    final budget = budgetMatch == null ? null : int.tryParse(budgetMatch.group(1)!.replaceAll(',', ''));
    if (budget != null) understood.add('Budget: up to PKR ${budget.toString()}');

    String? gender;
    if (RegExp(r'\b(female|girls|women|ladies)\b').hasMatch(normalized)) {
      gender = 'Female'; understood.add('Hostel type: Girls/Female');
    } else if (RegExp(r'\b(male|boys|men)\b').hasMatch(normalized)) {
      gender = 'Male'; understood.add('Hostel type: Boys/Male');
    }
    final openAdmissions = RegExp(r'\b(open|currently open|accepting applications)\b').hasMatch(normalized);
    if (openAdmissions) understood.add('Status: Open');
    final bestRated = RegExp(r'\b(best|good|top|best rated|highly rated)\b').hasMatch(normalized);
    if (bestRated) understood.add('Preference: Best rated / recommended');

    String? program;
    for (final p in ['computer science', 'cs', 'software engineering', 'engineering', 'business administration', 'fsc', 'ics', 'bs', 'undergraduate', 'ms', 'phd']) {
      if (RegExp('\b${RegExp.escape(p)}\b').hasMatch(normalized)) {
        program = p == 'cs' ? 'Computer Science' : p.toUpperCase() == 'BS' ? 'BS' : _titleCase(p);
        understood.add('Program/level: $program');
        break;
      }
    }

    String? instituteName;
    for (final name in ['the educators', 'arid', 'university of the punjab', 'punjab university', 'bzu', 'islamia university bahawalpur', 'uet', 'nust']) {
      if (normalized.contains(name)) {
        instituteName = name;
        understood.add('Institute: ${_titleCase(name)}');
        break;
      }
    }

    final stopWords = <String>{
      'in','where','good','best','top','find','show','me','the','a','an','for','of','is','are','open','currently','admission','hostel','scholarship','institute','school','college','university','people','profile','resources','community','deadline','last','date','under','below','less','than','maximum','max','budget','rs','pkr','female','male','girls','boys','students','student','kaha','kahan','hai','hain','mein','main'
    };
    final terms = normalized.split(' ').where((t) => t.length > 1 && !stopWords.contains(t) && !RegExp(r'^\d+$').hasMatch(t)).toSet().toList();
    if (understood.isEmpty) understood.add('Searching across available Talib-2.0 listings');
    return ParsedGlobalQuery(
      original: input, normalized: normalized, category: category,
      location: location, area: area, program: program, instituteName: instituteName,
      gender: gender, maxBudget: budget, wantsOpenAdmissions: openAdmissions,
      wantsBestRated: bestRated, terms: terms, understood: understood,
    );
  }

  static String _categoryLabel(GlobalSearchCategory c) => switch (c) {
    GlobalSearchCategory.institutes => 'Institutes',
    GlobalSearchCategory.admissions => 'Admissions',
    GlobalSearchCategory.hostels => 'Hostels',
    GlobalSearchCategory.scholarships => 'Scholarships',
    GlobalSearchCategory.resources => 'Resources',
    GlobalSearchCategory.community => 'Community',
    GlobalSearchCategory.people => 'People',
    GlobalSearchCategory.all => 'All categories',
  };
  static String _titleCase(String value) => value.split(' ').map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
}
