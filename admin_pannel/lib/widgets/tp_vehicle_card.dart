import 'package:flutter/material.dart';
import 'package:gogreen_admin/theme/app_colors.dart';

class TPVehicleCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(DateTime) onDateChange;

  const TPVehicleCard({
    super.key,
    required this.data,
    required this.onTap,
    required this.onDelete,
    required this.onDateChange,
  });

  @override
  State<TPVehicleCard> createState() => _TPVehicleCardState();
}

class _TPVehicleCardState extends State<TPVehicleCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Extract data with fallbacks
    final title = widget.data['title'] ?? 'Unknown Customer';
    final description = widget.data['description'] ?? 'Vehicle Model • AB 12 CD 3456';
    final dueDateStr = widget.data['due_date'];
    final DateTime? dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
    
    // Parse description if it follows a specific format, otherwise use as is
    String customerName = title;
    String vehicleInfo = description;
    
    // For demo purposes, if description doesn't look formatted, we might want to split or format it
    // But adhering to "Display the Customer Name... Below it, show the Vehicle Model"
    // We assume 'title' maps to Customer Name and 'description' to Vehicle Model + Reg No.

    return Draggable<Map<String, dynamic>>(
      data: widget.data,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280, // Match column width
          child: _buildCardContent(customerName, vehicleInfo, dueDate, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildCardContent(customerName, vehicleInfo, dueDate),
      ),
      child: _buildCardContent(customerName, vehicleInfo, dueDate),
    );
  }

  Widget _buildCardContent(String customerName, String vehicleInfo, DateTime? dueDate, {bool isDragging = false}) {
    // Parse vehicle info to extract model and registration separately
    // Assuming format: "Vehicle Model • Registration"
    List<String> vehicleParts = vehicleInfo.split('•').map((e) => e.trim()).toList();
    String vehicleModel = vehicleParts.isNotEmpty ? vehicleParts[0] : vehicleInfo;
    String vehicleReg = vehicleParts.length > 1 ? vehicleParts[1] : '';
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovering ? const Color(0xFF3b82f6) : const Color(0xFFe5e7eb),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Side (Info)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Garage/Vendor Name (Top - Bold & Larger)
                          Text(
                            customerName,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Vehicle Model/Variant
                          Text(
                            vehicleModel,
                            style: const TextStyle(
                              color: Color(0xFF6b7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (vehicleReg.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            // Vehicle Registration Number
                            Text(
                              vehicleReg,
                              style: const TextStyle(
                                color: Color(0xFF9ca3af),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Side (Schedule)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () async {
                            // Quick Date Edit Popup
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (picked != null) {
                              widget.onDateChange(picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFdbeafe), // Light blue bg
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dueDate != null
                                  ? '${dueDate.day} ${_getMonthName(dueDate.month)} ${dueDate.year}'
                                  : 'No Date',
                              style: const TextStyle(
                                color: Color(0xFF2563eb), // Blue text
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dueDate != null
                              ? '${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')} ${dueDate.hour >= 12 ? 'pm' : 'am'}'
                              : '--:--',
                          style: const TextStyle(
                            color: Color(0xFF9ca3af),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
