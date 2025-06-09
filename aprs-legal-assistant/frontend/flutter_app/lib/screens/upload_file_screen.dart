import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';
import 'dart:html' as html;

class UploadFileScreen extends StatelessWidget {
  const UploadFileScreen({super.key});

  Future<void> _uploadDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false, withData: true);
    if (result == null) return;
    final file = result.files.first;
    final request = http.MultipartRequest('POST', Uri.parse('http://localhost:8000/upload_documents'));
    request.files.add(http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name));
    final streamed = await request.send();
    final bytes = await streamed.stream.toBytes();
    if (streamed.statusCode == 200) {
      Navigator.pushReplacementNamed(context, '/upload_successful');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(flex: 2),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: SvgPicture.string(
                    uploadFileIllistration,
                    fit: BoxFit.scaleDown,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              ErrorInfo(
                title: "File Upload!",
                description:
                    "Select a file from your device to upload. Make sure it complies with the upload guidelines.",
                btnText: "Select File",
                press: () => _uploadDocument(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorInfo extends StatelessWidget {
  const ErrorInfo({
    super.key,
    required this.title,
    required this.description,
    this.button,
    this.btnText,
    required this.press,
  });

  final String title;
  final String description;
  final Widget? button;
  final String? btnText;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall!
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16 * 2.5),
            button ??
                ElevatedButton(
                  onPressed: press,
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)))),
                  child: Text(btnText ?? "Retry".toUpperCase()),
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

const uploadFileIllistration =
    '''<svg width="882" height="871" viewBox="0 0 882 871" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M871.21 496C874.072 496 876.816 497.137 878.84 499.16C880.863 501.184 882 503.928 882 506.79V858.21C882 861.072 880.863 863.816 878.84 865.84C876.816 867.863 874.072 869 871.21 869H519.79C516.928 869 514.184 867.863 512.16 865.84C510.137 863.816 509 861.072 509 858.21C509 762.146 547.161 670.016 615.089 602.089C683.016 534.161 775.146 496 871.21 496Z" fill="#BCBCBC"/>
<path d="M251.59 611.73V385.08C251.595 383.209 252.341 381.417 253.664 380.094C254.986 378.771 256.779 378.025 258.65 378.02H306.27" stroke="#0E0E0E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M512.89 690.62V730.27C512.885 732.141 512.139 733.934 510.816 735.256C509.493 736.579 507.701 737.325 505.83 737.33H413.57" stroke="#0E0E0E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M514.57 335.26L581.01 401.69H514.57V335.26Z" fill="#BCBCBC"/>
<path d="M306.26 646V333.06C306.262 332.602 306.445 332.164 306.769 331.84C307.093 331.516 307.532 331.333 307.99 331.33H501.13" stroke="#0E0E0E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M567.57 397.76V688.45C567.57 689.026 567.341 689.577 566.934 689.984C566.527 690.391 565.975 690.62 565.4 690.62H385.4" stroke="#0E0E0E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M501.13 331.33L567.57 397.76H501.13V331.33Z" stroke="#0E0E0E" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M444.43 589.95C474.844 589.95 499.5 565.294 499.5 534.88C499.5 504.466 474.844 479.81 444.43 479.81C414.016 479.81 389.36 504.466 389.36 534.88C389.36 565.294 414.016 589.95 444.43 589.95Z" fill="#BCBCBC"/>''';
