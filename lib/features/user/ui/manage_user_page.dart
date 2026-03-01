import 'package:flutter/material.dart';
import 'edit_user_name_page.dart';

class ManageUserPage extends StatefulWidget {
  final String userName;
  final String userEmail;
  final String userRole; // 'Home Owner' หรือ 'Member'

  const ManageUserPage({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> {
  bool get isHomeOwner => widget.userRole == 'Home Owner';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black87),
        centerTitle: true,
        title: const Text(
          'สมาชิกครอบครัว',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600, // หัวข้อเป็น w600
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // separate card just for name
            _WhiteCard(
              child: Column(
                children: [
                  // ส่วนชื่อ - ถ้าเป็น Home Owner จะกดไม่ได้และไม่มี Chevron
                  _buildInfoRow(
                    label: 'ชื่อ',
                    value: widget.userName,
                    showChevron: !isHomeOwner,
                    textColor: isHomeOwner ? Colors.black45 : Colors.black,
                    onTap: isHomeOwner
                        ? null // ถ้าเป็น Home Owner จะกดไม่ได้
                        : () async {
                            final newName = await Navigator.push<String>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditUserNamePage(initialName: widget.userName),
                              ),
                            );
                            if (newName != null && newName.isNotEmpty) {
                              // update state or call callback, here just setState
                              setState(() {
                                // we don't have a local variable; mimic update via widget? maybe rebuild with new data
                              });
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // card for account and role
            _WhiteCard(
              child: Column(
                children: [
                  // ส่วนบัญชี
                  _buildInfoRow(
                    label: 'บัญชี',
                    value: widget.userEmail,
                    showChevron: false,
                  ),

                  // ส่วนบทบาท
                  _buildInfoRow(
                    label: 'Family Role',
                    value: widget.userRole,
                    showChevron: false,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ปุ่มลบบัญชี - จะแสดงเฉพาะเมื่อไม่ใช่ Home Owner เท่านั้น
            if (!isHomeOwner)
              _WhiteCard(
                child: InkWell(
                  onTap: () => _showDeleteConfirmDialog(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: const Text(
                      'ลบบัญชี',
                      style: TextStyle(
                        color: Color(0xFFCF2F2F),
                        fontWeight: FontWeight.w400, // นอกนั้นเป็น w400
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool showChevron = false,
    VoidCallback? onTap,
    Color textColor = Colors.black45,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600, // Title label เป็น w600
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w400, // นอกนั้นเป็น w400
                fontSize: 15,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบสมาชิก', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('คุณต้องการลบสมาชิกคนนี้ออกจากครอบครัวใช่หรือไม่?', style: TextStyle(fontWeight: FontWeight.w400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(fontWeight: FontWeight.w400)),
          ),
          TextButton(
            onPressed: () {
              // TODO: Logic ลบสมาชิก
              Navigator.pop(context);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}