import 'package:flutter/material.dart';
import '../services/text_enhancer_service.dart';

class HomeBody extends StatefulWidget {
  final Function(String) onSubmit;
  final String? recognizedText;

  const HomeBody({
    super.key,
    required this.onSubmit,
    this.recognizedText,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  final TextEditingController _textController =
      TextEditingController();
  bool _isEnhancing = false;

  @override
  void didUpdateWidget(HomeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the text field when recognized text changes
    if (widget.recognizedText != null &&
        widget.recognizedText!.isNotEmpty &&
        widget.recognizedText != oldWidget.recognizedText) {
      _textController.text = widget.recognizedText!;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// Enhances the text using the API
  Future<void> _enhanceText() async {
    String text = _textController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter some text to enhance',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isEnhancing = true;
    });

    try {
      // Call the API to enhance the text
      String enhancedText =
          await TextEnhancerService.enhanceText(text);

      // Update the text field with the enhanced text
      setState(() {
        _textController.text = enhancedText;
        _isEnhancing = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Text enhanced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isEnhancing = false;
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(30),
      child: Column(
        children: [
          Stack(
            children: [
              TextField(
                controller: _textController,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                  hintText:
                      "Enter Text TO Start Enhancement",
                  contentPadding: EdgeInsets.only(
                    left: 12,
                    right: 60, // Make space for the button
                    top: 12,
                    bottom:
                        50, // Make space for the button at bottom
                  ),
                ),
                onChanged: (text) {
                  print("text Changed $text");
                },
                onSubmitted: (text) {
                  print("Text Submitted $text");
                },
              ),
              // Enhance button positioned at bottom right
              Positioned(
                bottom: 8,
                right: 8,
                child: _isEnhancing
                    ? Container(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<
                                  Color
                                >(Colors.deepOrangeAccent),
                          ),
                        ),
                      )
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _enhanceText,
                          borderRadius:
                              BorderRadius.circular(8),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  Colors.deepOrangeAccent,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ButtonStyle(),
              onPressed: () {
                String text = _textController.text;
                if (text.isNotEmpty) {
                  widget.onSubmit(text);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Text submitted successfully!',
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  _textController.clear();
                } else {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please enter some text first',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text(
                "submitt",
                style: TextStyle(
                  color: Colors.deepOrangeAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
