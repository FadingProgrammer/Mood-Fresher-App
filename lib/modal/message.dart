enum DownloadState {
  notDownloaded,
  downloading,
  downloaded,
}

enum MessageType {
  text,
  image,
  video,
  audio,
  document,
}

class Message {
  final String senderId;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final String mediaName;
  final String mediaUrl;
  DownloadState downloadState;

  Message({
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.type,
    required this.mediaUrl,
    required this.mediaName,
    this.downloadState = DownloadState.notDownloaded,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp,
      'type': type.index,
      'mediaUrl': mediaUrl,
      'mediaName': mediaName,
      'downloadState': downloadState.index
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
        senderId: map['senderId'],
        message: map['message'],
        timestamp: map['timestamp'].toDate(),
        type: MessageType.values[map['type']],
        mediaUrl: map['mediaUrl'],
        mediaName: map['mediaName'],
        downloadState: DownloadState.values[map['downloadState']]);
  }
}
