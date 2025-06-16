
class LikePostRequest {
  final String hospitalId;
  final String userId;
  final bool like;

  LikePostRequest(
      this.hospitalId, this.userId, this.like);

  String encode() {
    return '{"hospitalId":"$hospitalId",'
        '"userId":"$userId",'
        '"like":${like ? 1 : 0}}';
  }
}
