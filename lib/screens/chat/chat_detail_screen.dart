import 'package:flutter/material.dart';
import '../../services/odoo_api_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> channel;

  const ChatDetailScreen({Key? key, required this.channel}) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final OdooApiService _apiService = OdooApiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic>? _messages;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSending = false;

  // Lấy ID của người dùng hiện tại để phân biệt tin nhắn của "mình"
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool scrollToBottom = false}) async {
    if (!scrollToBottom) {
      setState(() => _isLoading = true);
    }

    try {
      final int channelId = widget.channel['id'];
      final messages = await _apiService.fetchMessages(channelId: channelId);

      // Lấy ID người dùng hiện tại từ tin nhắn đầu tiên (nếu có)
      // Odoo không cung cấp API lấy ID trực tiếp dễ dàng
      if (_currentUserId == null && messages.isNotEmpty) {
        _currentUserId = _apiService.getCurrentUserId();
      }

      setState(() {
        _messages = messages;
        _errorMessage = null;
      });

      // Tự động cuộn xuống cuối sau khi tin nhắn được tải
      if (scrollToBottom) {
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      return;
    }

    // Ẩn bàn phím
    FocusScope.of(context).unfocus();
    setState(() => _isSending = true);

    try {
      final int channelId = widget.channel['id'];
      await _apiService.postMessage(channelId: channelId, message: messageText);
      _messageController.clear();
      // Tải lại tin nhắn và cuộn xuống dưới cùng
      await _loadMessages(scrollToBottom: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi gửi tin nhắn: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  String _stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.channel['name'] ?? 'Chi tiết'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Lỗi: $_errorMessage'));
    }
    if (_messages == null || _messages!.isEmpty) {
      return const Center(child: Text('Hãy bắt đầu cuộc trò chuyện!'));
    }

    // Tự động cuộn xuống khi build xong
    _scrollToBottom();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages!.length,
      itemBuilder: (context, index) {
        final message = _messages![index];
        final authorId =
            (message['author_id'] is List) ? message['author_id'][0] : -1;
        final isMe = authorId == _currentUserId;

        return _MessageBubble(
          message: _stripHtmlIfNeeded(message['body'] ?? ''),
          author: (message['author_id'] is List)
              ? message['author_id'][1]
              : 'Không rõ',
          isMe: isMe,
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.black12,
                  hintText: 'Nhập tin nhắn...',
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8.0),
            _isSending
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator()),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }
}

// Widget bong bóng chat để tái sử dụng
class _MessageBubble extends StatelessWidget {
  final String message;
  final String author;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.author,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey.shade300,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  author,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade700,
                    fontSize: 12,
                  ),
                ),
              Text(
                message,
                style: TextStyle(color: isMe ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
