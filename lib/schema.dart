//==============型定義================
class TopicContent {
  final String title;
  final String summary;
  final String type;
  TopicContent(this.title, this.type, this.summary);
}

//==============Enum定義================
enum TopicType { event, life, cityAdministration, transportation, cultre }
