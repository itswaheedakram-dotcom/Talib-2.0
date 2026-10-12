import 'smart_search_parser.dart';

class SearchFacet {
  final String key,label,type;
  const SearchFacet(this.key,this.label,{this.type='choice'});
  factory SearchFacet.fromMap(Map<String,dynamic> map)=>SearchFacet((map['key']??'').toString(),(map['label']??'').toString(),type:(map['type']??'choice').toString());
  bool get valid=>RegExp(r'^[a-zA-Z][a-zA-Z0-9_.]{0,49}$').hasMatch(key)&&label.isNotEmpty&&const ['choice','number','toggle'].contains(type);
  Map<String,dynamic> toMap()=>{'key':key,'label':label,'type':type};
}
class SearchCatalog {
  final String id,label,icon;
  final List<String> aliases;
  final List<SearchFacet> facets;
  const SearchCatalog({required this.id,required this.label,this.icon='category',this.aliases=const [],this.facets=const []});
  factory SearchCatalog.fromMap(String id,Map<String,dynamic> data)=>SearchCatalog(id:id,label:(data['label']??'').toString(),icon:(data['icon']??'category').toString(),aliases:(data['aliases'] is List?(data['aliases'] as List).map((v)=>v.toString()).toList():const []),facets:(data['facets'] is List?(data['facets'] as List).whereType<Map>().map((v)=>SearchFacet.fromMap(Map<String,dynamic>.from(v))).where((v)=>v.valid).toList():const []));
  bool get valid=>RegExp(r'^[a-z][a-z0-9_-]{1,39}$').hasMatch(id)&&label.trim().isNotEmpty&&label.length<=80&&facets.length<=12;
  Map<String,dynamic> toMap()=>{'label':label,'icon':icon,'aliases':aliases,'facets':facets.map((f)=>f.toMap()).toList(),'enabled':true};
}
class SearchRecord {
  final String id,catalogId,title,description,city,area,route;
  final Map<String,dynamic> attributes;
  final List<String> tags;
  final Object? extra;
  final DateTime? updatedAt;
  final bool published,isDemo;
  const SearchRecord({required this.id,required this.catalogId,required this.title,this.description='',this.city='',this.area='',this.route='',this.attributes=const {},this.tags=const [],this.extra,this.updatedAt,this.published=true,this.isDemo=false});
  Object? field(String key){if(key=='city')return city;if(key=='area')return area;Object? value=attributes;for(final part in key.split('.')){if(value is! Map)return null;value=value[part];}return value;}
  static String flatten(Object? value,{int depth=0}){if(value==null||depth>5)return '';if(value is Map)return value.values.map((v)=>flatten(v,depth:depth+1)).join(' ');if(value is Iterable)return value.map((v)=>flatten(v,depth:depth+1)).join(' ');return value.toString();}
  String get searchable=>'$title $description $city $area ${tags.join(' ')} ${flatten(attributes)}';
}
class SearchPage {
  final List<SearchRecord> records;
  final bool hasMore;
  final Object? cursor;
  const SearchPage(this.records,{this.hasMore=false,this.cursor});
}
abstract class SearchAdapter {
  SearchCatalog get catalog;
  Future<SearchPage> load({Object? cursor});
}
class SearchMatch {
  final SearchRecord record;
  final double score;
  const SearchMatch(this.record,this.score);
}
class SearchResponse {
  final List<SearchMatch> matches;
  final List<String> warnings;
  final bool hasMore;
  final String category;
  final Map<String,String> filters;
  const SearchResponse(this.matches,{this.warnings=const [],this.hasMore=false,this.category='all',this.filters=const {}});
}
class SearchEngine {
  final Map<String,SearchAdapter> _adapters={};
  final Map<String,List<SearchRecord>> _cache={};
  final Map<String,Object?> _cursors={};
  final Set<String> _more={};
  final Map<String,DateTime> _loaded={};
  String _scope='';
  void register(SearchAdapter adapter){if(!adapter.catalog.valid)throw ArgumentError('Invalid search catalogue.');_adapters[adapter.catalog.id]=adapter;}
  void unregister(String id){_adapters.remove(id);_cache.remove(id);_loaded.remove(id);_more.remove(id);_cursors.remove(id);}
  List<SearchCatalog> get catalogs=>_adapters.values.map((s)=>s.catalog).toList();
  List<SearchRecord> get cachedRecords=>_cache.values.expand((v)=>v).where((r)=>r.published).toList();
  void resetScope(String scope){if(scope==_scope)return;_scope=scope;clearCache();}
  void clearCache(){_cache.clear();_cursors.clear();_loaded.clear();_more.clear();}
  static String normalize(String value){final parsed=SmartSearchParser.normalize(value);return parsed.isEmpty?value.toLowerCase().trim():parsed;}
  String inferCategory(String query){
    final parsed=SmartSearchParser.parse(query);final known=switch(parsed.category){GlobalSearchCategory.institutes=>'institutes',GlobalSearchCategory.admissions=>'admissions',GlobalSearchCategory.hostels=>'hostels',GlobalSearchCategory.scholarships=>'scholarships',GlobalSearchCategory.resources=>'resources',GlobalSearchCategory.community=>'posts',GlobalSearchCategory.people=>'people',_=>'all'};
    if(known!='all'&&_adapters.containsKey(known))return known;
    final text=normalize(query);final candidates=<({String id,int length})>[];
    for(final cat in catalogs){for(final alias in [cat.label,...cat.aliases]){final n=normalize(alias);if(n.isNotEmpty&&RegExp(r'\b'+RegExp.escape(n)+r'\b').hasMatch(text))candidates.add((id:cat.id,length:n.length));}}
    candidates.sort((a,b)=>b.length.compareTo(a.length));return candidates.isEmpty?'all':candidates.first.id;
  }
  Future<SearchResponse> search(String query,{String? category,Map<String,String> filters=const {},String sort='Relevance',bool refresh=false,bool more=false})async{
    final scope=_scope;final effective=category??inferCategory(query);final warnings=<String>[];
    final selected=effective=='all'?_adapters.values.toList():[_adapters[effective]].whereType<SearchAdapter>().toList();
    final now=DateTime.now();
    await Future.wait(selected.map((source)async{
      final id=source.catalog.id;
      final fresh=_loaded[id]!=null&&now.difference(_loaded[id]!)<const Duration(minutes:1);
      if(!refresh&&!more&&fresh&&id!='people')return;
      if(more&&!_more.contains(id))return;
      try{
        final page=await source.load(cursor:more?_cursors[id]:null);if(scope!=_scope)return;
        final map=<String,SearchRecord>{if(more)for(final r in _cache[id]??<SearchRecord>[])r.id:r,for(final r in page.records.where((r)=>r.published&&r.catalogId==id))r.id:r};
        _cache[id]=map.values.toList();_loaded[id]=now;_cursors[id]=page.cursor;if(page.hasMore){_more.add(id);}else{_more.remove(id);}
      }catch(_){if(scope==_scope){_cache.remove(id);_loaded.remove(id);warnings.add('${source.catalog.label} could not be loaded. Retry to try this source again.');}}
    }));
    if(scope!=_scope)return const SearchResponse([]);
    final parsed=SmartSearchParser.parse(query);
    final applied=Map<String,String>.from(filters);
    void infer(String key,String? value){if(value!=null&&!applied.containsKey(key))applied[key]=value;}
    infer('city',parsed.location);infer('area',parsed.area);
    if(effective=='institutes'&&parsed.instituteName==null){if(RegExp(r'\bschool\b').hasMatch(parsed.normalized))infer('type','schools');if(RegExp(r'\bcollege\b').hasMatch(parsed.normalized))infer('type','colleges');if(RegExp(r'\buniversity\b').hasMatch(parsed.normalized))infer('type','universities');}
    if(effective=='hostels'){if(RegExp(r'\bac\b').hasMatch(parsed.normalized))infer('ac','true');if(RegExp(r'\bavailable\b').hasMatch(parsed.normalized))infer('availableOnly','true');infer('gender',parsed.gender);if(parsed.maxBudget!=null)infer('budget',parsed.maxBudget.toString());}
    if(parsed.program!=null&&const ['institutes','courses','admissions','scholarships'].contains(effective))infer('program',parsed.program);
    if(parsed.wantsOpenAdmissions)infer('status','Open');
    if(parsed.wantsBestRated&&sort=='Relevance')sort='Top rated';
    final terms=List<String>.from(parsed.terms);
    if(parsed.instituteName!=null)terms.addAll(normalize(parsed.instituteName!).split(' ').where((v)=>v!='the'));
    final ignore={'the','of','in','for',if(effective=='hostels'&&applied.containsKey('ac'))'ac'};terms.removeWhere(ignore.contains);
    if(parsed.terms.isEmpty&&parsed.understood.length==1&&parsed.understood.first.startsWith('Searching')&&query.trim().isNotEmpty)terms.addAll(normalize(query).split(' '));
    if(parsed.normalized.isEmpty&&query.trim().isNotEmpty)terms.addAll(query.trim().split(RegExp(r'\s+')));
    final activeCatalog=_adapters[effective]?.catalog;
    if(activeCatalog!=null){final aliases=[activeCatalog.label,...activeCatalog.aliases].expand((a)=>normalize(a).split(' ')).toSet();terms.removeWhere(aliases.contains);}
    if(parsed.category!=GlobalSearchCategory.all&&effective!=inferCategory(query)){final inferred=_adapters[inferCategory(query)]?.catalog;if(inferred!=null)terms.add(normalize(inferred.aliases.isNotEmpty?inferred.aliases.first:inferred.label));}
    final matches=<SearchMatch>[];
    for(final source in selected){for(final record in _cache[source.catalog.id]??<SearchRecord>[]){
      if(!_passes(record,applied))continue;
      final score=_score(record,terms,query,source.catalog);
      if(score>0)matches.add(SearchMatch(record,score));
    }}
    matches.sort((a,b){
      if(sort=='Newest'){final c=(b.record.updatedAt??DateTime(1970)).compareTo(a.record.updatedAt??DateTime(1970));if(c!=0)return c;}
      if(sort=='Top rated'){final c=_number(b.record.field('rating')).compareTo(_number(a.record.field('rating')));if(c!=0)return c;}
      if(sort=='Price low'){final av=a.record.field('budget'),bv=b.record.field('budget');final c=(av==null?double.infinity:_number(av)).compareTo(bv==null?double.infinity:_number(bv));if(c!=0)return c;}
      final score=b.score.compareTo(a.score);return score!=0?score:a.record.title.compareTo(b.record.title);
    });
    return SearchResponse(matches,warnings:warnings,hasMore:selected.any((s)=>_more.contains(s.catalog.id)),category:effective,filters:applied);
  }
  bool _passes(SearchRecord record,Map<String,String> filters){
    final roomKeys={'budget','roomType','rentBasis','ac','availableOnly'};
    final offers=record.field('offers');
    if(record.catalogId=='hostels'&&offers is List&&filters.keys.any(roomKeys.contains)){
      if(!offers.whereType<Map>().any((offer)=>filters.entries.where((f)=>roomKeys.contains(f.key)).every((f)=>_fieldPass(offer[f.key],f.value,f.key))))return false;
    }
    for(final filter in filters.entries){
      if(record.catalogId=='hostels'&&offers is List&&roomKeys.contains(filter.key))continue;
      if(record.catalogId=='admissions'&&filter.key=='status'&&filter.value=='Open'&&(filters['program']??'').isNotEmpty&&record.field('programStatus') is Map){final statuses=record.field('programStatus') as Map;if(!statuses.entries.any((e)=>_fieldPass(e.key,filters['program']!,'program')&&e.value=='Open'))return false;continue;}
      if(!_fieldPass(record.field(filter.key),filter.value,filter.key))return false;
    }
    return true;
  }
  bool _fieldPass(Object? value,String wanted,String key){
    if(wanted.isEmpty)return true;
    if(key=='budget'||wanted.startsWith('<=')){final max=double.tryParse(wanted.replaceFirst('<=',''));final number=value is num?value.toDouble():SmartSearchParser.minimumPrice(value?.toString()??'')?.toDouble();return max!=null&&number!=null&&number<=max;}
    if(key=='availableOnly')return wanted!='true'||(value is num&&value>0)||value==true;
    if(wanted=='true')return value==true;
    if(value is Iterable)return value.any((v)=>_fieldPass(v,wanted,key));
    final hay=normalize(value?.toString()??''),needle=normalize(wanted);
    if(key=='city'||key=='area')return hay.contains(needle);
    if(key=='program')return RegExp(r'\b'+RegExp.escape(needle)+r'\b').hasMatch(hay);
    return hay==needle;
  }
  double _score(SearchRecord record,List<String> terms,String query,SearchCatalog cat){
    final title=normalize(record.title),username=normalize(record.field('username')?.toString()??''),raw=normalize(query.replaceFirst('@',''));
    final hay=normalize('${record.searchable} ${cat.label} ${cat.aliases.join(' ')}');
    if(raw.isNotEmpty&&username==raw)return 120;
    if(raw.isNotEmpty&&title==raw)return 110;
    var score=1.0;
    for(final term in terms){final word=normalize(term);if(word.isEmpty)continue;
      if(title.split(' ').contains(word)){score+=10;}else if(title.contains(word)){score+=6;}else if(hay.contains(word)){score+=2;}else if(word.length>=4&&hay.split(' ').any((w)=>_distance(w,word)<=1)){score+=.5;}else{return 0;}
    }
    if(raw.isNotEmpty&&title.startsWith(raw))score+=50;
    return score;
  }
  static double _number(Object? value)=>value is num?value.toDouble():double.tryParse(value?.toString()??'')??0;
  static int _distance(String a,String b){if((a.length-b.length).abs()>1)return 2;var row=List<int>.generate(b.length+1,(i)=>i);for(var i=1;i<=a.length;i++){final next=<int>[i];for(var j=1;j<=b.length;j++){final remove=row[j]+1,add=next[j-1]+1,replace=row[j-1]+(a[i-1]==b[j-1]?0:1);next.add([remove,add,replace].reduce((a,b)=>a<b?a:b));}row=next;}return row.last;}
  List<String> values(String category,String field){final records=category=='all'?cachedRecords:_cache[category]??<SearchRecord>[];final result=<String>{};for(final r in records){final value=r.field(field);if(value is Iterable){result.addAll(value.where((v)=>v is String||v is num).map((v)=>v.toString()));}else if(value is String&&value.isNotEmpty){result.add(value);} }return result.toList()..sort();}
}
