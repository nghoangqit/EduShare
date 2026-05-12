import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_conversation.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  ChatListScreen({super.key});

  final FirebaseDataService _dataService = FirebaseDataService.instance;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Tin nhan'),
      ),
      body: currentUserId == null
          ? const Center(
              child: Text(
                'Vui long dang nhap de xem tin nhan.',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : StreamBuilder<List<ChatConversation>>(
              stream: _dataService.watchConversations(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'Khong tai duoc danh sach tin nhan. Kiem tra Firestore rules va thu lai.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                }

                final conversations = snapshot.data ?? const [];
                if (conversations.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        'Chua co doan chat nao. Hay mo mot san pham va nhan "Chat voi nguoi ban".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: conversations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    final partnerName =
                        conversation.displayNameFor(currentUserId);
                    return InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              conversationId: conversation.id,
                              sellerUid: conversation.sellerUid,
                              sellerName: partnerName,
                              productId: conversation.productId,
                              productTitle: conversation.productTitle,
                              productType: conversation.productType,
                              productImageUrl: conversation.productImageUrl,
                            ),
                          ),
                        );
                      },
                      child: Ink(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: buildProductImage(
                                  type: conversation.productType,
                                  imageUrl: conversation.productImageUrl,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          partnerName,
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _timeLabel(conversation.updatedAt),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    conversation.productTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    conversation.lastMessage.isEmpty
                                        ? 'Chua co tin nhan nao.'
                                        : conversation.lastMessage,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textGray,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _timeLabel(DateTime value) {
    final today = DateTime.now();
    final sameDay =
        today.year == value.year &&
        today.month == value.month &&
        today.day == value.day;
    if (sameDay) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${value.day}/${value.month}';
  }
}
