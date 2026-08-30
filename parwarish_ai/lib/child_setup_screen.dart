import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class ChildSetupScreen extends StatefulWidget {
  @override
  _ChildSetupScreenState createState() => _ChildSetupScreenState();
}

class _ChildSetupScreenState extends State<ChildSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _childName = '';
  String _autismLevel = 'Mild'; // Default level

  final List<String> _levels = ['Mild', 'Moderate', 'Severe'];

  void _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 1. Generate 6-digit alphanumeric ID
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      Random rnd = Random();
      String childId = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

      // 2. Save to Firestore
      try {
        await FirebaseFirestore.instance.collection('children').doc(childId).set({
          'child_id': childId,
          'name': _childName,
          'autism_level': _autismLevel,
          'current_streak': 0,
          'struggle_flags': 0,
          'parent_id': 'pending', // We will link this to the parent later
        });

        // 3. Show Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile Created! Child ID: $childId')),
        );
      } catch (e) {
        print("Error saving to Firestore: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      appBar: AppBar(
        title: const Text('Setup Parwarish.ai Profile'),
        backgroundColor: const Color(0xFF4CA1AF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Child's Name",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
                onSaved: (value) => _childName = value!,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _autismLevel,
                decoration: const InputDecoration(
                  labelText: 'Diagnosed Autism Level',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _levels.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _autismLevel = value!),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _submitProfile,
                child: const Text('Create Profile & Generate ID', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}