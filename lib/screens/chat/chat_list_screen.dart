import 'package:flutter/material.dart';
import '../../services/odoo_api_service.dart';

// Màn hình này sẽ được chúng ta xây dựng ở bước tiếp theo
// import 'chat_detail_screen.dart'; 

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final OdooApiService _apiService = OdooApiService();
  Future<List<dynamic>>? _channelsFuture;

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  void _loadChannels() {
    setState(() {
      _channelsFuture = _apiService.fetchChannels();
    });
  }

  // Hàm helper để làm sạch thẻ HTML từ tin nhắn
  String _stripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChannels,
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _channelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Lỗi: ${snapshot.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có cuộc hội thoại nào.'));
          }

          final channels = snapshot.data!;

          return ListView.separated(
            itemCount: channels.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final channel = channels[index];
              final channelName = channel['name'] ?? 'Không tên';
              
              // Lấy thông tin tin nhắn cuối cùng
              final lastMessage = channel['last_message'];
              String lastMessagePreview = "Chưa có tin nhắn nào";
              String authorName = "";

              if (lastMessage != null) {
                lastMessagePreview = _stripHtmlIfNeeded(lastMessage['body'] ?? '');
                authorName = (lastMessage['author_id'] is List)
                    ? lastMessage['author_id'][1]
                    : " ";
                 // Hiển thị tên người gửi nếu đó là tin nhắn trong nhóm
                if (channel['channel_type'] != 'chat') {
                   lastMessagePreview = '$authorName: $lastMessagePreview';
                }
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Text(
                    channelName.isNotEmpty ? channelName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(channelName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  lastMessagePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // TẠM THỜI: Hiển thị thông báo.
                  // Ở bước sau, chúng ta sẽ điều hướng đến màn hình chi tiết.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sẽ mở chi tiết chat cho: $channelName')),
                  );
                  // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(channel: channel)));
                },
              );
            },
          );
        },
      ),
    );
  }
}
```

### **Làm thế nào để xem màn hình mới này?**

Bây giờ bạn đã có file `ChatListScreen`, bạn cần một cách để đi đến nó. Bạn hãy mở file `dashboard_screen.dart` của mình và thêm một nút bấm mới (giống như nút "Danh sách công việc") để điều hướng đến màn hình chat.

Ví dụ, bạn có thể thêm một `ElevatedButton` như thế này vào màn hình dashboard:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.chat_bubble_outline),
  label: const Text('Tin nhắn'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatListScreen()),
    );
  },
)
