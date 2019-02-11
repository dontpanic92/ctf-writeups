---
layout: post
title: CSHOP
categories: writeups
tags: reversing
ctfsite: reversing.kr
challenge_url: http://reversing.kr/challenge.php
---

下载文件后打开，发现只是一个空白窗体：

![screenshot]({% asset screenshot.png %})

{% include writeup_begin.html %}

用 Cutter 加载后，发现只有一句：

```asm
0x0042b48e      jmp  dword [sym.imp.mscoree.dll__CorExeMain]
```

这说明这是一个 .Net 程序。使用 dotPeek 打开，看一下窗体类，类的成员有点奇怪：

![members]({% asset members.png %})

换用 dnSpy 打开，原来是因为变量名中存在不可见字符。在反编译出的函数中，`Click` 最为可疑，似乎是设置了 flag：

![dnspy]({% asset dnspy.png %})

向下找到 `InitializeComponent`，看一下这个 Click 是在哪用到的：

![initialize_component]({% asset initializecomponent.png %})

原来是按钮的 Click 事件。这个按钮的 Size 被设置为了 0，不过还设置了 TabIndex 为 0。因此我们打开程序后，按一下 Tab，再按一下回车，就可以显示出 Flag 了。

{% include writeup_end.html %}
