// Copyright 2024 The Flutter Authors. All rights reserved. // 版权声明
// Use of this source code is governed by a BSD-style license that can be // 使用此源代码受 BSD 许可证管辖
// found in the LICENSE file. // 可在 LICENSE 文件中找到

import 'dart:async'; // 导入异步库

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
    this.loadPrevData, //💡 可选的上拉加载更多回调函数
    this.loadNextData, //💡 可选的下拉加载更多回调函数
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

  ///💡 上拉加载更多回调函数（加载更早的历史消息）
  final Future<void> Function()? loadPrevData; // 上拉加载更多

  ///💡 下拉加载更多回调函数（加载更新的消息）
  final Future<void> Function()? loadNextData; // 下拉加载更多

  @override // 重写父类方法
  State<ChatHistoryView> createState() => _ChatHistoryViewState(); // 创建状态对象
}

class _ChatHistoryViewState extends State<ChatHistoryView> { // 聊天历史视图状态类
  final ScrollController _scrollController = ScrollController(); //💡 新增滚动控制器
  bool _isLoadingPrev = false; //💡 上拉加载状态标志
  bool _isLoadingNext = false; //💡 下拉加载状态标志
  double _lastScrollPosition = 0; //💡 记录上一次滚动位置，用于判断滚动方向
  int _lastHistoryLength = 0; //💡 记录上一次历史消息数量，用于检测新消息

  //💡 新增：标记是否处于“自动追尾”模式。当用户手动滑离底部时关闭，滑到底部时开启
  bool _isAutoFollow = true; //💡

  @override //💡 重写初始化方法
  void initState() { //💡 初始化状态
    super.initState(); //💡 调用父类初始化
    _scrollController.addListener(_scrollListener); //💡 添加滚动监听器
  }

  @override //💡 重写销毁方法
  void dispose() { //💡 销毁控制器
    _scrollController.removeListener(_scrollListener); //💡 移除滚动监听器
    _scrollController.dispose(); //💡 释放内存
    super.dispose(); //💡 调用父类销毁
  }

  ///💡 滚动监听方法，用于检测上拉和下拉
  void _scrollListener() { //💡 滚动监听器
    if (!_scrollController.hasClients) return; //💡 如果未挂载则返回

    final maxScroll = _scrollController.position.maxScrollExtent; //💡 最大滚动位置
    final minScroll = _scrollController.position.minScrollExtent; //💡 最小滚动位置
    final currentScroll = _scrollController.position.pixels; //💡 当前滚动位置

    //💡 逻辑优化：判断是否处于底部追尾区（距离底部100px以内）
    if (currentScroll >= maxScroll - 100) { //💡
      _isAutoFollow = true; //💡 触底，开启自动跟随
    } else { //💡
      _isAutoFollow = false; //💡 用户离开底部，关闭自动跟随，允许回溯阅读
    } //💡

    //💡 判断滚动方向：向上滚动（手指向下滑）是 currentScroll < _lastScrollPosition
    final isScrollingUp = currentScroll < _lastScrollPosition; //💡 向上滚动
    _lastScrollPosition = currentScroll; //💡 更新上一次滚动位置

    //💡 检测上拉加载更多（向上滚动到顶部附近）
    if (isScrollingUp && //💡 向上滚动
        currentScroll <= minScroll + 100 && //💡 距离顶部100像素内
        !_isLoadingPrev && //💡 未在加载中
        widget.loadPrevData != null) { //💡 有加载回调
      _loadPrevData(); //💡 执行上拉加载
    }

    //💡 检测下拉加载更多（向下滚动到底部附近）
    if (!isScrollingUp && //💡 向下滚动
        currentScroll >= maxScroll - 100 && //💡 距离底部100像素内
        !_isLoadingNext && //💡 未在加载中
        widget.loadNextData != null) { //💡 有加载回调
      _loadNextData(); //💡 执行下拉加载
    }
  }

  ///💡 执行上拉加载更多
  Future<void> _loadPrevData() async { //💡 上拉加载方法
    if (_isLoadingPrev) return; //💡 防止重复加载
    setState(() => _isLoadingPrev = true); //💡 设置加载状态
    try {
      await widget.loadPrevData!(); //💡 调用外部传入的加载方法
    } finally {
      setState(() => _isLoadingPrev = false); //💡 重置加载状态
    }
  }

  ///💡 执行下拉加载更多
  Future<void> _loadNextData() async { //💡 下拉加载方法
    if (_isLoadingNext) return; //💡 防止重复加载
    setState(() => _isLoadingNext = true); //💡 设置加载状态
    try {
      await widget.loadNextData!(); //💡 调用外部传入的加载方法
    } finally {
      setState(() => _isLoadingNext = false); //💡 重置加载状态
    }
  }

  @override // 重写父类方法
  Widget build(BuildContext context) => ChatViewModelClient( // 构建方法，返回聊天视图模型客户端
    builder: (context, viewModel, child) { // 构建器函数，接收上下文、视图模型和子组件
      final currentHistoryLength = viewModel.provider.history.length; //💡 获取当前历史消息数量

      //💡 布局完成后，仅在处于追尾模式时执行滚动
      // WidgetsBinding.instance.addPostFrameCallback((_) { //💡 布局完成后执行
      //   if (_scrollController.hasClients) { //💡 检查滚动位置是否挂载
      //     //💡 如果历史消息数量增加（新消息）且处于自动追尾模式，则滚动到底部
      //     if (currentHistoryLength > _lastHistoryLength && _isAutoFollow) { //💡
      //       _scrollController.jumpTo(_scrollController.position.maxScrollExtent); //💡 滚动到最大偏移量
      //     }
      //     //💡 更新历史消息数量记录
      //     _lastHistoryLength = currentHistoryLength; //💡 保存当前历史消息数量
      //   }
      // });

      //💡 解决ai回答一部分后继续回答时不会继续滚动到最下方的bug
      WidgetsBinding.instance.addPostFrameCallback((_) { //💡
        if (_scrollController.hasClients && _isAutoFollow) { //💡 检查滚动位置是否挂载 并且 处于自动滚动模式
          //💡 使用 animateTo 实现丝滑的自动追尾滚动
          _scrollController.animateTo( //💡
            _scrollController.position.maxScrollExtent, //💡
            duration: const Duration(milliseconds: 100), //💡
            curve: Curves.easeOut, //💡
          ); //💡
        } //💡
      }); //💡

      final chatStyle = LlmChatViewStyle.resolve(viewModel.style); // 解析聊天视图样式
      final padding = chatStyle.padding as EdgeInsets? ?? const EdgeInsets.only(top: 16, left: 16, right: 16);// 获取内边距, 如果样式中有内边距则使用，否则使用默认内边距
      final messageSpacing = chatStyle.messageSpacing ?? 6.0; // 获取消息间距，默认为 6.0

      final showWelcomeMessage = viewModel.welcomeMessage != null; // 判断是否显示欢迎消息
      final showSuggestions = viewModel.suggestions.isNotEmpty && viewModel.provider.history.isEmpty; // 判断是否显示建议 当建议列表不为空且 聊天历史为空时显示 📌所以这个建议目前只用到了初始化时的冷启动上
      final history = [ // 构建历史消息列表
        if (showWelcomeMessage) // 如果需要显示欢迎消息
          ChatMessage(origin: MessageOrigin.llm, text: viewModel.welcomeMessage, attachments: [],), // 创建来源为 LLM 消息对象
        ...viewModel.provider.history, // 展开提供者的历史消息
      ];

      return Padding( // 返回内边距组件
        padding: padding, // 应用内边距
        child: ListView.builder( // 子组件为列表视图构建器
          controller: _scrollController, //💡 绑定控制器
          reverse: false, //💡 修改为非反向，符合正向逻辑顺序 , 原代码是 true , 理解太反人类
          //💡 优化：仅当正在加载时才在 itemCount 中分配位置
          itemCount: history.length +
              (showSuggestions ? 1 : 0) +
              (_isLoadingPrev ? 1 : 0) +
              (_isLoadingNext ? 1 : 0), //💡
          itemBuilder: (context, index) { //📌 列表项构建器, 之所以把建议分开写是因为它的渲染格式和单条消息不一样, 而上拉下拉加载更多也不一样, 所以也需要写在本处

            //💡 处理上拉加载指示器（只在 isLoadingPrev 为 true 时构建）
            if (_isLoadingPrev && index == 0) { //💡
              return const Padding( //💡
                padding: EdgeInsets.all(16), //💡
                child: Center( //💡
                  child: CircularProgressIndicator(), //💡
                      ),
              );
            }

            //💡 调整索引，减去可能存在的上拉加载指示器
            final adjustedIndex = index - (_isLoadingPrev ? 1 : 0); //💡

            //💡 处理建议视图
            if (showSuggestions && adjustedIndex == history.length) { //💡 当索引到达最后一条时，直接渲染建议
              return ChatSuggestionsView( // 返回建议视图
                suggestions: viewModel.suggestions, // 传入建议列表
                onSelectSuggestion: widget.onSelectSuggestion, // 传入选择建议的回调
              );
            }

            //💡 处理下拉加载指示器（仅在触发加载且处于列表末尾时构建）
            if (_isLoadingNext && index == (history.length + (showSuggestions ? 1 : 0) + (_isLoadingPrev ? 1 : 0))) { //💡
              return const Padding( //💡
                padding: EdgeInsets.all(16), //💡
                child: Center( //💡
                  child: CircularProgressIndicator(), //💡
                      ),
              );
            }

            final message = history[adjustedIndex]; //💡 直接通过索引获取消息，无需反向计算
            final isUser = message.origin.isUser; // 判断是否为用户消息
            final isLastUserMessage = isUser && adjustedIndex == history.length - 1; // 判断是否为最后一条用户消息, 简化逻辑，最后一条即历史数组末尾
            final canEdit = isLastUserMessage && widget.onEditMessage != null; // 判断是否可编辑

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
                        isWelcomeMessage: adjustedIndex == 0 && showWelcomeMessage, //💡 明确判断第一条是否为欢迎消息
                      ),
            );
          },
        ),
      );
    },
  );
}