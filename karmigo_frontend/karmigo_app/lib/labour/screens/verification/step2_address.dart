import 'package:flutter/material.dart';
import 'step3_payment.dart';

class Step2Address extends StatefulWidget {
  final Map<String, dynamic> previousData;
  const Step2Address({super.key, required this.previousData});

  @override
  State<Step2Address> createState() => _Step2AddressState();
}

class _Step2AddressState extends State<Step2Address> {
  final address1 = TextEditingController();
  final address2 = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final zip = TextEditingController();
  final emergencyName = TextEditingController();
  final emergencyPhone = TextEditingController();

  void _next() {
    if (address1.text.isEmpty || city.text.isEmpty || state.text.isEmpty || zip.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required address fields")),
      );
      return;
    }
    if (emergencyName.text.isEmpty || emergencyPhone.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency contact is mandatory")),
      );
      return;
    }

    // Merge Data
    final data = Map<String, dynamic>.from(widget.previousData);
    data.addAll({
      "address_line1": address1.text.trim(),
      "address_line2": address2.text.trim().isEmpty ? null : address2.text.trim(),
      "city": city.text.trim(),
      "state": state.text.trim(),
      "zip_code": zip.text.trim(),
      "emergency_contact_name": emergencyName.text.trim(),
      "emergency_contact_number": emergencyPhone.text.trim(),
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Step3Payment(previousData: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Step 2: Address")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Current Address", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            TextField(controller: address1, decoration: const InputDecoration(labelText: "Address Line 1", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: address2, decoration: const InputDecoration(labelText: "Address Line 2 (Optional)", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: city, decoration: const InputDecoration(labelText: "City", border: OutlineInputBorder()))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: state, decoration: const InputDecoration(labelText: "State", border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 10),
            TextField(controller: zip, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Zip/Pin Code", border: OutlineInputBorder())),
            
            const SizedBox(height: 30),
            const Text("Emergency Contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: emergencyName, decoration: const InputDecoration(labelText: "Contact Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: emergencyPhone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: "Contact Phone", border: OutlineInputBorder())),
            
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _next,
              child: const Text("Next Step"),
            ),
          ],
        ),
      ),
    );
  }
}
