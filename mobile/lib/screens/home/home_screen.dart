import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/receipt_provider.dart';
import '../receipt/receipt_detail_screen.dart';
import '../receipt/add_receipt_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Receipts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              _showProfileMenu(context, ref);
            },
          ),
        ],
      ),
      body: receiptsAsync.when(
        data: (receipts) {
          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No receipts yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first receipt',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(receiptsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(receipt.status),
                      child: Icon(
                        _getStatusIcon(receipt.status),
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      receipt.storeName ?? 'Unknown Store',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (receipt.productName != null)
                          Text(receipt.productName!),
                        if (receipt.totalAmount != null)
                          Text(
                            '${receipt.currency ?? 'USD'} ${receipt.totalAmount!.toStringAsFixed(2)}',
                          ),
                        if (receipt.warrantyExpiryDate != null)
                          Text(
                            'Warranty: ${receipt.warrantyDaysRemaining} days left',
                            style: TextStyle(
                              color: receipt.isWarrantyExpired
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReceiptDetailScreen(receiptId: receipt.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading receipts: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(receiptsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddReceiptScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final userProfile = ref.watch(userProfileProvider);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              userProfile.when(
                data: (user) => ListTile(
                  leading: const Icon(Icons.account_circle),
                  title: Text(user?.displayName ?? user?.email ?? 'User'),
                  subtitle: Text(user?.email ?? ''),
                ),
                loading: () => const ListTile(
                  leading: CircularProgressIndicator(),
                  title: Text('Loading...'),
                ),
                error: (_, __) => const ListTile(
                  leading: Icon(Icons.error),
                  title: Text('Error loading profile'),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sign Out'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(status) {
    switch (status.toString()) {
      case 'ReceiptStatus.completed':
        return Colors.green;
      case 'ReceiptStatus.processing':
        return Colors.orange;
      case 'ReceiptStatus.ocrFailed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(status) {
    switch (status.toString()) {
      case 'ReceiptStatus.completed':
        return Icons.check_circle;
      case 'ReceiptStatus.processing':
        return Icons.sync;
      case 'ReceiptStatus.ocrFailed':
        return Icons.error;
      default:
        return Icons.receipt;
    }
  }
}
