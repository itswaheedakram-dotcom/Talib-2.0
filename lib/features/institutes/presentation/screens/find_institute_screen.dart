import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/institute_repository.dart';
import '../../../models/institute.dart';

class FindInstituteScreen extends StatefulWidget {
  const FindInstituteScreen({super.key});
  @override
  State<FindInstituteScreen> createState() => _FindInstituteScreenState();
}

class _FindInstituteScreenState extends State<FindInstituteScreen> {
  final _searchController = TextEditingController();
  final _scoreController = TextEditingController();

  String _education = 'All';
  String _province = 'All provinces';
  String _city = 'All cities';
  String _sector = 'All sectors';
  String _program = 'All programs';
  String _submissionMode = 'All modes';
  String _campus = 'All campuses';

  @override
  void initState() {
    super.initState();
    InstituteRepository.instance.addListener(_onChanged);
    InstituteRepository.instance.load();
  }

  void _onChanged() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    InstituteRepository.instance.removeListener(_onChanged);
    _searchController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Iterable<Institute> get _typeItems => _education == 'All'
      ? InstituteRepository.instance.items
      : InstituteRepository.instance.items.where((i) => _label(i.type) == _education);

  Iterable<Institute> get _provinceItems => _province == 'All provinces'
      ? _typeItems
      : _typeItems.where((i) => i.province == _province);

  Iterable<Institute> get _cityItems => _city == 'All cities'
      ? _provinceItems
      : _provinceItems.where((i) => i.city == _city);

  Iterable<Institute> get _sectorItems => _sector == 'All sectors'
      ? _cityItems
      : _cityItems.where((i) => i.sector == _sector);

  List<String> _values(Iterable<Institute> source, String Function(Institute) pick, String all) {
    final values = source.map((i) => pick(i).trim()).where((v) => v.isNotEmpty).toSet().toList()..sort();
    return [all, ...values];
  }

  static const List<String> _punjabCities = [
    'Attock', 'Bahawalnagar', 'Bahawalpur', 'Bhakkar', 'Chakwal',
    'Chiniot', 'Dera Ghazi Khan', 'Faisalabad', 'Gujranwala', 'Gujrat',
    'Hafizabad', 'Jhang', 'Jhelum', 'Kasur', 'Khanewal', 'Khushab',
    'Lahore', 'Layyah', 'Lodhran', 'Mandi Bahauddin', 'Mianwali',
    'Multan', 'Muzaffargarh', 'Nankana Sahib', 'Narowal', 'Okara',
    'Pakpattan', 'Rahim Yar Khan', 'Rajanpur', 'Rawalpindi', 'Sahiwal',
    'Sargodha', 'Sheikhupura', 'Sialkot', 'Toba Tek Singh', 'Vehari',
    'Ahmedpur East', 'Alipur', 'Arifwala', 'Bhalwal', 'Burewala',
    'Chishtian', 'Daska', 'Depalpur', 'Dera Din Panah', 'Dunyapur',
    'Gojra', 'Gujar Khan', 'Hasilpur', 'Haroonabad', 'Jalalpur Jattan',
    'Jaranwala', 'Jatoi', 'Kamalia', 'Kamoke', 'Kahror Pacca',
    'Kharian', 'Kot Addu', 'Kot Momin', 'Liaquatpur', 'Mailsi',
    'Malakwal', 'Muridke', 'Narowal', 'Pattoki', 'Pindi Bhattian',
    'Pindi Gheb', 'Rajanpur', 'Sadiqabad', 'Sambrial', 'Sammundri',
    'Shakargarh', 'Shorkot', 'Shujaabad', 'Taxila', 'Wazirabad',
    'Yazman', 'Zafarwal',
  ];

  List<String> get _provinces => _values(_typeItems, (i) => i.province, 'All provinces');
  List<String> get _cities {
    final dataCities = _values(_provinceItems, (i) => i.city, 'All cities');
    if (_province == 'Punjab') {
      final merged = <String>{...dataCities.skip(1), ..._punjabCities};
      final sorted = merged.toList()..sort();
      return ['All cities', ...sorted];
    }
    return dataCities;
  }
  List<String> get _campuses => _values(_cityItems, (i) => i.campus, 'All campuses');

  List<String> get _programs {
    final values = <String>{};
    for (final i in _sectorItems) {
      values.addAll(i.programs.map((p) => p.trim()).where((p) => p.isNotEmpty));
      if (i.nextProgram.trim().isNotEmpty) values.add(i.nextProgram.trim());
    }
    final result = values.toList()..sort();
    return ['All programs', ...result];
  }

  List<Institute> get _results {
    final q = _searchController.text.trim().toLowerCase();
    final score = double.tryParse(_scoreController.text.trim());

    return InstituteRepository.instance.items.where((i) {
      final searchable =
          '${i.name} ${i.city} ${i.province} ${i.campus} ${i.address} '
          '${i.description} ${i.programs.join(' ')} ${i.nextProgram}'.toLowerCase();
      final programMatch = _program == 'All programs' ||
          i.nextProgram.toLowerCase() == _program.toLowerCase() ||
          i.programs.any((p) => p.toLowerCase() == _program.toLowerCase());

      return (q.isEmpty || searchable.contains(q)) &&
          (_education == 'All' || _label(i.type) == _education) &&
          (_province == 'All provinces' || i.province == _province) &&
          (_city == 'All cities' || i.city == _city) &&
          (_sector == 'All sectors' || i.sector == _sector) &&
          programMatch &&
          (_submissionMode == 'All modes' || i.submissionMode == _submissionMode) &&
          (_campus == 'All campuses' || i.campus == _campus) &&
          (score == null || score >= i.minScore);
    }).toList();
  }

  String _label(String type) => switch (type) {
    'schools' => 'School',
    'colleges' => 'College',
    'universities' => 'University',
    _ => type,
  };

  List<String> get _activeFilters => [
    if (_education != 'All') _education,
    if (_province != 'All provinces') _province,
    if (_city != 'All cities') _city,
    if (_sector != 'All sectors') _sector,
    if (_program != 'All programs') _program,
    if (_submissionMode != 'All modes') _submissionMode,
    if (_campus != 'All campuses') _campus,
    if (_scoreController.text.trim().isNotEmpty) 'Score ≥ ${_scoreController.text.trim()}',
  ];

  void _reset() {
    setState(() {
      _education = 'All';
      _province = 'All provinces';
      _city = 'All cities';
      _sector = 'All sectors';
      _program = 'All programs';
      _submissionMode = 'All modes';
      _campus = 'All campuses';
      _scoreController.clear();
    });
  }

  void _showFilters() {
    var education = _education;
    var province = _province;
    var city = _city;
    var sector = _sector;
    var program = _program;
    var mode = _submissionMode;
    var campus = _campus;
    var score = _scoreController.text;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, sheetSet) {
          Iterable<Institute> typeItems() => education == 'All'
              ? InstituteRepository.instance.items
              : InstituteRepository.instance.items.where((i) => _label(i.type) == education);
          Iterable<Institute> provinceItems() => province == 'All provinces'
              ? typeItems()
              : typeItems().where((i) => i.province == province);
          Iterable<Institute> cityItems() => city == 'All cities'
              ? provinceItems()
              : provinceItems().where((i) => i.city == city);
          Iterable<Institute> sectorItems() => sector == 'All sectors'
              ? cityItems()
              : cityItems().where((i) => i.sector == sector);

          final provinces = _values(typeItems(), (i) => i.province, 'All provinces');
          final cities = _values(provinceItems(), (i) => i.city, 'All cities');
          final sectors = _values(cityItems(), (i) => i.sector, 'All sectors');
          final campuses = _values(sectorItems(), (i) => i.campus, 'All campuses');
          final programSet = <String>{};
          for (final i in sectorItems()) {
            programSet.addAll(i.programs.map((p) => p.trim()).where((p) => p.isNotEmpty));
            if (i.nextProgram.trim().isNotEmpty) programSet.add(i.nextProgram.trim());
          }
          final programOptions = ['All programs', ...programSet.toList()..sort()];

          return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Expanded(child: Text('Find Institute', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                  TextButton(onPressed: () {
                    education = 'All'; province = 'All provinces'; city = 'All cities';
                    sector = 'All sectors'; program = 'All programs';
                    mode = 'All modes'; campus = 'All campuses'; score = '';
                    _scoreController.clear(); sheetSet(() {});
                  }, child: const Text('Clear all')),
                ]),
                const SizedBox(height: 8),
                _Group('Institute Type', const ['All','School','College','University'], education, (v) => sheetSet(() {
                  education = v; province = 'All provinces'; city = 'All cities';
                  sector = 'All sectors'; program = 'All programs'; campus = 'All campuses';
                })),
                _Group('Province', provinces, province, (v) => sheetSet(() {
                  province = v; city = 'All cities'; sector = 'All sectors';
                  program = 'All programs'; campus = 'All campuses';
                })),
                _Group('City', cities, city, (v) => sheetSet(() {
                  city = v; sector = 'All sectors'; program = 'All programs';
                  campus = 'All campuses';
                })),
                _Group('Sector', sectors, sector, (v) => sheetSet(() {
                  sector = v; program = 'All programs'; campus = 'All campuses';
                })),
                _Group('Program / Degree', programOptions, program, (v) => sheetSet(() => program = v)),
                _Group('Application / Submission', const ['All modes','Online','Offline'], mode, (v) => sheetSet(() => mode = v)),
                _Group('Campus', campuses, campus, (v) => sheetSet(() => campus = v)),
                const Text('Your Percentage / CGPA', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                TextField(
                  controller: _scoreController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 72 or 3.2',
                    labelText: 'Minimum score you have',
                    prefixIcon: Icon(Icons.percent),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => sheetSet(() => score = v),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () { _reset(); Navigator.pop(sheetContext); }, child: const Text('Clear all'))),
                  const SizedBox(width: 12),
                  Expanded(child: FilledButton(onPressed: () {
                    setState(() {
                      _education = education; _province = province; _city = city;
                      _sector = sector; _program = program; _submissionMode = mode;
                      _campus = campus; _scoreController.text = score;
                    });
                    Navigator.pop(sheetContext);
                  }, child: const Text('Apply filters'))),
                ]),
              ],
            ),
          );
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final repo = InstituteRepository.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Institute'),
        actions: [IconButton(onPressed: _showFilters, icon: const Icon(Icons.tune))],
      ),
      body: RefreshIndicator(
        onRefresh: repo.load,
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            sliver: SliverList(delegate: SliverChildListDelegate([
              const Text('Find the right institute', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Search by institute, location, program and apply detailed filters to find a suitable match.'),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search institute, city or program',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty ? null : IconButton(
                    onPressed: () { _searchController.clear(); setState(() {}); },
                    icon: const Icon(Icons.clear),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_activeFilters.isNotEmpty)
                Wrap(
                  spacing: 7, runSpacing: 7,
                  children: _activeFilters.map((f) => Chip(label: Text(f))).toList(),
                )
              else
                const Text('No filters applied', style: TextStyle(color: Colors.black54, fontSize: 13)),
              Row(children: [
                Text('${results.length} institutes found', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const Spacer(),
                TextButton.icon(onPressed: _showFilters, icon: const Icon(Icons.tune, size: 18), label: const Text('Filters')),
              ]),
            ])),
          ),
          if (repo.loading) const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
          if (results.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Padding(
                padding: EdgeInsets.all(30),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.search_off_rounded, size: 54),
                  SizedBox(height: 12),
                  Text('No matching institutes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Change your filters or search term and try again.', textAlign: TextAlign.center),
                ]),
              )),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final i = results[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(child: Icon(_icon(i.type))),
                      title: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${_label(i.type)} • ${i.city}${i.sector.isEmpty ? '' : ' • ${i.sector}'}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/institute/${i.id}'),
                    )),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }

  IconData _icon(String type) => switch (type) {
    'schools' => Icons.school_outlined,
    'colleges' => Icons.account_balance_outlined,
    _ => Icons.account_balance,
  };
}

class _Group extends StatelessWidget {
  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  const _Group(this.title, this.values, this.selected, this.onChanged);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      Wrap(
        spacing: 7, runSpacing: 7,
        children: values.map((v) => ChoiceChip(
          label: Text(v),
          selected: selected == v,
          onSelected: (_) => onChanged(v),
        )).toList(),
      ),
    ]),
  );
}
