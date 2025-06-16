class Introduction {
  final String title;
  final String text;

  Introduction(this.title, this.text);

  Introduction.fromMap(Map<String, dynamic> data)
      : title = data['title'] ?? '',
        text = data['text'] ?? '';
}

class Announcement {
  final String type;
  final String timestamp;
  final String title;
  final String content;

  Announcement(this.type, this.timestamp, this.title, this.content);

  Announcement.fromMap(Map<String, dynamic> data)
      : type = data['type'] ?? '',
        timestamp = data['timestamp'] ?? '',
        title = data['title'] ?? '',
        content = data['content'] ?? '';
}
