import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/personaldetails_provider.dart';

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({super.key});
  @override
  _PersonalDetailsState createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PersonalDetailsProvider>(context, listen: false).getUserDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PersonalDetailsProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Name'),
                      subtitle: Text(provider.name.isEmpty ? 'Loading...' : provider.name),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: const Icon(Icons.account_circle),
                      title: const Text('Username'),
                      subtitle: TextField(
                        controller: provider.usernameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your username',
                        ),
                        onChanged: (value) => provider.setUsername(value),
                      ),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: const Icon(Icons.assignment_ind),
                      title: const Text('Registration Number'),
                      subtitle: Text(provider.regNo.isEmpty ? 'Loading...' : provider.regNo),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: Text(provider.email.isEmpty ? 'Loading...' : provider.email),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: const Icon(Icons.wc),
                      title: const Text('Gender'),
                      trailing: DropdownButton<String>(
                        value: provider.selectedGender,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            provider.setGender(newValue);
                          }
                        },
                        items: <String>['Male', 'Female']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text('Date of Birth'),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: provider.dob ?? DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            provider.setDateOfBirth(picked);
                          }
                        },
                        child: Text(
                          provider.dob != null
                              ? '${provider.dob!.day}/${provider.dob!.month}/${provider.dob!.year}'
                              : 'Select Date',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IntrinsicWidth(
                child: ElevatedButton(
                  onPressed: () async {
                    await provider.updateDetails();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('Update'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
