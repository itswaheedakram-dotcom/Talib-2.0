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
  final bool isRomanUrdu;
  String get summary {
    final parts = <String>[];
    if (category != GlobalSearchCategory.all) parts.add(isRomanUrdu ? _romanCategory(category) : _englishCategory(category));
    if (instituteName != null) parts.add(isRomanUrdu ? '${instituteName} institute' : instituteName!);
    if (program != null) parts.add(isRomanUrdu ? '$program program' : '$program program');
    if (location != null) parts.add(isRomanUrdu ? '$location mein' : 'in $location');
    if (area != null) parts.add(isRomanUrdu ? '$area mein' : 'in $area');
    if (gender != null) parts.add(isRomanUrdu ? '${gender == 'Female' ? 'girls' : 'boys'} hostel' : '${gender == 'Female' ? 'girls’' : 'boys’'} hostels');
    if (maxBudget != null) parts.add(isRomanUrdu ? '${maxBudget} rupay tak budget' : 'budget up to PKR $maxBudget');
    if (wantsOpenAdmissions) parts.add(isRomanUrdu ? 'open admissions' : 'currently open admissions');
    if (wantsBestRated) parts.add(isRomanUrdu ? 'achay / highly rated options' : 'highly rated options');
    if (parts.isEmpty) return isRomanUrdu ? 'Aap ke sawal ke mutabiq tamam available listings mein relevant results dhoond raha hoon.' : 'I’m looking across available Talib-2.0 listings for results relevant to your query.';
    return isRomanUrdu ? 'Aap ${parts.join(', ')} ke mutabiq relevant results dhoond rahe hain.' : 'I understood that you’re looking for ${parts.join(', ')}.';
  }
  static String _romanCategory(GlobalSearchCategory c) => switch (c) {
    GlobalSearchCategory.institutes => 'institute', GlobalSearchCategory.admissions => 'admission information',
    GlobalSearchCategory.hostels => 'hostels', GlobalSearchCategory.scholarships => 'scholarships',
    GlobalSearchCategory.resources => 'study resources', GlobalSearchCategory.community => 'community posts',
    GlobalSearchCategory.people => 'profiles', GlobalSearchCategory.all => 'all listings',
  };
  static String _englishCategory(GlobalSearchCategory c) => switch (c) {
    GlobalSearchCategory.institutes => 'institutes', GlobalSearchCategory.admissions => 'admission information',
    GlobalSearchCategory.hostels => 'hostels', GlobalSearchCategory.scholarships => 'scholarships',
    GlobalSearchCategory.resources => 'study resources', GlobalSearchCategory.community => 'community posts',
    GlobalSearchCategory.people => 'profiles', GlobalSearchCategory.all => 'all listings',
  };
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
    this.isRomanUrdu = false,
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
      'where are': 'where', 'kahan': 'where', 'kaha': 'where', 'kahan par': 'where', 'kidhar': 'where', 'kis jagah': 'where',
      'mein': 'in', 'main': 'in', 'me': 'in', 'ke andar': 'in', 'ke qareeb': 'near', 'qareeb': 'near', 'nearby': 'near',
      'achy': 'good', 'acha': 'good', 'achi': 'good', 'ache': 'good', 'behtareen': 'best', 'sab se acha': 'best', 'top rated': 'best rated', 'highly rated': 'best rated',
      'girls': 'female', 'girl': 'female', 'ladies': 'female', 'women': 'female', 'larkiyon': 'female', 'larkio': 'female', 'larki': 'female', 'boys': 'male', 'boy': 'male', 'men': 'male', 'larkon': 'male', 'larko': 'male', 'larka': 'male',
      'admissions': 'admission', 'dakhla': 'admission', 'dakhle': 'admission', 'scholarships': 'scholarship', 'wazifa': 'scholarship', 'wazaif': 'scholarship', 'financial support': 'financial aid',
      'universities': 'university', 'colleges': 'college', 'schools': 'school', 'idaray': 'institute', 'institute': 'institute', 'madaris': 'school',
      'last date': 'deadline', 'akhri tareekh': 'deadline', 'aakhri tareekh': 'deadline', 'kab tak': 'deadline', 'closing date': 'deadline',
      'open hain': 'open', 'open hai': 'open', 'khulay': 'open', 'khula hai': 'open', 'apply ho raha': 'open', 'apply ho rahi': 'open', 'applications open': 'open',
      'under': 'under', 'below': 'under', 'less than': 'under', 'kam': 'under', 'se kam': 'under', 'tak': 'under', 'maximum': 'max', 'max budget': 'budget',
      'fees': 'fee', 'fee': 'fee', 'kiraya': 'rent', 'rent': 'rent', 'mahina': 'monthly', 'monthly': 'monthly', 'rupay': 'rs', 'rupees': 'rs', 'pkr': 'rs', 'lakh': '100000', 'hazaar': '000',
      'mess wala': 'mess', 'khana': 'meals', 'wifi': 'wi fi', 'internet': 'wi fi', 'air conditioning': 'ac', 'air conditioned': 'ac', 'kamra': 'room', 'kamray': 'room', 'rooms': 'room',
      'bachelors': 'bs', 'bachelor': 'bs', 'undergraduate': 'bs', 'masters': 'ms', 'master': 'ms', 'computer science': 'computer science', 'software eng': 'software engineering', 'cs degree': 'computer science', 'notes': 'notes', 'past papers': 'past paper', 'study material': 'study material',
      'hn': 'hain', 'han': 'hain', 'hain na': 'hain', 'he': 'hai', 'hai na': 'hai', 'btao': 'show', 'batao': 'show', 'bata dein': 'show', 'dikhao': 'show', 'dhoondo': 'find', 'talash': 'find', 'chahiye': 'need', 'chaheye': 'need', 'mujhe': 'me', 'mujhy': 'me', 'mere liye': 'for me', 'koi achi': 'good', 'koi acha': 'good', 'available hain': 'available', 'mil sakti': 'available', 'mil sakta': 'available',
    };
    replacements.forEach((from, to) => value = value.replaceAll(RegExp(r'\b' + RegExp.escape(from) + r'\b'), to));
    value = value.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static ParsedGlobalQuery parse(String input) {
    final isRomanUrdu = RegExp(r'\b(mein|main|me|kahan|kaha|kidhar|achy|acha|achi|ache|larkiyon|larkon|dakhla|wazifa|wazaif|kiraya|rupay|batao|btao|dikhao|dhoondo|mujhy|mujhe|chahiye|hai|hain|hn|he)\b', caseSensitive: false).hasMatch(input);
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
        if (entry.key == 'Johar Town' || entry.key == 'Gulberg' || entry.key == 'Bosan Road' || entry.key == 'New Campus' || entry.key == 'Baghdad-ul-Jadeed') {
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
      'in','near','where','good','best','top','find','show','need','me','the','a','an','for','of','is','are','open','currently','admission','hostel','scholarship','institute','school','college','university','people','profile','resources','community','deadline','last','date','under','below','less','than','maximum','max','budget','rs','pkr','female','male','girls','boys','students','student','kaha','kahan','hai','hain','mein','main','dakhla','wazifa','wazaif','rupay','kiraya','monthly','available','wi','fi','room','larki','larko','larkon','larkio','larkiyon','batao','btao','dikhao','dhoondo','mujhy','mujhe','chahiye','he','hn','acha','achi','achy','ache','behtareen','tak','kam','khulay','khula','tareekh','akhri','aakhri','lakh','hazaar','idaray','bata','dein'
    };
    final terms = normalized.split(' ').where((t) => t.length > 1 && !stopWords.contains(t) && !RegExp(r'^\d+$').hasMatch(t)).toSet().toList();
    if (understood.isEmpty) understood.add('Searching across available Talib-2.0 listings');
    return ParsedGlobalQuery(
      original: input, normalized: normalized, category: category,
      location: location, area: area, program: program, instituteName: instituteName,
      gender: gender, maxBudget: budget, wantsOpenAdmissions: openAdmissions,
      wantsBestRated: bestRated, terms: terms, understood: understood, isRomanUrdu: isRomanUrdu,
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
