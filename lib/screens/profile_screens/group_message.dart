import 'package:tracked/services/firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../utils/consts.dart';
import '../../models/group.dart';
import '../../services/send_sms.dart';

class GroupMessage extends StatefulWidget {
  final Group group;
  final int indexOfGroup;
  const GroupMessage({Key? key, required this.group, required this.indexOfGroup}) : super(key: key);

  @override
  State<GroupMessage> createState() => _GroupMessageState();
}

class _GroupMessageState extends State<GroupMessage> {
  final textController = TextEditingController();

  void addPhNumber() {
    final nameTextController = TextEditingController();
    final numberTextController = TextEditingController();

    // using two times
    void add() {

      if (nameTextController.text.trim().toString().isEmpty || numberTextController.text.trim().toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fields are empty')));
        return;
      }

      FirestoreService().addPhoneNumber(widget.indexOfGroup, nameTextController.text.trim().toString(), numberTextController.text.trim().toString())
        .then((value) {
          widget.group.phoneNumbers.addAll({ nameTextController.text.trim().toString(): numberTextController.text.trim().toString() });
          setState(() {});
        });

      Navigator.pop(context);
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5.0,),
          TextField(
            controller: nameTextController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Parent - Students Fullname',
              border: UnderlineInputBorder(),
            ),
          ),
          TextField(
            controller: numberTextController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            onEditingComplete: add,
            decoration: const InputDecoration(
              hintText: 'Phone Number',
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

  void editPhNumber(int index) {
    var oldName = widget.group.phoneNumbers.keys.toList()[index];
    var oldPhNo = widget.group.phoneNumbers.values.toList()[index];
    final nameTextController = TextEditingController(text: oldName);
    final numberTextController = TextEditingController(text: oldPhNo);

    void edit() {
      if (nameTextController.text.trim().toString().isEmpty || numberTextController.text.trim().toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fields are empty')));
        return;
      }

      final newName = nameTextController.text.trim();
      final newNumber = numberTextController.text.trim();

      if (newName == widget.group.phoneNumbers.keys.toList()[index] && newNumber == widget.group.phoneNumbers.values.toList()[index]) {
        Navigator.pop(context);
        return;
      }

      FirestoreService().editPhoneNumber(widget.indexOfGroup, widget.group.phoneNumbers.keys.toList()[index], newName, newNumber)
          .then((value) {

        widget.group.phoneNumbers.remove(oldName);
        widget.group.phoneNumbers[newName] = newNumber;
        setState(() {});
      });

      Navigator.pop(context);
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Edit Name and Number', style: TextStyle(fontWeight: FontWeight.bold),),
          TextField(
            controller: nameTextController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
            ),
          ),
          TextField(
            controller: numberTextController,
            textInputAction: TextInputAction.done,
            keyboardType: TextInputType.number,
            onEditingComplete: edit,
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
            onPressed: edit,
            child: const Text('Update',)
        ),
      ],
    ),);
  }

  void removePhNumber(int index) {

    var name = widget.group.phoneNumbers.keys.toList()[index];

    void delete() {
      FirestoreService().removePhoneNumber(widget.indexOfGroup, name)
        .then((value) {
          widget.group.phoneNumbers.remove(name);
          setState(() {});
      });
      Navigator.pop(context);
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Are you sure, you want to delete this phone number?', style: TextStyle(fontSize: 16.0,),),
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

  void checkSmsPermission() async {
    var status = await Permission.sms.status;
    if (status.isDenied) {
      await Permission.sms.request();
    }
  }

  void sendMessage() {
    // press button, shut keyboard
    if (!FocusScope.of(context).hasPrimaryFocus) {
      FocusScope.of(context).unfocus();
    }

    checkSmsPermission();

    if (widget.group.phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No member to send message')));
      return;
    }

    if (textController.text.trim().toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Can\'t send empty message')));
      return;
    }

    showDialog(context: context, builder: (context) => AlertDialog(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Send Message:'),
          Text(textController.text.trim().toString()),
        ],
      ),
      actions: [
        TextButton(
            onPressed: ()=> Navigator.pop(context),
            child: const Text('Cancel')
        ),
        TextButton(
            onPressed: () async {
              bool result = await SmsService.message(
                widget.group.phoneNumbers.values.toList(), // list has list ['name', 'phNumber'] getting all phNumbers
                textController.text.trim().toString(), context
              );

              if (result) {
                Navigator.pop(context);
                textController.clear();
                Fluttertoast.showToast(msg: 'Message sent');
              }
            },
            child: const Text('Send to All',)
        ),
      ],
    ),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name,),
        actions: [
          IconButton(
              onPressed: addPhNumber,
              icon: const Icon(Icons.add,)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: widget.group.phoneNumbers.isEmpty ? const Center(child: Text('Press + icon to add phone numbers'),) :  Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15.0,),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15.0),
              child: Text('List of Parents',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,),
              ),
            ),
            const SizedBox(height: 5.0,),
            Expanded(
              child: ListView.builder(
                itemCount: widget.group.phoneNumbers.length,
                itemBuilder: (context, index) {
                  final key = widget.group.phoneNumbers.keys.toList()[index];
                  final value = widget.group.phoneNumbers.values.toList()[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.65,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(key, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
                                Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(onTap: ()=> editPhNumber(index), child: const Icon(Icons.edit)),
                              const SizedBox(width: 10.0,),
                              GestureDetector(onTap: ()=> removePhNumber(index), child: const Icon(Icons.delete),),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              ),
            ),
            const SizedBox(height: 10.0,),
            const Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: Text('Please type your message below:',
                style: TextStyle(fontSize: 14.0,),
              ),
            ),
            const SizedBox(height: 10.0,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Column(
                children: [
                  TextField(
                    // style: TextStyle(height: 5.0,),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: textController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 50.0, horizontal: 5.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: sendMessage,
                        child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 25,),
                            decoration: BoxDecoration(
                              color: MediaQuery.of(context).platformBrightness == Brightness.light? myLightColor : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: const Text('Send to All', style: TextStyle(color: Colors.white),)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35.0,),
          ],
        ),
      ),
    );
  }
}
