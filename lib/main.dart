import 'package:flutter/material.dart';

void main() => runApp(const KricketApp());

class K {
  static const dark = Color(0xFF00341C);
  static const green = Color(0xFF004D2C);
  static const lime = Color(0xFFC1F100);
  static const limeText = Color(0xFF506600);
  static const ink = Color(0xFF1A1C1C);
  static const body = Color(0xFF404942);
  static const bg = Color(0xFFF9F9F9);
}

class ArticleData {
  const ArticleData({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.image,
    required this.date,
    required this.readTime,
    required this.body,
    required this.source,
  });

  final String id;
  final String category;
  final String title;
  final String summary;
  final String image;
  final String date;
  final String readTime;
  final List<String> body;
  final String source;

  factory ArticleData.fromJson(Map<String, dynamic> json) => ArticleData(
        id: json['id'] as String,
        category: json['category'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String,
        image: json['image_url'] as String,
        date: json['published_at'] as String,
        readTime: json['read_time'] as String,
        body: (json['body'] as List<dynamic>).cast<String>(),
        source: json['source'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'title': title,
        'summary': summary,
        'image_url': image,
        'published_at': date,
        'read_time': readTime,
        'body': body,
        'source': source,
      };
}

const realArticles = <ArticleData>[
  ArticleData(
    id: 'pak-women-sri-lanka-2026',
    category: 'PAKISTAN WOMEN',
    title: 'Pakistan women squads announced for Sri Lanka series',
    summary: 'Pakistan named 15-player ODI and T20I squads for six white-ball matches in Hambantota.',
    image: 'assets/images/pakistan_women.png',
    date: '18 July 2026',
    readTime: '4 min read',
    source: 'Pakistan Cricket Board / ICC',
    body: [
      'Pakistan’s Women’s National Selection Committee has announced 15-member squads for the ODI and T20I series against Sri Lanka in Hambantota.',
      'The tour begins with three ODIs on 23, 25 and 28 July. Three T20Is follow on 31 July, 2 August and 4 August, with every match staged at the Mahinda Rajapaksa International Cricket Stadium.',
      'The ODI leg forms part of the ICC Women’s Championship 2025–29. Pakistan entered the tour second in the standings with eight points from six matches, making the series an important step in their qualification campaign.'
    ],
  ),
  ArticleData(
    id: 'babar-discipline-fitness-2026',
    category: 'PLAYER NEWS',
    title: 'Babar Azam returns focused on discipline, fitness and performance',
    summary: 'Pakistan’s Test captain says preparation and consistency will guide the team’s next assignments.',
    image: 'assets/images/babar_batting.png',
    date: '6 July 2026',
    readTime: '5 min read',
    source: 'Pakistan Cricket Board',
    body: [
      'Babar Azam has placed discipline, fitness and performance at the centre of his plans after taking charge of Pakistan’s Test side again.',
      'The batter said preparation for upcoming assignments must be built around clear roles and consistent standards. His return follows a productive Pakistan Super League campaign in which he led Peshawar Zalmi to the title and finished as the competition’s leading run-scorer.',
      'Pakistan will look to turn that renewed confidence into stronger results in the current World Test Championship cycle.'
    ],
  ),
  ArticleData(
    id: 'u19-sports-psychology-2026',
    category: 'U19 DEVELOPMENT',
    title: 'Sports psychology added to Pakistan U19 development camp',
    summary: 'The PCB introduced structured mental-skills work alongside technical and tactical training in Multan.',
    image: 'assets/images/u19_training.png',
    date: '17 July 2026',
    readTime: '3 min read',
    source: 'Pakistan Cricket Board',
    body: [
      'The Pakistan Cricket Board has introduced a structured sports psychology programme at its U19 Skills Development Camp in Multan.',
      'The programme complements technical coaching with work on concentration, confidence, emotional control and decision-making under pressure.',
      'Coaches are using the camp to prepare young players for the demands of high-performance cricket while building habits that can support long-term development.'
    ],
  ),
  ArticleData(
    id: 'womens-t20-world-cup-2028-host',
    category: 'GLOBAL CRICKET',
    title: 'Pakistan confirmed as host of Women’s T20 World Cup 2028',
    summary: 'The ICC approved the qualification pathway for the 12-team tournament to be hosted by the PCB.',
    image: 'assets/images/cricket_stadium.png',
    date: '1 June 2026',
    readTime: '4 min read',
    source: 'International Cricket Council',
    body: [
      'The ICC Board has endorsed the qualification pathway for the Women’s T20 World Cup 2028, which will be hosted by the Pakistan Cricket Board.',
      'The tournament will feature 12 teams. Ten places will be filled through automatic qualification, including the host nation when required, while two remaining berths will come through a 10-team Global Qualifier.',
      'India’s matches are scheduled to be played at a neutral venue. The decision forms part of a wider package designed to strengthen the global women’s cricket pathway.'
    ],
  ),
];

abstract interface class NewsApi {
  Future<List<ArticleData>> getArticles({String? category});
  Future<ArticleData> getArticle(String id);
}

class MockNewsApi implements NewsApi {
  const MockNewsApi({this.latency = const Duration(milliseconds: 450)});
  final Duration latency;

  @override
  Future<List<ArticleData>> getArticles({String? category}) async {
    await Future<void>.delayed(latency);
    final response = <String, dynamic>{
      'success': true,
      'data': [for (final article in realArticles) article.toJson()],
      'meta': {'page': 1, 'per_page': realArticles.length, 'total': realArticles.length},
    };
    final items = (response['data'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ArticleData.fromJson)
        .where((article) => category == null || article.category == category)
        .toList();
    return items;
  }

  @override
  Future<ArticleData> getArticle(String id) async {
    await Future<void>.delayed(latency);
    final match = realArticles.where((article) => article.id == id);
    if (match.isEmpty) throw const NewsApiException(404, 'Article not found');
    return ArticleData.fromJson(match.first.toJson());
  }
}

class NewsApiException implements Exception {
  const NewsApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'NewsApiException($statusCode): $message';
}

class KricketApp extends StatelessWidget {
  const KricketApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kricket.pk',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: K.bg,
          colorScheme: ColorScheme.fromSeed(seedColor: K.green),
          fontFamily: 'Inter',
        ),
        home: const AppShell(),
      );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int page = 0;
  late final Future<List<ArticleData>> articles;

  @override
  void initState() {
    super.initState();
    articles = const MockNewsApi().getArticles();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: page < 2 ? const KricketBar() : null,
        body: FutureBuilder<List<ArticleData>>(
          future: articles,
          builder: (context, snapshot) {
            if (snapshot.hasError) return ApiErrorView(error: snapshot.error!);
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: K.green));
            return IndexedStack(index: page, children: [HomeScreen(articles: snapshot.data!), NewsScreen(articles: snapshot.data!), const PlaceholderScreen(), const PlaceholderScreen(), const PlaceholderScreen()]);
          },
        ),
        bottomNavigationBar: KricketNav(index: page, onTap: (i) => setState(() => page = i)),
      );
}

class ApiErrorView extends StatelessWidget {
  const ApiErrorView({super.key, required this.error});
  final Object error;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off, color: K.green, size: 44), const SizedBox(height: 12), const Text('Unable to load news', style: TextStyle(color: K.dark, fontSize: 20, fontWeight: FontWeight.w700)), const SizedBox(height: 6), Text('$error', textAlign: TextAlign.center, style: const TextStyle(color: K.body))])));
}

class KricketBar extends StatelessWidget implements PreferredSizeWidget {
  const KricketBar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) => AppBar(
        toolbarHeight: 64,
        backgroundColor: K.dark,
        foregroundColor: K.lime,
        leading: const Icon(Icons.menu, size: 20),
        titleSpacing: 0,
        title: const Text('Kricket.pk', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        actions: const [Icon(Icons.search, size: 20), SizedBox(width: 16), Icon(Icons.notifications_none, size: 21), SizedBox(width: 16)],
      );
}

class KricketNav extends StatelessWidget {
  const KricketNav({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;
  static const items = [(Icons.home, 'Home'), (Icons.newspaper, 'News'), (Icons.sports_cricket, 'Matches'), (Icons.groups, 'Players'), (Icons.person_outline, 'Profile')];
  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 72,
          decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFBFC9BF))), boxShadow: [BoxShadow(color: Color(0x14004D2C), blurRadius: 10, offset: Offset(0, -4))]),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (var i = 0; i < items.length; i++) InkWell(onTap: () => onTap(i), borderRadius: BorderRadius.circular(12), child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: EdgeInsets.symmetric(horizontal: i == index ? 16 : 9, vertical: 5), decoration: BoxDecoration(color: i == index ? K.lime : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(items[i].$1, size: 20, color: i == index ? K.limeText : K.body), const SizedBox(height: 2), Text(items[i].$2, style: TextStyle(fontSize: 11, color: i == index ? K.limeText : K.body))])))]),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.articles});
  final List<ArticleData> articles;
  static const hero = 'assets/images/babar_batting.png';
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Welcome to Kricket.pk', style: TextStyle(color: K.dark, fontSize: 24, height: 1.33, fontWeight: FontWeight.w700, letterSpacing: -.6)), Text('Stay updated with the latest cricket news.', style: TextStyle(color: K.body, fontSize: 16, height: 1.5))])),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: K.green, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Color(0x14004D2C), blurRadius: 10, offset: Offset(0, 4))]), child: Row(children: [const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('●  LIVE • PAK VS AUS', style: TextStyle(color: Color(0xFF7BBD93), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .6)), SizedBox(height: 4), Text.rich(TextSpan(children: [TextSpan(text: 'PAK 245/4 ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)), TextSpan(text: '(42.3 ov)', style: TextStyle(fontSize: 12, color: Color(0x997BBD93)))]), style: TextStyle(color: Color(0xFF7BBD93)))])), FilledButton(style: FilledButton.styleFrom(backgroundColor: K.lime, foregroundColor: K.limeText, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)), onPressed: () {}, child: const Text('VIEW SCORE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))]))),
          const SizedBox(height: 24),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: GestureDetector(onTap:()=>openArticle(context,articles[1]),child:ClipRRect(borderRadius: BorderRadius.circular(12), child: Container(color: Colors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Stack(children: [NetImage(hero, height: 191, width: double.infinity), Positioned(left: 12, top: 12, child: Container(color: const Color(0xFFDC3545), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), child: const Text('TOP STORY', style: TextStyle(color: Colors.white, fontSize: 10))))]), Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(articles[1].title, style: const TextStyle(color: K.dark, fontSize: 24, height: 1.25, fontWeight: FontWeight.w600)), const SizedBox(height: 8), Text(articles[1].summary, style: const TextStyle(color: K.body, fontSize: 16, height: 1.5)), const SizedBox(height: 12), const Text('READ MORE  ➜', style: TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2))]))]))))),
          const SizedBox(height: 24),
          const QuickActions(),
          const SectionTitle(title: 'Cricket News', action: 'SEE ALL'),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(children: [NewsRow(article: articles[0]), const SizedBox(height: 16), NewsRow(article: articles[1]), const SizedBox(height: 16), NewsRow(article: articles[2])])),
          const SectionTitle(title: 'Trending Stories', action: '↗'),
          SizedBox(height: 214, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 24), children: const [TrendCard(image: 'assets/images/u19_training.png', title: 'U19 development camp adds sports psychology'), SizedBox(width: 16), TrendCard(image: 'assets/images/cricket_stadium.png', title: 'Pakistan to host Women’s T20 World Cup 2028')]))
        ]),
      );
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});
  @override
  Widget build(BuildContext context) { const data = [(Icons.newspaper, 'Cricket News'),(Icons.sports_cricket, 'Latest\nMatches'),(Icons.scoreboard, 'Live Scores'),(Icons.groups, 'Trending\nPlayers')]; return Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (var i=0;i<data.length;i++) SizedBox(width: 76, child: Column(children: [Container(width: 56,height:56,decoration: BoxDecoration(color:i==0?K.lime:const Color(0xFFE8E8E8),shape:BoxShape.circle),child:Icon(data[i].$1,size:20,color:K.dark)),const SizedBox(height:8),Text(data[i].$2,textAlign:TextAlign.center,style:const TextStyle(fontSize:11,height:1.27,color:K.ink))]))])); }
}

class SectionTitle extends StatelessWidget { const SectionTitle({super.key,required this.title,required this.action}); final String title,action; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(24,24,24,16),child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[Text(title,style:const TextStyle(color:K.dark,fontSize:20,fontWeight:FontWeight.w600)),Text(action,style:const TextStyle(color:K.limeText,fontSize:12,fontWeight:FontWeight.w700))])); }
class NetImage extends StatelessWidget { const NetImage(this.url,{super.key,this.height,this.width,this.fit=BoxFit.cover}); final String url; final double? height,width; final BoxFit fit; @override Widget build(BuildContext context)=>url.startsWith('assets/')?Image.asset(url,height:height,width:width,fit:fit,errorBuilder:(_,__,___)=>_fallback()):Image.network(url,height:height,width:width,fit:fit,errorBuilder:(_,__,___)=>_fallback()); Widget _fallback()=>Container(height:height,width:width,color:const Color(0xFFE4EAE5),child:const Icon(Icons.sports_cricket,color:K.green,size:42)); }
class NewsRow extends StatelessWidget { const NewsRow({super.key,required this.article}); final ArticleData article; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(8),child:NetImage(article.image,width:96,height:96)),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(article.category,style:const TextStyle(color:K.limeText,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:.6)),const SizedBox(height:4),Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:16,height:1.35,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text('${article.date} • ${article.readTime}',style:const TextStyle(color:K.body,fontSize:11))]))])); }
class TrendCard extends StatelessWidget { const TrendCard({super.key,required this.image,required this.title}); final String image,title; @override Widget build(BuildContext context)=>Container(width:256,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:3)]),clipBehavior:Clip.antiAlias,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[NetImage(image,width:256,height:144),Padding(padding:const EdgeInsets.all(12),child:Text(title,style:const TextStyle(color:K.ink,fontSize:16,height:1.35,fontWeight:FontWeight.w700))) ])); }

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key, required this.articles});
  final List<ArticleData> articles;
  @override Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.only(bottom:32),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    SizedBox(height:58,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),children:[chip('All',true),chip('Pakistan'),chip('International'),chip('Domestic'),chip('PSL')])),
    Padding(padding:const EdgeInsets.symmetric(horizontal:16),child:GestureDetector(onTap:()=>openArticle(context,articles[0]),child:ClipRRect(borderRadius:BorderRadius.circular(12),child:Stack(children:[NetImage(articles[0].image,width:double.infinity,height:202),Container(height:202,decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xD9001C10)]))),Positioned(left:18,right:18,bottom:18,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(articles[0].title,style:const TextStyle(color:Colors.white,fontSize:23,height:1.15,fontWeight:FontWeight.w700),maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:8),Text(articles[0].summary,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontSize:13))]))])))),
    const SectionTitle(title:'Latest News',action:'VIEW ALL ›'),
    for(var article in articles) NewsListCard(article:article),
    const SectionTitle(title:'Trending Stories',action:''),
    SizedBox(height:150,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:16),children:[RealTrendWide(article:articles[1]),const SizedBox(width:12),RealTrendWide(article:articles[3])]))
  ]));
  static Widget chip(String t,[bool active=false])=>Container(margin:const EdgeInsets.only(right:8),padding:const EdgeInsets.symmetric(horizontal:22),alignment:Alignment.center,decoration:BoxDecoration(color:active?K.lime:const Color(0xFFF0F1F0),border:active?null:Border.all(color:const Color(0xFFCBD0CB)),borderRadius:BorderRadius.circular(22)),child:Text(t,style:TextStyle(color:active?K.limeText:K.body,fontSize:12,fontWeight:FontWeight.w600)));
}
class NewsListCard extends StatelessWidget { const NewsListCard({super.key,required this.article}); final ArticleData article; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article),child:Container(margin:const EdgeInsets.fromLTRB(16,0,16,16),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:7,offset:Offset(0,3))]),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(8),child:NetImage(article.image,width:88,height:88)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(article.category,style:const TextStyle(color:K.green,fontSize:10,letterSpacing:1)),const SizedBox(height:5),Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:15,height:1.25,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text('${article.date} • ${article.readTime}',style:const TextStyle(color:K.body,fontSize:10))])),const Icon(Icons.arrow_forward,color:K.green)]))); }
class TrendWide extends StatelessWidget { const TrendWide({super.key,required this.image,required this.title}); final String image,title; @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(14),child:Stack(children:[NetImage(image,width:255,height:150),Container(width:255,height:150,decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xCC001C10)]))),Positioned(left:12,bottom:12,child:Text(title,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w700))) ])); }

void openArticle(BuildContext context, ArticleData article) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => FigmaArticleScreen(article: article)));
}

class RealTrendWide extends StatelessWidget {
  const RealTrendWide({super.key, required this.article});
  final ArticleData article;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => openArticle(context, article),
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            NetImage(article.image, width: 255, height: 150),
            Container(width: 255, height: 150, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD001C10)]))),
            Positioned(left: 12, right: 12, bottom: 12, child: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700))),
          ]),
        ),
      );
}

class FigmaArticleScreen extends StatelessWidget {
  const FigmaArticleScreen({super.key, required this.article});
  final ArticleData article;

  @override
  Widget build(BuildContext context) {
    final related = realArticles.where((item) => item.title != article.title).take(2).toList();
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: K.bg,
      appBar: AppBar(
        toolbarHeight: 64,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: const Color(0x2200341C),
        backgroundColor: Colors.white.withValues(alpha: .97),
        surfaceTintColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, size: 20), onPressed: () => Navigator.pop(context)),
        titleSpacing: 0,
        title: const Text('Kricket.pk', style: TextStyle(color: K.dark, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -.4)),
        actions: const [Icon(Icons.bookmark_border, size: 20), SizedBox(width: 8), Icon(Icons.share_outlined, size: 20), SizedBox(width: 16)],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(25, 40, 25, 56 + safeBottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7), decoration: BoxDecoration(color: K.lime.withValues(alpha: .22), border: Border.all(color: K.lime.withValues(alpha: .55)), borderRadius: BorderRadius.circular(999)), child: Text(article.category, style: const TextStyle(color: K.limeText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
            const Row(children: [Icon(Icons.bookmark_border, size: 19, color: K.dark), SizedBox(width: 18), Icon(Icons.share_outlined, size: 19, color: K.dark)]),
          ]),
          const SizedBox(height: 23),
          Text(article.title, style: const TextStyle(color: K.dark, fontSize: 36, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -.9)),
          const SizedBox(height: 24),
          Container(width: double.infinity, padding: const EdgeInsets.only(left: 24), decoration: const BoxDecoration(border: Border(left: BorderSide(color: Color(0xFF92D5A9), width: 4))), child: Text(article.summary, style: const TextStyle(color: K.body, fontSize: 20, height: 1.62, fontWeight: FontWeight.w500, fontStyle: FontStyle.italic))),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 25),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E2E2)), bottom: BorderSide(color: Color(0xFFE2E2E2)))),
            child: Row(children: [
              const CircleAvatar(radius: 24, backgroundColor: Color(0xFFE6F0E9), child: Icon(Icons.newspaper, color: K.green)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.source, style: const TextStyle(color: K.dark, fontSize: 15, fontWeight: FontWeight.w700)), const SizedBox(height: 3), Text('${article.date}  •  ${article.readTime}', style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w500))])),
            ]),
          ),
          const SizedBox(height: 40),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x1A00341C), blurRadius: 28, offset: Offset(0, 16))]), clipBehavior: Clip.antiAlias, child: NetImage(article.image, width: double.infinity, height: 320)),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.only(top: 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x80E2E2E2)))), child: const Text('Editorial cricket image • Kricket.pk', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 13, height: 1.38, fontStyle: FontStyle.italic))),
          const SizedBox(height: 40),
          for (var i = 0; i < article.body.length; i++) ...[
            if (i == 1) const Padding(padding: EdgeInsets.only(top: 12, bottom: 18), child: Text('What You Need to Know', style: TextStyle(color: K.dark, fontSize: 26, height: 1.4, fontWeight: FontWeight.w800, letterSpacing: -.65))),
            Text(article.body[i], style: const TextStyle(color: K.ink, fontSize: 18, height: 1.8)),
            const SizedBox(height: 23),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(33),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(32), boxShadow: const [BoxShadow(color: Color(0x1400341C), blurRadius: 25, offset: Offset(0, 20))]),
            child: Column(children: [
              const Text('VERIFIED CRICKET REPORT', style: TextStyle(color: Color(0x8000341C), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.2)),
              const SizedBox(height: 12),
              const Icon(Icons.verified, color: K.green, size: 56),
              const SizedBox(height: 8),
              Text(article.date, textAlign: TextAlign.center, style: const TextStyle(color: K.ink, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('Reporting checked against ${article.source}.', textAlign: TextAlign.center, style: const TextStyle(color: K.body, fontSize: 14, height: 1.6)),
              const SizedBox(height: 20),
              Container(width: 48, height: 4, decoration: BoxDecoration(color: K.lime, borderRadius: BorderRadius.circular(99))),
            ]),
          ),
          const SizedBox(height: 48),
          Container(padding: const EdgeInsets.fromLTRB(32, 42, 24, 16), child: Stack(clipBehavior: Clip.none, children: [
            const Positioned(left: -32, top: -42, child: Text('“', style: TextStyle(color: Color(0x1A00341C), fontSize: 80, fontFamily: 'serif'))),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.summary, style: const TextStyle(color: K.dark, fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, letterSpacing: -.6)), const SizedBox(height: 28), Text('— ${article.source.toUpperCase()}', style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2))]),
          ])),
          const SizedBox(height: 42),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final tag in _tagsFor(article)) Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFF3F3F4), border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(12)), child: Text(tag, style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 48),
          const Divider(color: Color(0xFFE2E2E2), thickness: 2),
          const SizedBox(height: 44),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Continue Reading', style: TextStyle(color: K.dark, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.55)), SizedBox(width: 48, child: Divider(color: Color(0x5500341C), thickness: 2))]),
          const SizedBox(height: 32),
          for (final item in related) ...[_RelatedArticleCard(article: item), const SizedBox(height: 32)],
          const SizedBox(height: 8),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 36),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: K.dark, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 64), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, shadowColor: K.green.withValues(alpha: .35)),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back to News', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  List<String> _tagsFor(ArticleData value) => ['#PakistanCricket', '#${value.category.replaceAll(' ', '')}', '#News'];
}

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({required this.article});
  final ArticleData article;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FigmaArticleScreen(article: article))),
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 15, offset: Offset(0, 8))]), clipBehavior: Clip.antiAlias, child: NetImage(article.image, width: double.infinity, height: 191)),
          const SizedBox(height: 15),
          Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: K.ink, fontSize: 18, height: 1.38, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${article.readTime}  •  ${article.category}', style: const TextStyle(color: K.limeText, fontSize: 12, fontWeight: FontWeight.w700)),
        ]),
      );
}

class RealArticleScreen extends StatelessWidget {
  const RealArticleScreen({super.key, required this.article});
  final ArticleData article;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          titleSpacing: 0,
          title: const Text('Kricket.pk', style: TextStyle(color: K.green, fontSize: 16, fontWeight: FontWeight.w700)),
          actions: const [Icon(Icons.bookmark_border), Icon(Icons.share_outlined), SizedBox(width: 8)],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 24, 25, 48),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7), decoration: BoxDecoration(color: K.lime, borderRadius: BorderRadius.circular(18)), child: Text(article.category, style: const TextStyle(color: K.limeText, fontSize: 11, fontWeight: FontWeight.w700))),
            const SizedBox(height: 22),
            Text(article.title, style: const TextStyle(color: K.dark, fontSize: 32, height: 1.08, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.only(left: 18), decoration: const BoxDecoration(border: Border(left: BorderSide(color: K.lime, width: 3))), child: Text(article.summary, style: const TextStyle(color: K.body, fontSize: 16, height: 1.5))),
            const SizedBox(height: 22),
            Row(children: [
              const CircleAvatar(radius: 22, backgroundColor: Color(0xFFE4EAE5), child: Icon(Icons.newspaper, color: K.green)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.source, style: const TextStyle(fontWeight: FontWeight.w700)), Text('${article.date}  •  ${article.readTime}', style: const TextStyle(color: K.body, fontSize: 11))])),
            ]),
            const SizedBox(height: 28),
            ClipRRect(borderRadius: BorderRadius.circular(12), child: NetImage(article.image, width: double.infinity, height: 320)),
            const SizedBox(height: 12),
            Center(child: Text('Photo used for editorial illustration • ${article.source}', textAlign: TextAlign.center, style: const TextStyle(color: K.body, fontSize: 10, fontStyle: FontStyle.italic))),
            const SizedBox(height: 30),
            for (var i = 0; i < article.body.length; i++) ...[
              if (i == 1) const ArticleHeading('What you need to know'),
              ArticleText(article.body[i]),
              const SizedBox(height: 18),
            ],
            Container(width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFFF6F8F5), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFDDE7DD))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SOURCE', style: TextStyle(color: K.green, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(height: 8), Text(article.source, style: const TextStyle(color: K.dark, fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(height: 6), const Text('This article summary uses verified reporting current to July 2026.', style: TextStyle(color: K.body, fontSize: 12, height: 1.5))])),
            const SizedBox(height: 28),
            FilledButton(style: FilledButton.styleFrom(backgroundColor: K.dark, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () => Navigator.pop(context), child: const Text('Back to News')),
          ]),
        ),
      );
}

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key});
  static const hero='https://www.figma.com/api/mcp/asset/f2d12722-30ba-49cc-9fc5-5545ac12abd6';
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:Colors.white,appBar:AppBar(backgroundColor:Colors.white,titleSpacing:0,title:const Text('Kricket.pk',style:TextStyle(color:K.green,fontSize:16,fontWeight:FontWeight.w700)),actions:const [Icon(Icons.bookmark_border),Icon(Icons.share_outlined),SizedBox(width:8)]),body:SingleChildScrollView(padding:const EdgeInsets.fromLTRB(25,24,25,40),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),decoration:BoxDecoration(color:K.lime,borderRadius:BorderRadius.circular(18)),child:const Text('ICC WORLD CUP',style:TextStyle(color:K.limeText,fontSize:11,fontWeight:FontWeight.w700))),const SizedBox(height:22),
    const Text("The Rise of Babar Azam: A Statistical Deep Dive into Pakistan's Batting Pillar",style:TextStyle(color:K.dark,fontSize:32,height:1.08,fontWeight:FontWeight.w800)),const SizedBox(height:20),
    Container(padding:const EdgeInsets.only(left:18),decoration:const BoxDecoration(border:Border(left:BorderSide(color:K.lime,width:3))),child:const Text("How the captain's technique and consistency are rewriting the record books across all formats.",style:TextStyle(color:K.body,fontSize:16,height:1.5))),const SizedBox(height:22),
    const Row(children:[CircleAvatar(radius:22,backgroundColor:Color(0xFFE4EAE5),child:Icon(Icons.person,color:K.green)),SizedBox(width:12),Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Zahid Ahmed',style:TextStyle(fontWeight:FontWeight.w700)),Text('Oct 24, 2023  •  8 min read',style:TextStyle(color:K.body,fontSize:11))])]),const SizedBox(height:28),
    ClipRRect(borderRadius:BorderRadius.circular(12),child:NetImage(hero,width:double.infinity,height:320)),const SizedBox(height:12),const Center(child:Text("Babar Azam's signature cover drive has become a symbol of his technical mastery.",textAlign:TextAlign.center,style:TextStyle(color:K.body,fontSize:10,fontStyle:FontStyle.italic))),const SizedBox(height:30),
    const ArticleText('In the pantheon of modern cricketing greats, few names resonate with the same rhythmic elegance as Babar Azam. While contemporaries might rely on brute force or unorthodox geometry, Babar operates with the precision of a master watchmaker.\n\nHis journey from the streets of Lahore to the summit of the ICC rankings is not just a tale of talent, but a testament to a technical blueprint that seems almost bulletproof.'),
    const ArticleHeading('Consistency is King'),
    const ArticleText('The hallmark of Babar’s batting is his incredible ability to find the gaps with surgical precision. Unlike the frantic pace of modern T20I batting, Babar brings a sense of calm to the crease. Analysts point to his weight transfer as the secret sauce; whether facing a 150kph thunderbolt or a subtle drifter, his head remains still, eyes level, and his bat flows through a perfect arc.'),const SizedBox(height:28),
    Container(width:double.infinity,padding:const EdgeInsets.all(28),decoration:BoxDecoration(color:const Color(0xFFF6F8F5),borderRadius:BorderRadius.circular(18),border:Border.all(color:const Color(0xFFDDE7DD))),child:const Column(children:[Text('AVERAGE IN WINNING CAUSES',style:TextStyle(color:K.green,fontSize:11,fontWeight:FontWeight.w700,letterSpacing:1)),SizedBox(height:12),Text('64.28',style:TextStyle(color:K.dark,fontSize:46,fontWeight:FontWeight.w800)),Text('Highest among active top-order batsmen',textAlign:TextAlign.center,style:TextStyle(color:K.body,fontSize:12))])),const SizedBox(height:28),
    Container(padding:const EdgeInsets.all(24),decoration:const BoxDecoration(border:Border(left:BorderSide(color:K.lime,width:4))),child:const Text('Leadership in Pakistan cricket is often a poisoned chalice, yet Babar has worn it with a quiet stoicism.\n\n— THE EDITORIAL BOARD',style:TextStyle(color:K.dark,fontSize:20,height:1.45,fontWeight:FontWeight.w700,fontStyle:FontStyle.italic))),const ArticleHeading('Continue Reading'),
    const TrendCard(image:'https://www.figma.com/api/mcp/asset/b117a5b1-20f3-45e4-978f-de4d1bfa313a',title:"Shaheen's Opening Spells: A Nightmare for Top Orders"),const SizedBox(height:24),
    FilledButton(style:FilledButton.styleFrom(backgroundColor:K.dark,minimumSize:const Size(double.infinity,56),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),onPressed:()=>Navigator.pop(context),child:const Text('‹  Share Story'))
  ])));
}
class ArticleHeading extends StatelessWidget { const ArticleHeading(this.text,{super.key}); final String text; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:30,bottom:16),child:Text(text,style:const TextStyle(color:K.dark,fontSize:27,fontWeight:FontWeight.w800))); }
class ArticleText extends StatelessWidget { const ArticleText(this.text,{super.key}); final String text; @override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:K.ink,fontSize:16,height:1.75)); }
class PlaceholderScreen extends StatelessWidget { const PlaceholderScreen({super.key}); @override Widget build(BuildContext context)=>const Center(child:Text('Coming soon',style:TextStyle(color:K.dark,fontSize:22,fontWeight:FontWeight.w700))); }
