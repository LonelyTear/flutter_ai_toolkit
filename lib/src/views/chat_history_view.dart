// Copyright 2024 The Flutter Authors. All rights reserved. // 版权声明
// Use of this source code is governed by a BSD-style license that can be // 使用此源代码受 BSD 许可证管辖
// found in the LICENSE file. // 可在 LICENSE 文件中找到

import 'package:flutter/material.dart'; // 导入 Flutter Material 设计库
import 'package:flutter/widgets.dart'; // 导入 Flutter 基础组件库
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart'; // 导入 Flutter AI Toolkit 主包
import 'package:flutter_ai_toolkit/src/views/chat_input/chat_suggestion_view.dart'; // 导入聊天建议视图组件

import '../chat_view_model/chat_view_model_client.dart'; // 导入聊天视图模型客户端
import 'chat_message_view/llm_message_view.dart'; // 导入 LLM 消息视图组件
import 'chat_message_view/user_message_view.dart'; // 导入用户消息视图组件

/// A widget that displays a history of chat messages. // 显示聊天消息历史记录的组件
///
/// This widget renders a scrollable list of chat messages, supporting // 此组件渲染可滚动的聊天消息列表，支持
/// selection and editing of messages. It displays messages in reverse // 消息选择和编辑。它以反向
/// chronological order (newest at the bottom). // 时间顺序显示消息（最新的在底部）
@immutable // 标记为不可变类
class ChatHistoryView extends StatefulWidget { // 聊天历史视图组件，继承自有状态组件
  /// Creates a [ChatHistoryView]. // 创建聊天历史视图
  ///
  /// If [onEditMessage] is provided, it will be called when a user initiates an // 如果提供了 onEditMessage，当用户发起
  /// edit action on an editable message (typically the last user message in the // 对可编辑消息的编辑操作时会被调用（通常是历史记录中的
  /// history). // 最后一条用户消息）
  const ChatHistoryView({ // 构造函数
    this.onEditMessage, // 可选的编辑消息回调函数
    required this.onSelectSuggestion, // 必需的建议选择回调函数
    super.key, // 父类 key 参数
  });

  /// Optional callback function for editing a message. // 可选的编辑消息回调函数
  ///
  /// If provided, this function will be called when a user initiates an edit // 如果提供，当用户发起编辑操作时
  /// action on an editable message (typically the last user message in the // 会被调用（通常是历史记录中的
  /// history). The function receives the [ChatMessage] to be edited as its // 最后一条用户消息）。函数接收要编辑的 [ChatMessage] 作为
  /// parameter. // 参数
  final void Function(ChatMessage message)? onEditMessage; // 编辑消息的回调函数

  /// The callback function to call when a suggestion is selected. // 当选择建议时调用的回调函数
  final void Function(String suggestion) onSelectSuggestion; // 选择建议的回调函数

  @override // 重写父类方法
  State<ChatHistoryView> createState() => _ChatHistoryViewState(); // 创建状态对象
}

class _ChatHistoryViewState extends State<ChatHistoryView> { // 聊天历史视图状态类
  final ScrollController _scrollController = ScrollController(); //💡 新增滚动控制器

  @override //💡 重写销毁方法
  void dispose() { //💡 销毁控制器
    _scrollController.dispose(); //💡 释放内存
    super.dispose(); //💡 调用父类销毁
  } //💡

  @override // 重写父类方法
  Widget build(BuildContext context) => ChatViewModelClient( // 构建方法，返回聊天视图模型客户端
    builder: (context, viewModel, child) { // 构建器函数，接收上下文、视图模型和子组件
      //💡 监测数据变化并自动滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) { //💡 布局完成后执行
        if (_scrollController.hasClients) { //💡 检查滚动位置是否挂载
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent); //💡 滚动到最大偏移量
        } //💡
      }); //💡

      final chatStyle = LlmChatViewStyle.resolve(viewModel.style); // 解析聊天视图样式
      final padding = // 获取内边距
          chatStyle.padding as EdgeInsets? ?? // 如果样式中有内边距则使用，否则
          const EdgeInsets.only(top: 16, left: 16, right: 16); // 使用默认内边距
      final messageSpacing = chatStyle.messageSpacing ?? 6.0; // 获取消息间距，默认为 6.0

      final showWelcomeMessage = viewModel.welcomeMessage != null; // 判断是否显示欢迎消息
      final showSuggestions = // 判断是否显示建议
          viewModel.suggestions.isNotEmpty && // 当建议列表不为空且
          viewModel.provider.history.isEmpty; // 聊天历史为空时显示
      final history = [ // 构建历史消息列表
        if (showWelcomeMessage) // 如果需要显示欢迎消息
          ChatMessage( // 创建聊天消息对象
            origin: MessageOrigin.llm, // 消息来源为 LLM
            text: viewModel.welcomeMessage, // 消息文本为欢迎消息
            attachments: [], // 附件为空
          ),
        ...viewModel.provider.history, // 展开提供者的历史消息
      ];

      return Padding( // 返回内边距组件
        padding: padding, // 应用内边距
        child: ListView.builder( // 子组件为列表视图构建器
          controller: _scrollController, //💡 绑定控制器
          reverse: false, //💡 修改为非反向，符合正向逻辑顺序 , 原代码是 true , 理解太反人类
          itemCount: history.length + (showSuggestions ? 1 : 0), // 列表项数量，包含建议视图
          itemBuilder: (context, index) { //📌 列表项构建器, 之所以把建议分开写是因为它的渲染格式和单条消息不一样, 而上拉下拉加载更多也不一样, 所以也需要写在本处
            if (showSuggestions && index == history.length) { //💡 当索引到达最后一条时，直接渲染建议
              return ChatSuggestionsView( // 返回建议视图
                suggestions: viewModel.suggestions, // 传入建议列表
                onSelectSuggestion: widget.onSelectSuggestion, // 传入选择建议的回调
              );
            }
            final message = history[index]; //💡 直接通过索引获取消息，无需反向计算
            final isLastUserMessage = // 判断是否为最后一条用户消息
                message.origin.isUser && index == history.length - 1; //💡 简化逻辑，最后一条即历史数组末尾
            final canEdit = isLastUserMessage && widget.onEditMessage != null; // 判断是否可编辑
            final isUser = message.origin.isUser; // 判断是否为用户消息

            return Padding( // 返回内边距组件
              padding: EdgeInsets.only(top: messageSpacing), // 应用消息间距
              child: // 子组件
                  isUser // 如果是用户消息
                      ? UserMessageView( // 显示用户消息视图
                        message, // 传入消息对象
                        onEdit: // 编辑回调
                            canEdit // 如果可编辑
                                ? () => widget.onEditMessage?.call(message) // 则调用编辑回调
                                : null, // 否则为 null
                      )
                      : LlmMessageView( // 否则显示 LLM 消息视图
                        message, // 传入消息对象
                        isWelcomeMessage: index == 0 && showWelcomeMessage, //💡 明确判断第一条是否为欢迎消息
                      ),
            );
          },
        ),
      );
    },
  );
}