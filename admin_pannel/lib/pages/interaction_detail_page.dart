import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gogreen_admin/models/interaction.dart';
import 'package:gogreen_admin/models/vehicle.dart';
import 'package:gogreen_admin/models/task.dart';
import 'package:gogreen_admin/models/maintenance_job.dart';
import 'package:gogreen_admin/pages/estimate_maker_page.dart';
import 'package:gogreen_admin/services/supabase_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InteractionDetailPage extends StatefulWidget {
  final String interactionId;

  const InteractionDetailPage({
    super.key,
    required this.interactionId,
  });

  @override
  State<InteractionDetailPage> createState() => _InteractionDetailPageState();
}

class _InteractionDetailPageState extends State<InteractionDetailPage> {
  final SupabaseService _service = SupabaseService();
  Interaction? _interaction;
  Vehicle? _vehicle;
  Map<String, dynamic>? _customer;
  List<Task> _tasks = [];
  List<MaintenanceJob> _historyJobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _interaction = await _service.getInteractionById(widget.interactionId);
      
      if (_interaction != null) {
        // Load vehicle with customer_id
        final vehicleData = await _service.getVehicleWithCustomer(_interaction!.vehicleId);
        if (vehicleData != null) {
          _vehicle = Vehicle.fromJson(vehicleData);
          
          // Load customer (driver) using customer_id from vehicle
          final customerId = vehicleData['customer_id'] as String?;
          if (customerId != null) {
            _customer = await _service.getCustomerById(customerId);
          }
        }
        
        // Load tasks
        _tasks = await _service.getTasksByInteractionId(widget.interactionId);
        
        // Load maintenance job history
        if (_vehicle != null) {
          _historyJobs = await _service.getMaintenanceJobsByVehicleId(_vehicle!.vehicleId);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Dashboard'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _interaction == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: const Text('Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error ?? 'Interaction not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Dashboard'),
        actions: [
          _ActionButton(
            label: 'Generate Estimate',
            icon: Icons.description,
            color: Colors.blue,
            onPressed: () => _generateEstimate(),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Generate Receipt',
            icon: Icons.receipt,
            color: Colors.green,
            onPressed: () => _generateReceipt(),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Inventory Maker',
            icon: Icons.inventory,
            color: Colors.purple,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Process Payment',
            icon: Icons.credit_card,
            color: Colors.grey,
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Delete Interaction',
            icon: Icons.delete,
            color: Colors.red,
            onPressed: () => _showDeleteDialog(context),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar - Driver, Vehicle, Notes
          SizedBox(
            width: 350,
            child: _buildLeftSidebar(),
          ),
          // Right Main Content - Service Details
          Expanded(
            child: _buildServiceDetails(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftSidebar() {
    return Container(
      color: Theme.of(context).cardColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Section
            _buildDriverSection(),
            const Divider(height: 1),
            
            // Vehicle Section
            _buildVehicleSection(),
            const Divider(height: 1),
            
            // Customer Notes Section
            _buildCustomerNotesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.person, size: 18),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoField('Name', _customer?['full_name'] ?? 'N/A'),
          _buildInfoField('Phone', _customer?['mobile_number'] ?? 'N/A'),
          _buildInfoField('Email', _customer?['email_id'] ?? 'N/A'),
          _buildInfoField('Date', DateFormat('MM/dd/yyyy').format(_interaction!.pickupDateTime)),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              labelText: 'GST Number (Optional)',
              hintText: 'Enter 15-digit GSTIN',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vehicle',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoField('Reg. No.', _vehicle?.vehicleNumber ?? 'N/A'),
          _buildInfoField('Make & Model', '${_vehicle?.make ?? ''} ${_vehicle?.model ?? ''}'.trim()),
          _buildInfoField('Year', _vehicle?.yearOfManufacture?.toString() ?? 'N/A'),
          _buildInfoField('Fuel Type', _vehicle?.fuelType?.toLowerCase() ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildCustomerNotesSection() {
    final notesController = TextEditingController(text: _interaction?.customerNote ?? '');
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer Notes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    hintText: 'Add a new task...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails() {
    // Group tasks by task_type (job name)
    final Map<String, List<Task>> groupedTasks = {};
    for (var task in _tasks) {
      if (!groupedTasks.containsKey(task.taskType)) {
        groupedTasks[task.taskType] = [];
      }
      groupedTasks[task.taskType]!.add(task);
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Service Details',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Job'),
                  onPressed: () => _showEstimateMaker(context),
                ),
              ],
            ),
          ),
          
          // Job Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // Existing job sections
                ...groupedTasks.entries.map((entry) => 
                  _buildJobSection(entry.key, entry.value)
                ),
                
                // History Section
                if (_historyJobs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobSection(String jobName, List<Task> tasks) {
    // Simplified: Just show the job name as a card
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.work_outline,
            size: 20,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              jobName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: () {
              // Delete all tasks for this job
              for (var task in tasks) {
                _deleteTask(task.taskId);
              }
            },
            color: Theme.of(context).colorScheme.error,
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Card(
      child: ExpansionTile(
        title: Text(
          'History',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${_historyJobs.length} jobs assigned by GoGreen'),
        children: _historyJobs.map((job) => ListTile(
          title: Text(job.jobType),
          subtitle: Text('${job.jobCategory} - ${DateFormat('MMM dd, yyyy').format(job.diagnosisDate)}'),
          trailing: Text(
            job.status,
            style: TextStyle(
              color: _getJobStatusColor(job.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        )).toList(),
      ),
    );
  }

  Color _getJobStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'pending_diagnosis':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEstimateMaker(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => EstimateMakerPage(
        interactionId: widget.interactionId,
      ),
    );
    
    if (result == true) {
      // Refresh data if jobs were saved
      _loadData();
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _service.deleteTask(taskId);
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Interaction'),
        content: const Text('Are you sure you want to delete this interaction? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete
              Navigator.pop(context);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateEstimate() async {
    if (_interaction == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildEstimateHeader(),
          pw.SizedBox(height: 20),
          _buildEstimateDetails(),
          pw.SizedBox(height: 20),
          _buildEstimateItems(),
          pw.SizedBox(height: 20),
          _buildEstimateFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  Future<void> _generateReceipt() async {
    if (_interaction == null) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildReceiptHeader(),
          pw.SizedBox(height: 20),
          _buildReceiptDetails(),
          pw.SizedBox(height: 20),
          _buildReceiptItems(),
          pw.SizedBox(height: 20),
          _buildReceiptFooter(),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
    );
  }

  pw.Widget _buildEstimateHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ESTIMATE',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Interaction Number: ${_interaction!.interactionNumber}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildEstimateDetails() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Service Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Primary Job: ${_interaction!.primaryJob}'),
        pw.Text('Vendor: ${_interaction!.vendorName}'),
        pw.Text('Pickup Date: ${DateFormat('dd MMM yyyy HH:mm').format(_interaction!.pickupDateTime)}'),
        pw.Text('Delivery Date: ${DateFormat('dd MMM yyyy').format(_interaction!.deliveryDate)}'),
        pw.Text('Odometer Reading: ${_interaction!.currentOdometerReading} km'),
      ],
    );
  }

  pw.Widget _buildEstimateItems() {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(_interaction!.primaryJob),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '₹${_interaction!.totalAmount.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '₹${_interaction!.totalAmount.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildEstimateFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(_interaction!.customerNote),
        pw.SizedBox(height: 20),
        pw.Text(
          'This is an estimate. Final charges may vary.',
          style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
        ),
      ],
    );
  }

  pw.Widget _buildReceiptHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RECEIPT',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Interaction Number: ${_interaction!.interactionNumber}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildReceiptDetails() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Service Details',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text('Primary Job: ${_interaction!.primaryJob}'),
        pw.Text('Vendor: ${_interaction!.vendorName}'),
        pw.Text('Pickup Date: ${DateFormat('dd MMM yyyy HH:mm').format(_interaction!.pickupDateTime)}'),
        pw.Text('Delivery Date: ${DateFormat('dd MMM yyyy').format(_interaction!.deliveryDate)}'),
      ],
    );
  }

  pw.Widget _buildReceiptItems() {
    return pw.Table(
      border: pw.TableBorder.all(),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Purchase Price'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '₹${_interaction!.purchasePrice.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '₹${_interaction!.sellPrice.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildReceiptFooter() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(_interaction!.customerNote),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
    );
  }
}
