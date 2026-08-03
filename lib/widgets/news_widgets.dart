import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';
import 'package:kricket_pk/models/article_model.dart';
import 'package:kricket_pk/widgets/net_image.dart';
import 'package:kricket_pk/screens/article_screen.dart';

class NewsRow extends StatelessWidget { const NewsRow({super.key,required this.article,required this.articles}); final ArticleData article; final List<ArticleData> articles; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article,articles),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(8),child:NetImage(article.image,width:96,height:96)),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(article.category,style:const TextStyle(color:K.limeText,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:.6)),const SizedBox(height:4),Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:16,height:1.35,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text('${article.date} • ${article.readTime}',style:const TextStyle(color:K.body,fontSize:11))]))])); }
class TrendCard extends StatelessWidget { const TrendCard({super.key,required this.article,required this.articles}); final ArticleData article; final List<ArticleData> articles; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article,articles),borderRadius:BorderRadius.circular(12),child:Container(width:256,decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:3)]),clipBehavior:Clip.antiAlias,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[NetImage(article.image,width:256,height:130),Padding(padding:const EdgeInsets.symmetric(horizontal:12, vertical:10),child:Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:16,height:1.35,fontWeight:FontWeight.w700))) ]))); }
class NewsListCard extends StatelessWidget { const NewsListCard({super.key,required this.article,required this.articles}); final ArticleData article; final List<ArticleData> articles; @override Widget build(BuildContext context)=>InkWell(onTap:()=>openArticle(context,article,articles),child:Container(margin:const EdgeInsets.fromLTRB(16,0,16,16),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),boxShadow:const [BoxShadow(color:Color(0x10000000),blurRadius:7,offset:Offset(0,3))]),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(8),child:NetImage(article.image,width:88,height:88)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(article.category,style:const TextStyle(color:K.green,fontSize:10,letterSpacing:1)),const SizedBox(height:5),Text(article.title,maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(color:K.ink,fontSize:15,height:1.25,fontWeight:FontWeight.w700)),const SizedBox(height:8),Text('${article.date} • ${article.readTime}',style:const TextStyle(color:K.body,fontSize:10))])),const Icon(Icons.arrow_forward,color:K.green)]))); }
class TrendWide extends StatelessWidget { const TrendWide({super.key,required this.image,required this.title}); final String image,title; @override Widget build(BuildContext context)=>ClipRRect(borderRadius:BorderRadius.circular(14),child:Stack(children:[NetImage(image,width:255,height:150),Container(width:255,height:150,decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topCenter,end:Alignment.bottomCenter,colors:[Colors.transparent,Color(0xCC001C10)]))),Positioned(left:12,bottom:12,child:Text(title,style:const TextStyle(color:Colors.white,fontSize:15,fontWeight:FontWeight.w700))) ])); }
class RealTrendWide extends StatelessWidget {
  const RealTrendWide({super.key, required this.article, required this.articles});
  final ArticleData article;
  final List<ArticleData> articles;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => openArticle(context, article, articles),
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
