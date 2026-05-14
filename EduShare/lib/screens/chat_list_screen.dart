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
                  return _buildErrorState();
                }

                final conversations = snapshot.data ?? const [];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeroHeader()),
                    SliverToBoxAdapter(child: _buildSearchStub()),
                    SliverToBoxAdapter(child: _buildSupportShortcut()),
                    if (conversations.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final conversation = conversations[index];
                              final partnerName =
                                  conversation.displayNameFor(currentUserId);
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == conversations.length - 1 ? 0 : 12,
                                ),
                                child: _conversationTile(
                                  context,
                                  currentUserId: currentUserId,
                                  conversation: conversation,
                                  partnerName: partnerName,
                                ),
                              );
                            },
                            childCount: conversations.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06242E), Color(0xFF0D9488), Color(0xFF5FD0C1)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tin nhan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Theo doi trao doi voi nguoi mua, nguoi ban va kenh ho tro trong cung mot noi.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13.2,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchStub() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tim theo ten nguoi dung hoac ten san pham',
              style: TextStyle(
                color: AppColors.textGray,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(Icons.tune_rounded, color: AppColors.textGray, size: 18),
        ],
      ),
    );
  }

  Widget _buildSupportShortcut() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ho tro EduShare',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Can giai dap ve don hang, vi hoac tai khoan? Hoi admin ngay trong chat.',
                  style: TextStyle(
                    fontSize: 12.3,
                    color: AppColors.textGray,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.forum_outlined,
                size: 42,
                color: AppColors.primary,
              ),
              SizedBox(height: 16),
              Text(
                'Chua co doan chat nao',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Hay mo mot san pham va nhan "Chat voi nguoi ban" de bat dau trao doi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _conversationTile(
    BuildContext context, {
    required String currentUserId,
    required ChatConversation conversation,
    required String partnerName,
  }) {
    final isSupport = conversation.productId == 'support_admin';
    return InkWell(
      borderRadius: BorderRadius.circular(24),
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
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: isSupport ? AppColors.primaryLight : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: isSupport
                  ? const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 30,
                    )
                  : buildProductImage(
                      type: conversation.productType,
                      imageUrl: conversation.productImageUrl,
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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isSupport
                              ? const Color(0xFFFFF7E8)
                              : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isSupport
                              ? 'Ho tro'
                              : typeLabel(conversation.productType),
                          style: TextStyle(
                            fontSize: 10.8,
                            color: isSupport
                                ? AppColors.amber
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          conversation.productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    conversation.lastMessage.isEmpty
                        ? 'Chua co tin nhan nao.'
                        : conversation.lastMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.8,
                      color: AppColors.textDark,
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
