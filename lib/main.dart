import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:summary_pdf/helpPage.dart';
import 'package:summary_pdf/detailPage.dart';
import 'package:summary_pdf/schema.dart';
import 'package:summary_pdf/widget.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

const summaryPrompt = "次のテキストを1文にまとめて下さい";
const contentTitlePrompt = "次のテキストの内容に対して見出しを1文で作成してください";
const contentTypePrompt =
    '次のテキストをイベント,生活,市政,交通,文化の1カテゴリに必ず分類して、不要な記号はつけずにカテゴリ名のみ返してください。';

Future<void> main() async {
  await dotenv.load(fileName: ".env"); //ここを追加
  runApp(const MyApp());
}

//ヘルプボタンイベント
void navigate(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (context) => const HelpPage()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyHomePage(title: "Summary_PDF");
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _filePath;
  bool _isLoading = false;
  double _fontSizeRate = 1.0;

  List<TopicContent> _topicContents = [];

// テキスト抽出を別スレッドで実行する
  Future<List<String>> _extractTextInOtherThread(Uint8List fileBytes) async {
    return await compute(_extractText, fileBytes);
  }

  // 抽出されたテキストの文字列配列を返す
  static List<String> _extractText(Uint8List bytes) {
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final List<String> texts = [];
    final endPage = document.pages.count;
    const _endPage = 10; // 最大10ページまで抽出する設定
    for (int i = 0; i < _endPage && i < endPage; i++) {
      final text = PdfTextExtractor(document)
          .extractText(startPageIndex: i, endPageIndex: i);
      texts.add(text);
    }
    document.dispose();
    return texts;
  }

  //テキストを要約した文字列を返す
  Future<String> chatGptRequest(String text, String prompt) async {
    String? apiKey = dotenv.env['API_KEY'];
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: utf8.encode(jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant.'},
          {'role': 'user', 'content': '$prompt:$text'}
        ],
        'max_tokens': 150,
      })),
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return responseData['choices'][0]['message']['content'].trim();
    } else {
      return 'chatGPT API実行に失敗しました。';
    }
  }

  //PDFアップロードボタンイベント
  Future<void> handleClickUpload() async {
    setState(() {
      _isLoading = true;
    });
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        Uint8List fileBytes;
        String fileName;

        if (kIsWeb) {
          // Web環境での処理
          fileBytes = result.files.single.bytes!;
          fileName = result.files.single.name;
        } else {
          // モバイル/デスクトップでの処理
          File file = File(result.files.single.path!);
          fileBytes = file.readAsBytesSync();
          fileName = file.path;
        }

        // テキスト抽出
        final pdfTexts = await _extractTextInOtherThread(fileBytes);
        List<TopicContent> topicContents = [];

        for (String text in pdfTexts) {
          final title = await chatGptRequest(text, contentTitlePrompt);
          final summary = await chatGptRequest(text, summaryPrompt);
          final type = await chatGptRequest(text, contentTypePrompt);
          final topic = TopicContent(title, type, summary);
          topicContents.add(topic);
        }

        setState(() {
          _topicContents = topicContents;
          _filePath = fileName;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log("エラー: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  //詳細画面に遷移
  void navigateDetail(BuildContext context, String title, String summary) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => DetailPage(
              title: title,
              summary: summary,
              fontSizeRate: _fontSizeRate,
              onFontSizeChanged: (newRate) {
                setState(() {
                  _fontSizeRate = newRate;
                });
              },
            )));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade100),
        useMaterial3: true,
      ),
      home: DefaultTabController(
        length: 5,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: handleClickUpload,
                  child: const Row(
                    children: [Icon(Icons.upload), Text("PDF選択")],
                  ),
                ),
                const HelpButton()
              ],
            ),
            bottom: const TabBar(
                tabAlignment: TabAlignment.start,
                labelPadding: EdgeInsets.symmetric(horizontal: 5),
                unselectedLabelColor: Colors.white54,
                labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700),
                indicatorColor: Colors.transparent,
                isScrollable: true,
                tabs: [
                  CustomAppBar(label: "イベント", color: Colors.orange),
                  CustomAppBar(label: "生活", color: Colors.green),
                  CustomAppBar(label: "市政", color: Colors.blue),
                  CustomAppBar(label: "交通", color: Colors.red),
                  CustomAppBar(label: "文化", color: Colors.purple),
                ]),
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? createProgressIndicator()
                    : _filePath == null
                        ? Center(
                            child: OutlinedButton(
                              onPressed: handleClickUpload,
                              style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.teal, width: 5)),
                              child: const Text(
                                'PDFを要約',
                                style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.teal),
                              ),
                            ),
                          )
                        : TabBarView(
                            children: [
                              FilteredTopics(
                                topicContents: _topicContents,
                                topicType: "イベント",
                                navigateDetail: navigateDetail,
                                fontSizeRate: _fontSizeRate,
                              ),
                              FilteredTopics(
                                topicContents: _topicContents,
                                topicType: "生活",
                                navigateDetail: navigateDetail,
                                fontSizeRate: _fontSizeRate,
                              ),
                              FilteredTopics(
                                topicContents: _topicContents,
                                topicType: "市政",
                                navigateDetail: navigateDetail,
                                fontSizeRate: _fontSizeRate,
                              ),
                              FilteredTopics(
                                topicContents: _topicContents,
                                topicType: "交通",
                                navigateDetail: navigateDetail,
                                fontSizeRate: _fontSizeRate,
                              ),
                              FilteredTopics(
                                topicContents: _topicContents,
                                topicType: "文化",
                                navigateDetail: navigateDetail,
                                fontSizeRate: _fontSizeRate,
                              ),
                            ],
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "文字サイズの変更",
                      style: TextStyle(fontSize: 20),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "A",
                          style: TextStyle(fontSize: 15),
                        ),
                        Slider(
                          value: _fontSizeRate,
                          min: 0.5,
                          max: 2.0,
                          onChanged: (newValue) {
                            setState(() {
                              _fontSizeRate = newValue;
                            });
                          },
                        ),
                        const Text(
                          "A",
                          style: TextStyle(fontSize: 30),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//ヘルプボタン
class HelpButton extends StatelessWidget {
  const HelpButton({super.key});

  //ヘルプボタンイベント
  void handleClickHelp(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const HelpPage()));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => handleClickHelp(context),
      child: const Row(
        children: [Icon(Icons.question_mark), Text("アプリの使い方")],
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: Tab(
        child: Text(label),
      ),
    );
  }
}

//表示確認用
class FilteredTopics extends StatelessWidget {
  final List<TopicContent> topicContents;
  final String topicType;
  final double fontSizeRate;
  final void Function(BuildContext, String, String) navigateDetail;

  const FilteredTopics(
      {super.key,
      required this.topicContents,
      required this.topicType,
      required this.navigateDetail,
      required this.fontSizeRate});

  @override
  Widget build(BuildContext context) {
    return Column(
        children: topicContents
            .where((topic) => topic.type == topicType)
            .toList()
            .map((topic) => GestureDetector(
                onTap: () =>
                    navigateDetail(context, topic.title, topic.summary),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text(
                          topic.title,
                          style: TextStyle(
                              fontSize: 22 * fontSizeRate,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                )))
            .toList());
  }
}

class CustomTab extends StatelessWidget {
  const CustomTab({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(10))),
      child: Tab(
        child: Text(label),
      ),
    );
  }
}

// 詳細ページの実装
class DetailPage extends StatelessWidget {
  final String title;
  final String summary;
  final double fontSizeRate;
  final ValueChanged<double> onFontSizeChanged;

  const DetailPage(
      {super.key,
      required this.title,
      required this.summary,
      required this.fontSizeRate,
      required this.onFontSizeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(title, style: TextStyle(fontSize: 25 * fontSizeRate)),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                summary,
                style: TextStyle(fontSize: 16 * fontSizeRate),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "文字サイズの変更",
                  style: TextStyle(fontSize: 20),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "小",
                      style: TextStyle(fontSize: 20),
                    ),
                    Slider(
                      value: fontSizeRate,
                      min: 0.5,
                      max: 2.0,
                      onChanged: onFontSizeChanged,
                    ),
                    const Text(
                      "大",
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
