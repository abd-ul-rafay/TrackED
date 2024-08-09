import 'package:tracked/services/firestore.dart';
import 'package:flutter/material.dart';
import '../../models/group.dart';
import 'group_message.dart';

class ManageGroups extends StatefulWidget {
  final List<Group> groups;
  const ManageGroups({Key? key, required this.groups}) : super(key: key);

  @override
  State<ManageGroups> createState() => _ManageGroupsState();
}

class _ManageGroupsState extends State<ManageGroups> {

  void addGroup() {
    final textController = TextEditingController();

    // using two times
    void add() {
      final group = Group(name: textController.text.trim().toString(), phoneNumbers: {});

      FirestoreService().addGroup(group, () {
            widget.groups.add(group);
            setState(() {});
          }
      );
      Navigator.pop(context);
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Class/Section:', style: TextStyle(fontWeight: FontWeight.bold),),
          TextField(
              controller: textController,
              textInputAction: TextInputAction.done,
              onEditingComplete: add,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: add,
            child: const Text('Add',)
        ),
      ],
    ),);
  }

  void removeGroup(int index) {
    void delete() {
      FirestoreService().removeGroup(widget.groups[index], () {
        widget.groups.removeAt(index);
        setState(() {});
      });

      Navigator.pop(context);
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Are you sure, you want to delete this group?', style: TextStyle(fontSize: 16.0,),),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: delete,
            child: const Text('Delete',)
        ),
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {
    widget.groups.removeWhere((group) => group.name == 'Demo Group');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Text',),
        actions: [
          IconButton(
            onPressed: addGroup,
            icon: const Icon(Icons.add),),
        ],
      ),
      body: widget.groups.isEmpty? const Center(child: Text('Press + icon to add class/section')) :  Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text('Please Select Class/Section to Message:',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.groups.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: GestureDetector(
                  onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (context) =>
                      GroupMessage(group: widget.groups[index], indexOfGroup: index,),),)
                      .then((value) { setState((){}); }),
                  child: Card(
                    child: ListTile(
                      title: Text(widget.groups[index].name),
                      subtitle: Text('Members: ${widget.groups[index].phoneNumbers.length}'),
                      trailing: IconButton(
                        onPressed: ()=> removeGroup(index),
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
