import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pm_mobile_frontend/features/user/bloc/user_event.dart';
import '../bloc/user_bloc.dart';
import '../bloc/user_state.dart';

class ManageUserPage extends StatefulWidget {
  final String userName;
  final String userEmail;

  const ManageUserPage({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<ManageUserPage> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<ManageUserPage> {

  @override
  void initState() {
    super.initState();
    context.read<UserBloc>().add(FetchUsers());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state.status == UserStatus.failure && state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }

        if (state.status == UserStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ดำเนินการสำเร็จ')),
          );
        }
      },
      child: Scaffold(
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
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ),
        body: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            final isDeleting = state.status == UserStatus.deleting;
            final isLoading = state.status == UserStatus.loading;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      _WhiteCard(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              label: 'ชื่อ',
                              value: widget.userName,
                              showChevron: false,
                              textColor: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _WhiteCard(
                        child: Column(
                          children: [
                            _buildInfoRow(
                              label: 'บัญชี',
                              value: widget.userEmail,
                              showChevron: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // if (!isHomeOwner) //TODO implement if there's role
                        _WhiteCard(
                          child: InkWell(
                            onTap: isDeleting ? null : _showDeleteConfirmDialog,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const Text(
                                'ลบบัญชี',
                                style: TextStyle(
                                  color: Color(0xFFCF2F2F),
                                  fontWeight: FontWeight.w400,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLoading || isDeleting)
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
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
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w400,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'ยืนยันการลบสมาชิก',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text(
          'คุณต้องการลบสมาชิกคนนี้ออกจากครอบครัวใช่หรือไม่?',
          style: TextStyle(fontWeight: FontWeight.w400),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UserBloc>().add(DeleteUser(widget.userEmail)); //TODO
              Navigator.pop(context);
            },
            child: const Text(
              'ลบ',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w400,
              ),
            ),
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