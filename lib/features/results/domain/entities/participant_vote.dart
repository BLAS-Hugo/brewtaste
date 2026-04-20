class ParticipantVote {
  const ParticipantVote({
    required this.pseudo,
    required this.hasSkipped,
    required this.score,
    required this.guesses,
  });

  final String pseudo;
  final bool hasSkipped;
  final int? score;
  final Map<String, String> guesses;
}
