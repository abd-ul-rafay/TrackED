import 'dart:io';
import 'package:tracked/screens/settings_screens/decide_settings.dart';
import 'package:tracked/screens/profile_screens/profile.dart';
import 'package:tracked/screens/reports_screens/report.dart';
import 'package:tracked/screens/scanning_screens/scan.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/user.dart' as model;
import 'package:flutter/material.dart';
import '../utils/consts.dart';
import '../services/firestore.dart';
import '../widgets/my_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key,}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? image;

  int _pageSelected = 2; // default third (profile) page
  final adminBottomNavigationBarItem = const [
    BottomNavigationBarItem(
        icon: Icon(Icons.camera),
        label: 'Scan'
    ),
    BottomNavigationBarItem(
        icon: Icon(Icons.library_books_sharp),
        label: 'Report'
    ),
    BottomNavigationBarItem(
        icon: Icon(Icons.person_2),
        label: 'Profile'
    ),
    BottomNavigationBarItem(
        icon: Icon(Icons.home_work),
        label: 'Manage'
    ),
  ];
  final nonAdminBottomNavigationBarItem = const [
    BottomNavigationBarItem(
        icon: Icon(Icons.camera),
        label: 'Scan'
    ),
    BottomNavigationBarItem(
        icon: Icon(Icons.library_books_sharp),
        label: 'Report'
    ),
    BottomNavigationBarItem(
        icon: Icon(Icons.person_2),
        label: 'Profile'
    ),
  ];

  void readProfilePhoto() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final imagePath = '${appDirectory.path}/profile_photo.png';

    final File imageFile = File(imagePath);

    image = await imageFile.exists()? imageFile : null;

    if (await imageFile.exists()) {
      image = imageFile;
      setState(() {});
    } else {
      image = null;
      setState(() {});
    }

  }

  @override
  void initState() {
    readProfilePhoto();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<model.User?> (
        stream: FirestoreService().getUserStream(context),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final model.User user = snapshot.data as model.User;
            final adminPages = [ScanPage(user: user,), ReportPage(user: user,), ProfilePage(user: user, onPhotoUpdated: readProfilePhoto, image: image), DecideSettings(user: user),];
            final nonAdminPages = [ScanPage(user: user,), ReportPage(user: user,), ProfilePage(user: user, onPhotoUpdated: readProfilePhoto, image: image),];
            return Scaffold(
              appBar: myAppBar(user, context, _pageSelected),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _pageSelected,
                onTap: (index) {
                  setState(() {
                    _pageSelected = index;
                  });
                },
                selectedItemColor: myColor,
                unselectedItemColor: Colors.grey,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.fixed,
                items: (user.role == 'Admin')? adminBottomNavigationBarItem : nonAdminBottomNavigationBarItem,
              ),
              body: (user.role == 'Admin') ? adminPages[_pageSelected] : nonAdminPages[_pageSelected]
            );
          }

          if (snapshot.hasError) {
            return GestureDetector(
                onTap: (){ FirebaseAuth.instance.signOut(); },
                child: const Scaffold(body: Center(child: Text('Something went wrong!'),),),);
          }

          // loading
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
    );
  }
}
