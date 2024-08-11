import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/materials_provider.dart';
import 'units.dart';

class MaterialsHome extends StatelessWidget {
  const MaterialsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Subjects'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Consumer<MaterialsProvider>(
                            builder: (context, materialProvider, child){
                              return SingleChildScrollView(
                                child: Container(
                                  color: Colors.white,
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(height: 20.0),
                                      const Text(
                                        'Year',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      DropdownButton<String>(
                                        value: materialProvider.currentYearSelectedOption,
                                        onChanged: (String? newValue) {
                                          // provider.currentYearSelectedOption = newValue;
                                          materialProvider.currentYearSelection(newValue);
                                          materialProvider.getSpecialization();
                                          materialProvider.updateSharedPrefsValues();
                                          materialProvider.getSubjects();
                                        },
                                        isDense: true,
                                        items: provider.yearsList
                                            .map<DropdownMenuItem<String>>((String? value) {
                                          return DropdownMenuItem<String>(
                                            value: value!,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 20.0),
                                      const Text(
                                        'Branch',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      DropdownButton<String>(
                                        value: materialProvider.currentBranchSelectedOption,
                                        onChanged: (String? newValue) {
                                          materialProvider.branchSelectedOption = newValue;
                                          materialProvider.getSpecialization();
                                          materialProvider.updateSharedPrefsValues();
                                          materialProvider.getSubjects();
                                        },
                                        isDense: true,
                                        items: materialProvider.branchList
                                            .map<DropdownMenuItem<String>>((String? value) {
                                          return DropdownMenuItem<String>(
                                            value: value!,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 20.0),
                                      const Text(
                                        'Stream',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      DropdownButton<String>(
                                        value: materialProvider.currentStreamSelectedOption,
                                        onChanged: (String? newValue) {
                                          // materialProvider.streamSelectedOption = newValue;
                                          materialProvider.newStreamSelection(newValue);
                                        },
                                        isDense: true,
                                        items: materialProvider.availableSpecializations
                                            .map<DropdownMenuItem<String>>((String? value) {
                                          return DropdownMenuItem<String>(
                                            value: value!,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 20.0),
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (!await materialProvider.utils.checkInternetConnection()) {
                                            provider.utils.showToastMessage('Connect to the Internet');
                                            return;
                                          }
                                          Navigator.pop(context);
                                          materialProvider.getSubjects();
                                          materialProvider.updateSharedPrefsValues();
                                        },
                                        child: const Text('Submit'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (provider.announcementText != null && provider.announcementText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
                  child: Text(
                    provider.announcementText!,
                    style: const TextStyle(
                      fontSize: 15.0,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ListView.builder(
                    itemCount: provider.availableSubjects.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: ListTile(
                          title: Text(provider.availableSubjects[index].toString()),
                          onTap: () async {
                            final selectedSubject = provider.availableSubjects[index].toString();
                            if (!await provider.utils.checkInternetConnection()) {
                              provider.utils.showToastMessage('Connect to the Internet');
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Units(
                                  path: 'materials/${provider.yearSelectedOption}/$selectedSubject',
                                  subject: selectedSubject,
                                ),
                              ),
                            ).then((_) {
                              provider.selectedSubjects.remove(selectedSubject);
                              provider.selectedSubjects.insert(0, selectedSubject);
                              provider.sortSubjects();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

