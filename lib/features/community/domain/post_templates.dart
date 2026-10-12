class PostField {
  final String key, label;
  final bool required;
  final String kind;
  final List<String> choices;
  const PostField(
    this.key,
    this.label, {
    this.required = false,
    this.kind = 'text',
    this.choices = const [],
  });
}

class PostTemplate {
  final String id, label, emoji, topic, prompt;
  final bool question, communityAnnouncement;
  final List<PostField> fields;
  const PostTemplate(
    this.id,
    this.label,
    this.emoji,
    this.topic,
    this.prompt, {
    this.question = false,
    this.communityAnnouncement = false,
    this.fields = const [],
  });
}

abstract final class PostTemplates {
  static const subjects = [
    'Computer Science',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Business',
    'Education',
  ];
  static const programs = [
    'Matric',
    'FA',
    'FSc',
    'ICS',
    'BS',
    'MS',
    'MPhil',
    'PhD',
    'Diploma',
    'Certificate',
  ];
  static const all = <PostTemplate>[
    PostTemplate(
      'question',
      'Ask a question',
      '❓',
      'Study Help',
      'What are you trying to understand? Share what you have already tried.',
      question: true,
      fields: [
        PostField('subject', 'Subject', required: true, choices: subjects),
        PostField('program', 'Class / program', choices: programs),
        PostField('topic', 'Topic'),
      ],
    ),
    PostTemplate(
      'resource',
      'Notes / resource',
      '📚',
      'Study Resources',
      'What will students learn from these notes?',
      fields: [
        PostField('subject', 'Subject', required: true, choices: subjects),
        PostField('topic', 'Topic', required: true),
        PostField(
          'semester',
          'Semester',
          choices: ['1', '2', '3', '4', '5', '6', '7', '8'],
        ),
      ],
    ),
    PostTemplate(
      'admission',
      'Admission update',
      '🎓',
      'Admissions',
      'Share application details or useful guidance.',
      communityAnnouncement: true,
      fields: [
        PostField('program', 'Program', required: true, choices: programs),
        PostField(
          'deadline',
          'Application deadline',
          required: true,
          kind: 'date',
        ),
        PostField('eligibility', 'Eligibility', required: true),
        PostField(
          'sourceUrl',
          'Official source link',
          required: true,
          kind: 'url',
        ),
      ],
    ),
    PostTemplate(
      'scholarship',
      'Scholarship',
      '💰',
      'Scholarships',
      'Who can apply and what support is offered?',
      communityAnnouncement: true,
      fields: [
        PostField('program', 'Study level', required: true, choices: programs),
        PostField(
          'deadline',
          'Application deadline',
          required: true,
          kind: 'date',
        ),
        PostField('eligibility', 'Eligibility', required: true),
        PostField('coverage', 'Financial support'),
        PostField(
          'sourceUrl',
          'Official source link',
          required: true,
          kind: 'url',
        ),
      ],
    ),
    PostTemplate(
      'study_group',
      'Study partner / group',
      '👥',
      'Study Help',
      'Who would you like to study with?',
      fields: [
        PostField('subject', 'Subject', required: true, choices: subjects),
        PostField(
          'mode',
          'Study mode',
          required: true,
          choices: ['Online', 'In person'],
        ),
        PostField('schedule', 'Available days', required: true, kind: 'days'),
        PostField('time', 'Available time', required: true, kind: 'time'),
        PostField('location', 'Location (for in-person study)'),
      ],
    ),
    PostTemplate(
      'assignment',
      'Exam / assignment help',
      '📝',
      'Exam Preparation',
      'Which concept or step do you need help understanding?',
      question: true,
      fields: [
        PostField(
          'subject',
          'Course / subject',
          required: true,
          choices: subjects,
        ),
        PostField('topic', 'Topic', required: true),
        PostField('deadline', 'Exam / assignment date', kind: 'date'),
      ],
    ),
    PostTemplate(
      'achievement',
      'Share an achievement',
      '🎉',
      'Student Life',
      'Tell the community about your achievement!',
      fields: [
        PostField(
          'milestone',
          'Achievement',
          required: true,
          choices: [
            'Admission',
            'Exam result',
            'Graduation',
            'Certificate',
            'Competition',
            'Other',
          ],
        ),
        PostField('program', 'Program / course', choices: programs),
      ],
    ),
    PostTemplate(
      'poll',
      'Poll / advice',
      '📊',
      'Questions & Answers',
      'What would you like the community to vote on?',
      fields: [
        PostField(
          'duration',
          'Poll duration',
          required: true,
          choices: ['1 day', '3 days', '7 days'],
        ),
      ],
    ),
    PostTemplate(
      'career',
      'Career / internship',
      '💼',
      'Career',
      'Share the opportunity or career question.',
      fields: [
        PostField(
          'purpose',
          'Post about',
          required: true,
          choices: ['Career advice', 'Internship', 'Job opportunity'],
        ),
        PostField(
          'field',
          'Career field',
          required: true,
          choices: [
            'Software',
            'Engineering',
            'Business',
            'Design',
            'Finance',
            'Education',
            'Other',
          ],
        ),
        PostField('organization', 'Organization'),
        PostField('deadline', 'Last date', kind: 'date'),
        PostField('sourceUrl', 'Source link', kind: 'url'),
      ],
    ),
    PostTemplate(
      'general',
      'General post',
      '✍️',
      'General Discussion',
      'Share something with the Talib community.',
    ),
  ];
  static PostTemplate byId(String id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.last);
  static String labelFor(String key) =>
      all
          .expand((t) => t.fields)
          .where((f) => f.key == key)
          .firstOrNull
          ?.label ??
      key;
  static bool validUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null &&
        const ['https', 'http'].contains(uri.scheme) &&
        uri.host.isNotEmpty;
  }

  static String? validate({
    required String type,
    required Map<String, String> values,
    required String body,
    int attachments = 0,
    int institutes = 0,
    List<String> options = const [],
  }) {
    final template = byId(type);
    if (body.length > 10000) return 'Keep the post under 10,000 characters.';
    for (final f in template.fields) {
      final value = (values[f.key] ?? '').trim();
      if (f.required && value.isEmpty) return 'Add ${f.label.toLowerCase()}.';
      if (value.length > 600) return '${f.label} is too long.';
      if (value.isNotEmpty && f.kind == 'url' && !validUrl(value))
        return 'Enter a valid website link.';
      if (value.isNotEmpty &&
          f.kind == 'date' &&
          DateTime.tryParse(value) == null)
        return 'Choose a valid date.';
    }
    if (template.communityAnnouncement && institutes == 0)
      return 'Choose the relevant institute.';
    if (type == 'study_group' &&
        values['mode'] == 'In person' &&
        (values['location'] ?? '').trim().isEmpty)
      return 'Add a meeting location for in-person study.';
    if (type == 'poll' &&
        (body.trim().isEmpty ||
            options.length < 2 ||
            options.length > 5 ||
            options.any((v) => v.trim().isEmpty || v.length > 120) ||
            options.map((v) => v.trim().toLowerCase()).toSet().length !=
                options.length))
      return 'Add a question and 2–5 different poll options.';
    if (type == 'general' && body.trim().isEmpty)
      return 'Write something before publishing.';
    if ((type == 'question' || type == 'assignment') && body.trim().isEmpty)
      return 'Write your question so others can help.';
    if (type == 'resource' && attachments == 0 && body.trim().isEmpty)
      return 'Add notes, a photo, a document or a resource link.';
    if (institutes > 10) return 'Choose up to 10 institutes.';
    if (attachments > 8) return 'You can attach up to 8 items.';
    if (type == 'career' &&
        values['purpose'] == 'Career advice' &&
        body.trim().isEmpty)
      return 'Write your career question or advice.';
    if (type == 'career' &&
        values['purpose'] != 'Career advice' &&
        ((values['organization'] ?? '').isEmpty ||
            !validUrl(values['sourceUrl'] ?? '')))
      return 'Add the organization and source link for this opportunity.';
    return null;
  }

  static String compose(String type, Map<String, String> values, String body) {
    if (body.trim().isNotEmpty) return body.trim();
    final t = byId(type);
    return '${t.label}\n${t.fields.where((f) => (values[f.key] ?? '').trim().isNotEmpty && f.key != 'sourceUrl').map((f) => '${f.label}: ${values[f.key]}').join('\n')}';
  }
}
