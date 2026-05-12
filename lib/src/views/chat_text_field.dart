// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart' show CupertinoTextField;
import 'package:flutter/material.dart'
    show InputBorder, InputDecoration, TextField, TextInputAction;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../styles/toolkit_colors.dart';
import '../utility.dart';

/// A text field that adapts to the current app style (Material or Cupertino).
///
/// This widget will render either a [CupertinoTextField] or a [TextField]
/// depending on whether the app is using Cupertino or Material design.
@immutable
class ChatTextField extends StatelessWidget {
  /// Creates an adaptive text field.
  ///
  /// Many of the parameters are required to ensure consistent behavior
  /// across both Cupertino and Material designs.
  const ChatTextField({
    required this.minLines,
    required this.maxLines,
    required this.autofocus,
    required this.style,
    required this.textInputAction,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.hintText,
    required this.hintStyle,
    required this.hintPadding,
    super.key,
  });

  /// The minimum number of lines to show.
  final int minLines;

  /// The maximum number of lines to show.
  final int maxLines;

  /// Whether the text field should be focused initially.
  final bool autofocus;

  /// The style to use for the text being edited.
  final TextStyle style;

  /// The type of action button to use for the keyboard.
  final TextInputAction textInputAction;

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Defines the keyboard focus for this widget.
  final FocusNode focusNode;

  /// The text to show when the text field is empty.
  final String hintText;

  /// The style to use for the hint text.
  final TextStyle hintStyle;

  /// The padding to use for the hint text.
  final EdgeInsetsGeometry? hintPadding;

  /// Called when the user submits editable content.
  final void Function(String text) onSubmitted;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.enter):
          () => onSubmitted(controller.text),
    },
    child:
        GestureDetector(
          // 💡 关键：添加 behavior 属性，确保它在命中测试中拦截手势
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) {
            // 💡 如果当前没有焦点，才触发长按回调
            if (!focusNode.hasFocus) { //💡 利用组件内部已有的 focusNode 判断
              print("cccccccccccccc");
            }
          },
          onLongPressEnd: (_) {
            print("ddddddddddddddd");
          },
          // 💡 关键：防止长按时触发点击（从而避免进入录入状态）
          onTap: () {
            print("eeeeeeeeeee33");
            if (!focusNode.hasFocus) {
              focusNode.requestFocus(); // 只有主动点击才获取焦点
            }
          },
          child: isCupertinoApp(context)
              ? CupertinoTextField(
                minLines: minLines,
                maxLines: maxLines,
                controller: controller,
                autofocus: autofocus,
                focusNode: focusNode,
                onSubmitted: onSubmitted,
                style: style,
                placeholder: hintText,
                placeholderStyle: hintStyle,
                padding: hintPadding ?? EdgeInsets.zero,
                decoration: BoxDecoration(
                  border: Border.all(width: 0, color: ToolkitColors.transparent),
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              )
              : TextField(
                minLines: minLines,
                maxLines: maxLines,
                controller: controller,
                autofocus: false,//@back 原本为 autofocus , 如果为 true, 开屏会报错, 回头看
                focusNode: focusNode,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onSubmitted: onSubmitted,
                style: style,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: hintText,
                  hintStyle: hintStyle,
                  contentPadding: hintPadding,
                  isDense: false,
                ),
              ),
        ),
  );
}
