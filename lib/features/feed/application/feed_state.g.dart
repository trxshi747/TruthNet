// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
  id: json['id'] as String,
  authorId: json['authorId'] as String,
  authorName: json['authorName'] as String,
  content: json['content'] as String,
  mediaUrl: json['mediaUrl'] as String?,
  location: json['location'] as String?,
  likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
  commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
  shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
  isLiked: json['isLiked'] as bool? ?? false,
  isSaved: json['isSaved'] as bool? ?? false,
);

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'content': instance.content,
      'mediaUrl': instance.mediaUrl,
      'location': instance.location,
      'likeCount': instance.likeCount,
      'commentCount': instance.commentCount,
      'shareCount': instance.shareCount,
      'isLiked': instance.isLiked,
      'isSaved': instance.isSaved,
    };
