---
layout: post
title: Easy UnpackMe
categories: writeups
tags: reversing
ctfsite: reversing.kr
challenge_url: http://reversing.kr/challenge.php
---

下载下来的文件是一个压缩包，里面除了 `Easy UnpackMe.exe` 之外还有一个 `README`，其中说明了 `Easy UnpackMe.exe` 的 OEP 即为 Flag。

{% include writeup_begin.html %}

使用 OllyDBG 打开 `Easy UnpackMe.exe`，经过 OD 的分析之后，它会自动停在 OEP 处：

![OllyDBG]({% asset ollydbg.png %})

所以最后的 Flag 就是<flag>00401150</flag>。

![wtf]({{ '/assets/images/wtf.png' | relative_url }})

{% include writeup_end.html %}
