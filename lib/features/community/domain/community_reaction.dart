class CommunityReaction {
  final String id, label, emoji;
  const CommunityReaction(this.id, this.label, this.emoji);
  static const all = [
    CommunityReaction('like', 'Like', '👍'),
    CommunityReaction('insightful', 'Insightful', '💡'),
    CommunityReaction('helpful', 'Helpful', '🙌'),
    CommunityReaction('celebrate', 'Celebrate', '🎉'),
    CommunityReaction('support', 'Support', '❤️'),
  ];
  static bool valid(String? id) => id == null || all.any((r) => r.id == id);
  static CommunityReaction byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => all.first);
}
