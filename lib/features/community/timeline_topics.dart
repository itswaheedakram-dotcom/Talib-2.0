class TimelineTopic {
  final String name;
  final String emoji;
  const TimelineTopic(this.name, this.emoji);
}

abstract final class TimelineTopics {
  static const all = <TimelineTopic>[
    TimelineTopic('Admissions','🎓'),
    TimelineTopic('Career','💼'),
    TimelineTopic('Scholarships','💰'),
    TimelineTopic('Study Help','📚'),
    TimelineTopic('Institute Reviews','🏫'),
    TimelineTopic('Announcements','📢'),
    TimelineTopic('Entry Tests','📝'),
    TimelineTopic('Exam Preparation','📖'),
    TimelineTopic('Internships','💻'),
    TimelineTopic('Jobs','💼'),
    TimelineTopic('Study Resources','📚'),
    TimelineTopic('Study Abroad','🌍'),
    TimelineTopic('Hostels','🏠'),
    TimelineTopic('Events & Seminars','🎤'),
    TimelineTopic('Student Life','🎒'),
    TimelineTopic('Gaming','🎮'),
    TimelineTopic('Esports','🏆'),
    TimelineTopic('Sports','⚽'),
    TimelineTopic('Cricket','🏏'),
    TimelineTopic('Movies & Series','🎬'),
    TimelineTopic('Music','🎵'),
    TimelineTopic('Memes & Fun','😂'),
    TimelineTopic('Photography','📸'),
    TimelineTopic('Art & Creativity','🎨'),
    TimelineTopic('Tech & Gadgets','📱'),
    TimelineTopic('General Discussion','🗣️'),
    TimelineTopic('Questions & Answers','💬'),
    TimelineTopic('Travel','🧳'),
    TimelineTopic('Food & Cafes','🍔'),
    TimelineTopic('Transport','🚌'),
    TimelineTopic('Freelancing','🚀'),
    TimelineTopic('Skills & Courses','🛠️'),
    TimelineTopic('Degree & Programs','🎯'),
    TimelineTopic('Fee & Financial Aid','💵'),
    TimelineTopic('Admission Deadlines','📅'),
    TimelineTopic('Institute Updates','🏛️'),
  ];

  static TimelineTopic? byName(String name) {
    for (final topic in all) {
      if (topic.name == name) return topic;
    }
    return null;
  }

  // Topics are opt-in. New users start with only For You + Following + Add.
  static const defaults = <String>[];
}
