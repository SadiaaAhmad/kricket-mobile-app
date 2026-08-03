import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/services/news_api.dart';
import 'package:kricket_pk/widgets/net_image.dart';

void openArticle(BuildContext context, ArticleData article, List<ArticleData> articles) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => FigmaArticleScreen(article: article, articles: articles)));
}

class FigmaArticleScreen extends StatefulWidget {
  const FigmaArticleScreen({super.key, required this.article, required this.articles});
  final ArticleData article;
  final List<ArticleData> articles;

  @override
  State<FigmaArticleScreen> createState() => _FigmaArticleScreenState();
}

class _FigmaArticleScreenState extends State<FigmaArticleScreen> {
  late final Future<ArticleData> fullArticle;

  @override
  void initState() {
    super.initState();
    fullArticle = const KricketNewsApi().getArticle(widget.article.id);
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<ArticleData>(
        future: fullArticle,
        builder: (context, snapshot) {
          // Use full article if loaded, otherwise fall back to preview
          final ArticleData article;
          if (snapshot.hasData) {
            article = snapshot.data!;
          } else if (snapshot.hasError) {
            // If full article fails to load, use preview as fallback
            print('DEBUG: Failed to load full article, using preview. Error: ${snapshot.error}');
            article = widget.article;
          } else {
            // Show loading state with preview
            return const Center(child: CircularProgressIndicator(color: K.green));
          }
          
          final related = widget.articles.where((item) => item.id != article.id).take(3).toList();
          
          return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(25, 40, 25, 56 + safeBottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7), decoration: BoxDecoration(color: K.lime.withValues(alpha: .22), border: Border.all(color: K.lime.withValues(alpha: .55)), borderRadius: BorderRadius.circular(999)), child: Text(article.category, style: const TextStyle(color: K.limeText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
            const Row(children: [Icon(Icons.bookmark_border, size: 19, color: K.dark), SizedBox(width: 18), Icon(Icons.share_outlined, size: 19, color: K.dark)]),
          ]),
          const SizedBox(height: 23),
          Text(article.title, style: const TextStyle(color: K.dark, fontSize: 36, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -.9)),
          const SizedBox(height: 40),
          const SizedBox(height: 40),
          Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x1A00341C), blurRadius: 28, offset: Offset(0, 16))]), clipBehavior: Clip.antiAlias, child: NetImage(article.image, width: double.infinity, height: 320)),
          const SizedBox(height: 16),
          Container(width: double.infinity, padding: const EdgeInsets.only(top: 16), decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0x80E2E2E2)))), child: const Text('Editorial cricket image • Kricket.pk', textAlign: TextAlign.center, style: TextStyle(color: K.body, fontSize: 13, height: 1.38, fontStyle: FontStyle.italic))),
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
          for (var i = 0; i < article.body.length; i++) ...[
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
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(article.title, style: const TextStyle(color: K.dark, fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, fontStyle: FontStyle.italic, letterSpacing: -.6)), const SizedBox(height: 28), Text('— ${article.source.toUpperCase()}', style: const TextStyle(color: K.body, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2))]),
          ])),
          const SizedBox(height: 42),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final tag in _tagsFor(article)) Container(padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9), decoration: BoxDecoration(color: const Color(0xFFF3F3F4), border: Border.all(color: const Color(0xFFE2E2E2)), borderRadius: BorderRadius.circular(12)), child: Text(tag, style: const TextStyle(color: K.dark, fontSize: 12, fontWeight: FontWeight.w700)))]),
          const SizedBox(height: 48),
          const Divider(color: Color(0xFFE2E2E2), thickness: 2),
          const SizedBox(height: 44),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Continue Reading', style: TextStyle(color: K.dark, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.55)), SizedBox(width: 48, child: Divider(color: Color(0x5500341C), thickness: 2))]),
          const SizedBox(height: 32),
          for (final item in related) ...[_RelatedArticleCard(article: item, articles: widget.articles), const SizedBox(height: 32)],
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
          );
        },
      ),
    );
  }

  List<String> _tagsFor(ArticleData value) => ['#PakistanCricket', '#${value.category.replaceAll(' ', '')}', '#News'];
}

class _RelatedArticleCard extends StatelessWidget {
  const _RelatedArticleCard({required this.article, required this.articles});
  final ArticleData article;
  final List<ArticleData> articles;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FigmaArticleScreen(article: article, articles: articles))),
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
    const SizedBox(height:24),
    FilledButton(style:FilledButton.styleFrom(backgroundColor:K.dark,minimumSize:const Size(double.infinity,56),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),onPressed:()=>Navigator.pop(context),child:const Text('‹  Share Story'))
  ])));
}
class ArticleHeading extends StatelessWidget { const ArticleHeading(this.text,{super.key}); final String text; @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.only(top:30,bottom:16),child:Text(text,style:const TextStyle(color:K.dark,fontSize:27,fontWeight:FontWeight.w800))); }
class ArticleText extends StatelessWidget { const ArticleText(this.text,{super.key}); final String text; @override Widget build(BuildContext context)=>Text(text,style:const TextStyle(color:K.ink,fontSize:16,height:1.75)); }
