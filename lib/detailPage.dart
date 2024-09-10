import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String title;
  final String summary;
  final double fontSizeRate;

  const DetailPage(
      {super.key,
      required this.title,
      required this.summary,
      required this.fontSizeRate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 30 * fontSizeRate,
              ),
              Text(summary,
                  style: TextStyle(
                      fontSize: 24 * fontSizeRate, fontWeight: FontWeight.w500))
            ],
          ),
        ));
  }
}
