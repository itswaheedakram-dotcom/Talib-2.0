import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';
import '../../../common/presentation/screens/bookmarks_screen.dart';
import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override State<MainScreen> createState()=>_MainScreenState();
}
class _MainScreenState extends State<MainScreen>{
  int index=0;
  final pages=const[HomeScreen(),SearchScreen(),CommunityScreen(),BookmarksScreen()];
  @override Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Talib 2.0',style:TextStyle(fontWeight:FontWeight.w500)),leading:Builder(builder:(context)=>IconButton(icon:const Icon(Icons.menu),onPressed:()=>Scaffold.of(context).openDrawer()))),
    drawer:Drawer(child:ListView(padding:EdgeInsets.zero,children:[
      const DrawerHeader(decoration:BoxDecoration(color:Color(0xFF4CAF50)),child:Align(alignment:Alignment.bottomLeft,child:Text('Talib 2.0',style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.w500)))),
      ListTile(leading:const Icon(Icons.home),title:const Text('Home'),onTap:(){Navigator.pop(context);setState(()=>index=0);}),
      ListTile(leading:const Icon(Icons.search),title:const Text('Search'),onTap:(){Navigator.pop(context);setState(()=>index=1);}),
      ListTile(leading:const Icon(Icons.group),title:const Text('Community'),onTap:(){Navigator.pop(context);setState(()=>index=2);}),
      ListTile(leading:const Icon(Icons.bookmark),title:const Text('Bookmarks'),onTap:(){Navigator.pop(context);setState(()=>index=3);}),
      ListTile(leading:const Icon(Icons.info_outline),title:const Text('About Us'),onTap:()=>_showAbout(context)),
      ListTile(leading:const Icon(Icons.person_outline),title:const Text('Profile / Sign In'),onTap:(){Navigator.pop(context);context.push('/signin');}),
    ])),
    body:IndexedStack(index:index,children:pages),
    bottomNavigationBar:BottomNavigationBar(currentIndex:index,onTap:(v)=>setState(()=>index=v),type:BottomNavigationBarType.fixed,selectedItemColor:const Color(0xFF4CAF50),unselectedItemColor:Colors.grey,items:const[
      BottomNavigationBarItem(icon:Icon(Icons.home_outlined),activeIcon:Icon(Icons.home),label:'Home'),
      BottomNavigationBarItem(icon:Icon(Icons.search),label:'Search'),
      BottomNavigationBarItem(icon:Icon(Icons.group_outlined),activeIcon:Icon(Icons.group),label:'Community'),
      BottomNavigationBarItem(icon:Icon(Icons.bookmark_border),activeIcon:Icon(Icons.bookmark),label:'Bookmarks'),
    ]),
  );
  void _showAbout(BuildContext context){Navigator.pop(context);showAboutDialog(context:context,applicationName:'Talib 2.0',applicationVersion:'2.0',applicationLegalese:'Educational and career guidance platform.',children:const[Text('Find institutes, scholarships, courses, seminars, hostels, internships, jobs and connect with the student community.')]);}
}
