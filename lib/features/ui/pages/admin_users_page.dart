import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/ui/bloc/auth_bloc.dart';
import 'package:smart_cucumber_agriculture_system/features/data/models/auth_user_model.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<AuthUser>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _usersFuture = context.read<AuthCubit>().fetchAllUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<AuthUser>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data ?? [];

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(
                    user.status,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(color: _getStatusColor(user.status)),
                  ),
                ),
                title: Text(user.displayName ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(user.status),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: user.role == 'admin'
                    ? const Icon(Icons.admin_panel_settings, color: Colors.blue)
                    : PopupMenuButton<String>(
                        onSelected: (status) async {
                          await context.read<AuthCubit>().updateUserStatus(
                            user.uid,
                            status,
                          );
                          _refresh();
                        },
                        itemBuilder: (context) {
                          if (user.status == 'pending') {
                            return [
                              const PopupMenuItem(
                                value: 'approved',
                                child: Text('Approve'),
                              ),
                              const PopupMenuItem(
                                value: 'rejected',
                                child: Text('Reject'),
                              ),
                            ];
                          } else {
                            final bool isBlocked = user.status == 'blocked';
                            return [
                              PopupMenuItem(
                                value: isBlocked ? 'approved' : 'blocked',
                                child: Text(isBlocked ? 'Unblock' : 'Block'),
                              ),
                            ];
                          }
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
