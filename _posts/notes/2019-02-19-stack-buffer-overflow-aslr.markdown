---
layout: post
title: 栈缓冲区溢出之二 ASLR
categories: notes
tags: binary
---

[上文]({% url_by_slug stack-buffer-overflow-101 %})介绍了栈缓冲区溢出的基本情况与利用方法。为了降低栈缓冲区溢出漏洞发生后的风险，很多技术应运而生，ASLR（Address Space Layout Randomization，地址空间布局随机化）就是其中之一。

上文中我们提到，栈缓冲区溢出之后，如果没有任何防护措施，攻击者可以非常容易地改变程序执行逻辑，甚至可以执行注入的代码。
