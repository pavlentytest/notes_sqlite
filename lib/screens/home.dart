import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/db.dart';
import '../theme/colors.dart';

Future<List<Map<String, dynamic>>> readDatabase() async {
  try {
    NotesDatabase notesDb = NotesDatabase();
    await notesDb.initDatabase();
    List<Map> notesList = await notesDb.getAllNotes();
    //await notesDb.deleteAllNotes();
    await notesDb.closeDatabase();
    List<Map<String, dynamic>> notesData = List<Map<String, dynamic>>.from(notesList);
    notesData.sort((a, b) => (a['title']).compareTo(b['title']));
    return notesData;
  } catch(e) {

    return [{}];
  }
}

// Home Screen
class Home extends StatefulWidget{
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  // Read Database and get Notes
  late List<Map<String, dynamic>> notesData;
  List<int> selectedNoteIds = [];

  // Render the screen and update changes
  void afterNavigatorPop() {
    setState(() {});
  }

  // Long Press handler to display bottom bar
  void handleNoteListLongPress(int id) {
    setState(() {
      if (selectedNoteIds.contains(id) == false) {
        selectedNoteIds.add(id);
      }
    });
  }

  // Remove selection after long press
  void handleNoteListTapAfterSelect(int id) {
    setState(() {
      if (selectedNoteIds.contains(id) == true) {
        selectedNoteIds.remove(id);
      }
    });
  }

  // Delete Note/Notes
  void handleDelete() async {
    try {
      NotesDatabase notesDb = NotesDatabase();
      await notesDb.initDatabase();
      for (int id in selectedNoteIds) {
        int result = await notesDb.deleteNote(id);
      }
      await notesDb.closeDatabase();
    } catch (e) {

    } finally {
      setState(() {
        selectedNoteIds = [];
      });
    }
  }


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: (selectedNoteIds.length > 0?
        IconButton(
          onPressed: () {
            setState(() {
              selectedNoteIds = [];
            });
          },
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
        ):
        //AppBarLeading()
        Container()
        ),

        title: Text(
          (selectedNoteIds.length > 0?
          ('Selected ' + selectedNoteIds.length.toString() + '/' + notesData.length.toString()):
          'Notes'
          ),
          style: TextStyle(
            color: Colors.black45,
          ),
        ),

        actions: [
          (selectedNoteIds.length == 0?
          Container():
          IconButton(
            onPressed: () {
              setState(() {
                selectedNoteIds = notesData.map((item) => item['id'] as int).toList();
              });
            },
            icon: Icon(
              Icons.done_all,
              color: Colors.black,
            ),
          )
          )
        ],
      ),

      /*
			//Drawer
			drawer: Drawer(
				child: DrawerList(),
			),
			*/

      //Floating Button
      floatingActionButton: (
          selectedNoteIds.length == 0?
          FloatingActionButton(
            child: const Icon(
              Icons.add,
              color: Colors.black,
            ),
            tooltip: 'New Notes',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/notes_edit',
                arguments: [
                  'new',
                  [{}],
                ],
              ).then((dynamic value) {
                afterNavigatorPop();
              }
              );
              return;
            },
          ):
          null
      ),

      body: FutureBuilder(
          future: readDatabase(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              notesData = snapshot.data!;
              return Stack(
                children: <Widget>[
                  // Display Notes
                  AllNoteLists(
                    snapshot.data,
                    this.selectedNoteIds,
                    afterNavigatorPop,
                    handleNoteListLongPress,
                    handleNoteListTapAfterSelect,
                  ),

                  // Bottom Action Bar when Long Pressed
                  (selectedNoteIds.length > 0?
                  BottomActionBar(
                      handleDelete: handleDelete
                  ):
                  Container()
                  ),
                ],
              );
            } else {
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.black26,
                ),
              );
            }
          }
      ),
    );
  }
}

// Display all notes
class AllNoteLists extends StatelessWidget {
  final data;
  final selectedNoteIds;
  final afterNavigatorPop;
  final handleNoteListLongPress;
  final handleNoteListTapAfterSelect;

  AllNoteLists(
      this.data,
      this.selectedNoteIds,
      this.afterNavigatorPop,
      this.handleNoteListLongPress,
      this.handleNoteListTapAfterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          dynamic item = data[index];
          return DisplayNotes(
            item,
            selectedNoteIds,
            (selectedNoteIds.contains(item['id']) == false? false: true),
            afterNavigatorPop,
            handleNoteListLongPress,
            handleNoteListTapAfterSelect,
          );
        }
    );
  }
}


// A Note view showing title, first line of note and color
class DisplayNotes extends StatelessWidget {
  final notesData;
  final selectedNoteIds;
  final selectedNote;
  final callAfterNavigatorPop;
  final handleNoteListLongPress;
  final handleNoteListTapAfterSelect;

  DisplayNotes(
      this.notesData,
      this.selectedNoteIds,
      this.selectedNote,
      this.callAfterNavigatorPop,
      this.handleNoteListLongPress,
      this.handleNoteListTapAfterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        color: Colors.black45,
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(5.0),
        child: InkWell(
          onTap: () {
            if (selectedNote == false) {
              if (selectedNoteIds.length == 0) {
                Navigator.pushNamed(
                  context,
                  '/notes_edit',
                  arguments: [
                    'update',
                    notesData,
                  ],
                ).then((dynamic value) {
                  callAfterNavigatorPop();
                }
                );
                return;
              }
              else {
                handleNoteListLongPress(notesData['id']);
              }
            }
            else {
              handleNoteListTapAfterSelect(notesData['id']);
            }
          },

          onLongPress: () {
            handleNoteListLongPress(notesData['id']);
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                           color: Colors.black45,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: (
                              selectedNote == false?
                              Text(
                                notesData['title'][0],
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 21,
                                ),
                              ):
                              Icon(
                                Icons.check,
                                color: Colors.black,
                                size: 21,
                              )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children:<Widget>[
                      Text(
                        notesData['title'] != null? notesData['title']: "",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        height: 3,
                      ),

                      Text(
                        notesData['content'] != null? notesData['content'].split('\n')[0]: "",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// BottomAction bar contais options like Delete, Share...
class BottomActionBar extends StatelessWidget {
  final VoidCallback handleDelete;

  BottomActionBar({
    required this.handleDelete
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        child: Material(
          elevation: 2,
          color: Colors.black,
          clipBehavior: Clip.hardEdge,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Delete
                InkResponse(
                  onTap: () => handleDelete(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.delete,
                        color: Colors.black,
                        semanticLabel: 'Delete',
                      ),
                      Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
