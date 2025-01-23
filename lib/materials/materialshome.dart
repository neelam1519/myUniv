import 'dart:io';
import 'package:findany_flutter/materials/units.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'materials_provider.dart';

class MaterialsHome extends StatelessWidget {
  const MaterialsHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MaterialsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Subjects',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined, size: 28),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (BuildContext context) {
                      return Padding(
                        padding: MediaQuery.of(context).viewInsets,
                        child: Consumer<MaterialsProvider>(
                          builder: (context, materialProvider, child) {
                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Filter Options',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16.0),
                                  _buildDropdown(
                                    context,
                                    'Year',
                                    materialProvider.yearsList,
                                    materialProvider.currentYearSelectedOption,
                                    materialProvider.currentYearSelection,
                                  ),
                                  const SizedBox(height: 16.0),
                                  _buildDropdown(
                                    context,
                                    'Branch',
                                    materialProvider.branchList,
                                    materialProvider.currentBranchSelectedOption, (value) {
                                    materialProvider.branchSelectedOption = value;
                                    materialProvider.updateSharedPrefsValues();
                                    materialProvider.getSubjects();
                                  },
                                  ),
                                  const SizedBox(height: 24.0),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      if (!await materialProvider.utils.checkInternetConnection()) {
                                        provider.utils.showToastMessage('Connect to the Internet');
                                        return;
                                      }
                                      materialProvider.subjects.clear();
                                      Navigator.pop(context);
                                      materialProvider.getSubjects();
                                    },
                                    child: const Text(
                                      'Apply Filters',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
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
                Container(
                  width: double.infinity,
                  color: Colors.amberAccent,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Text(
                    provider.announcementText!,
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: provider.subjects.isEmpty  // Check for loading state
                      ? _buildShimmerEffect() // Display shimmer effect while loading
                      : ListView.builder(
                    itemCount: provider.subjects.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          title: Text(
                            provider.subjects[index].toString(),
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                          onTap: () async {
                            provider.selectedSubject = provider.subjects[index];

                            String subjectID = "";
                            List<Map<String,String>> data = provider.subjectsWithID;
                            print('Selected Subject: ${provider.selectedSubject}');

                            for (var subject in data) {
                              if (subject.containsKey(provider.selectedSubject)) {
                                subjectID = subject[provider.selectedSubject]!;
                                break;
                              }
                            }

                            print('Subject ID: $subjectID');

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Units(
                                  subjectID: subjectID,
                                  subjectname: provider.selectedSubject,
                                ),
                              ),
                            );
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

  Widget _buildShimmerEffect() {
    return ListView.builder(
      itemCount: 10, // Shimmer effect shows for 10 items by default
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            elevation: 4.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              title: Container(
                height: 16.0,
                color: Colors.white,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String? selectedItem, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          value: selectedItem,
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
        ),
      ],
    );
  }
}
