

// Edit Customer Dialog
class _EditCustomerDialog extends StatefulWidget {
  final CustomerInfo customer;
  final Function(CustomerInfo) onSave;

  const _EditCustomerDialog({
    required this.customer,
    required this.onSave,
  });

  @override
  State<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<_EditCustomerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _gstController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phone);
    _emailController = TextEditingController(text: widget.customer.email);
    _gstController = TextEditingController(text: widget.customer.gstNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Customer Information'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _gstController,
              decoration: const InputDecoration(
                labelText: 'GST Number (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedCustomer = widget.customer.copyWith(
              name: _nameController.text,
              phone: _phoneController.text,
              email: _emailController.text,
              gstNumber: _gstController.text.isEmpty ? null : _gstController.text,
            );
            widget.onSave(updatedCustomer);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Edit Vehicle Dialog
class _EditVehicleDialog extends StatefulWidget {
  final VehicleInfo vehicle;
  final Function(VehicleInfo) onSave;

  const _EditVehicleDialog({
    required this.vehicle,
    required this.onSave,
  });

  @override
  State<_EditVehicleDialog> createState() => _EditVehicleDialogState();
}

class _EditVehicleDialogState extends State<_EditVehicleDialog> {
  late TextEditingController _regController;
  late TextEditingController _makeModelController;
  late TextEditingController _yearController;
  late String _fuelType;

  @override
  void initState() {
    super.initState();
    _regController = TextEditingController(text: widget.vehicle.registrationNumber);
    _makeModelController = TextEditingController(text: widget.vehicle.makeAndModel);
    _yearController = TextEditingController(text: widget.vehicle.year.toString());
    _fuelType = widget.vehicle.fuelType;
  }

  @override
  void dispose() {
    _regController.dispose();
    _makeModelController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Vehicle Information'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _regController,
              decoration: const InputDecoration(
                labelText: 'Registration Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _makeModelController,
              decoration: const InputDecoration(
                labelText: 'Make & Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: 'Year',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _fuelType,
              decoration: const InputDecoration(
                labelText: 'Fuel Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'EV', child: Text('EV')),
                DropdownMenuItem(value: 'ICE', child: Text('ICE')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _fuelType = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedVehicle = widget.vehicle.copyWith(
              registrationNumber: _regController.text,
              makeAndModel: _makeModelController.text,
              year: int.tryParse(_yearController.text) ?? widget.vehicle.year,
              fuelType: _fuelType,
            );
            widget.onSave(updatedVehicle);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// Estimate Preview Dialog
class _EstimatePreviewDialog extends StatelessWidget {
  final ServiceDetail serviceDetail;

  const _EstimatePreviewDialog({required this.serviceDetail});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Service Estimate'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${serviceDetail.customer.name}'),
              Text('Vehicle: ${serviceDetail.vehicle.registrationNumber}'),
              const Divider(height: 24),
              const Text('Periodic Service:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...serviceDetail.periodicServiceItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              Text('Subtotal: ₹${serviceDetail.periodicTotal.toStringAsFixed(2)}'),
              const Divider(height: 24),
              const Text('Bodyshop:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...serviceDetail.bodyshopItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              Text('Subtotal: ₹${serviceDetail.bodyshopTotal.toStringAsFixed(2)}'),
              const Divider(height: 24),
              Text(
                'Grand Total: ₹${serviceDetail.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Generate PDF
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Estimate PDF generated')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Download PDF'),
        ),
      ],
    );
  }
}

// Receipt Preview Dialog
class _ReceiptPreviewDialog extends StatelessWidget {
  final ServiceDetail serviceDetail;

  const _ReceiptPreviewDialog({required this.serviceDetail});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Service Receipt'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('GoGreen Fleet Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text('Receipt Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
              const Divider(height: 24),
              Text('Customer: ${serviceDetail.customer.name}'),
              Text('Phone: ${serviceDetail.customer.phone}'),
              Text('Email: ${serviceDetail.customer.email}'),
              if (serviceDetail.customer.gstNumber != null)
                Text('GST: ${serviceDetail.customer.gstNumber}'),
              const Divider(height: 24),
              Text('Vehicle: ${serviceDetail.vehicle.registrationNumber}'),
              Text('Model: ${serviceDetail.vehicle.makeAndModel}'),
              const Divider(height: 24),
              const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...serviceDetail.periodicServiceItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              ...serviceDetail.bodyshopItems.map((item) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name),
                      Text('₹${(item.partsCost + item.labourCost).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Text(
                'Total Amount: ₹${serviceDetail.grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Generate PDF
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Receipt PDF generated')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: const Text('Download PDF'),
        ),
      ],
    );
  }
}

// Inventory Maker Dialog
class _InventoryMakerDialog extends StatelessWidget {
  final ServiceDetail serviceDetail;

  const _InventoryMakerDialog({required this.serviceDetail});

  @override
  Widget build(BuildContext context) {
    final allItems = [...serviceDetail.periodicServiceItems, ...serviceDetail.bodyshopItems];
    
    return AlertDialog(
      title: const Text('Inventory Maker'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Parts needed for this service:'),
            const SizedBox(height: 16),
            ...allItems.where((item) => item.partsCost > 0).map((item) => 
              ListTile(
                title: Text(item.name),
                subtitle: Text('Quantity: ${item.quantity}'),
                trailing: Text('₹${item.partsCost.toStringAsFixed(2)}'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Generate inventory list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Inventory list generated')),
            );
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
          ),
          child: const Text('Generate List'),
        ),
      ],
    );
  }
}

// Payment Dialog
class _PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final VoidCallback onPaymentComplete;

  const _PaymentDialog({
    required this.totalAmount,
    required this.onPaymentComplete,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  String _paymentMethod = 'Cash';
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Process Payment'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                DropdownMenuItem(value: 'Card', child: Text('Card')),
                DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _paymentMethod = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Process payment in database
            widget.onPaymentComplete();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: const Text('Process Payment'),
        ),
      ],
    );
  }
}
