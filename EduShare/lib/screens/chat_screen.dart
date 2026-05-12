import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/product.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ChatScreen extends StatefulWidget {
  final Product? product;
  final String sellerUid;
  final String sellerName;
  final String productId;
  final String productTitle;
  final String productType;
  final String? productImageUrl;
  final String? conversationId;

  const ChatScreen({
    super.key,
    this.product,
    required this.sellerUid,
    required this.sellerName,
    required this.productId,
    required this.productTitle,
    required this.productType,
    this.productImageUrl,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  final TextEditingController _messageCtrl = TextEditingController();
  String? _conversationId;
  bool _bootstrapping = true;
  bool _sending = false;

  bool get _isSupportChat => widget.productId == 'support_admin';

  @override
  void initState() {
    super.initState();
    _bootstrapConversation();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrapConversation() async {
    final seededConversationId = widget.conversationId?.trim();
    if (seededConversationId != null && seededConversationId.isNotEmpty) {
      final currentUserId = _dataService.currentUserId;
      if (currentUserId != null &&
          widget.sellerUid.trim().isNotEmpty &&
          currentUserId != widget.sellerUid) {
        _conversationId =
            await _dataService.ensureConversation(
              sellerUid: widget.sellerUid,
              sellerName: widget.sellerName,
              productId: widget.productId,
              productTitle: widget.productTitle,
              productType: widget.productType,
              productImageUrl: widget.productImageUrl,
            ) ??
            seededConversationId;
      } else {
        _conversationId = seededConversationId;
      }
      if (!mounted) return;
      setState(() => _bootstrapping = false);
      return;
    }

    final product = widget.product;
    if (product == null) {
      if (!mounted) return;
      setState(() => _bootstrapping = false);
      return;
    }

    final conversationId = await _dataService.ensureConversationForProduct(product: product);
    if (!mounted) return;
    setState(() {
      _conversationId = conversationId;
      _bootstrapping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.sellerName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              _isSupportChat
                  ? 'Kenh ho tro voi admin EduShare'
                  : 'Dang trao doi ve san pham',
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.white.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _productHeader(),
          Expanded(
            child: _bootstrapping
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _conversationId == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            'Khong the khoi tao doan chat nay.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      )
                    : StreamBuilder<List<ChatMessage>>(
                        stream: _dataService.watchMessages(_conversationId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28),
                                child: Text(
                                  'Khong tai duoc tin nhan. Kiem tra Firestore rules va thu lai.',
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

                          final messages = snapshot.data ?? const <ChatMessage>[];
                          if (messages.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 28),
                                child: Text(
                                  'Hay gui loi nhan dau tien de bat dau cuoc tro chuyen.',
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

                          final currentUserId =
                              _dataService.currentUserId ?? '';

                          return ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message =
                                  messages[messages.length - 1 - index];
                              final isMine =
                                  message.senderUid == currentUserId;
                              return Align(
                                alignment: isMine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.74,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    10,
                                    14,
                                    10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMine)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            message.senderName,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : AppColors.textDark,
                                          fontSize: 13.5,
                                          height: 1.35,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _timeLabel(message.createdAt),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isMine
                                              ? Colors.white.withValues(
                                                  alpha: 0.78,
                                                )
                                              : AppColors.textGray,
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
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _productHeader() {
    if (_isSupportChat) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 30,
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
                  SizedBox(height: 8),
                  Text(
                    'Ban co the hoi admin ve thanh toan, vi EduShare, giao hang va cac van de tai khoan.',
                    style: TextStyle(
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
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 62,
              height: 62,
              child: buildProductImage(
                type: widget.productType,
                imageUrl: widget.productImageUrl,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    typeLabel(widget.productType),
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.productTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageCtrl,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: _isSupportChat
                      ? 'Nhap noi dung can admin ho tro...'
                      : 'Nhap noi dung can hoi nguoi ban...',
                  filled: true,
                  fillColor: const Color(0xFFF7FAFB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 52,
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_conversationId == null) return;
    final text = _messageCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);
    await _dataService.sendChatMessage(
      conversationId: _conversationId!,
      text: text,
    );
    _messageCtrl.clear();
    if (!mounted) return;
    setState(() => _sending = false);
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
