import 'package:flutter/material.dart';
import 'package:kricket_pk/constants/app_theme.dart';

class NetImage extends StatelessWidget { const NetImage(this.url,{super.key,this.height,this.width,this.fit=BoxFit.cover}); final String url; final double? height,width; final BoxFit fit; @override Widget build(BuildContext context)=>url.startsWith('assets/')?Image.asset(url,height:height,width:width,fit:fit,errorBuilder:(_,__,___)=>_fallback()):Image.network(url,height:height,width:width,fit:fit,errorBuilder:(_,__,___)=>_fallback()); Widget _fallback()=>Container(height:height,width:width,color:const Color(0xFFE4EAE5),child:const Icon(Icons.sports_cricket,color:K.green,size:42)); }
