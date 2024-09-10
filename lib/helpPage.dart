import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        margin: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 30),
                child: const Text(
                  "【アプリの使い方】",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ステップ1",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      "市の広報PDFをダウンロード",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Image.asset(
                      "images/manual1.png",
                      height: 500,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ステップ2",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      "「PDF を要約」ボタンを押し、要約する PDF を選択する",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Image.asset(
                      "images/manual4.png",
                      height: 500,
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.only(bottom: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ステップ3",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      "気になるトピックを押す",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Image.asset(
                      "images/manual2.png",
                      height: 500,
                    ),
                  ],
                ),
              ),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ステップ4",
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const Text(
                      "文字サイズを変更",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Image.asset(
                      "images/manual3.png",
                      height: 500,
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
