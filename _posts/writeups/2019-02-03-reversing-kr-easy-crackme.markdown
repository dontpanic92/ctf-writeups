---
layout: post
title: Easy CrackMe
categories: writeups
tags: reversing
ctfsite: reversing.kr
challenge_url: http://reversing.kr/challenge.php
---

双击点开`Easy CrackMe.exe`，将弹出一个对话框，要求输入密码。点击按钮后将对密码进行验证。

![screenshot]({% asset screenshot.png %})

{% include writeup_begin.html %}

首先用 Cutter 打开`Easy CrackMe.exe`，看看 Strings 里面有没有什么特别的：

![strings]({% asset strings.png %})

`AGR3versing`似乎有点奇怪。输进去看看，不对。除此之外，就是`Wrong Password`和`Congratulations`最吸引我们了。看一下`Congratulations`的交叉引用，跳到了：

{% highlight nasm linenos %}
|      ||   0x00401114      push 0x40 ; '@' ; 64
|      ||   0x00401116      push str.EasyCrackMe ; 0x406058 ; "EasyCrackMe"
|      ||   0x0040111b      push str.Congratulation ; 0x406044 ; "Congratulation !!"
|      ||   0x00401120      push edi
|      ||   0x00401121      call dword [sym.imp.USER32.dll_MessageBoxA] ; 0x4050a0 ; "NU"
|      ||   0x00401127      push 0
|      ||   0x00401129      push edi
|      ||   0x0040112a      call dword [sym.imp.USER32.dll_EndDialog] ; 0x4050a4 ; "BU"
|      ||   0x00401130      pop  edi
|      ||   0x00401131      add  esp, 0x64 ; 'd'
|      ||   0x00401134      ret
|      ``-> 0x00401135      push 0x10 ; 16
|           0x00401137      push str.EasyCrackMe ; 0x406058 ; "EasyCrackMe"
|           0x0040113c      push str.Incorrect_Password ; 0x406030 ; "Incorrect Password"
|           0x00401141      push edi
|           0x00401142      call dword [sym.imp.USER32.dll_MessageBoxA] ; 0x4050a0 ; "NU"
|           0x00401148      pop  edi
|           0x00401149      add  esp, 0x64 ; 'd'
\           0x0040114c      ret
{% endhighlight %}

看起来这就是最终弹出检查结果的地方了。往上翻一下，在同一个函数里面，就是检查的逻辑：

{% highlight nasm linenos %}
/ (fcn) sub.USER32.dll_GetDlgItemTextA_401080 205
|   long sub.USER32.dll_GetDlgItemTextA_401080 (HWND hDlg, int nIDDlgItem, LPSTR lpString, int nMaxCount);
|           ; var unsigned int local_4h @ esp+0x4
|           ; var unsigned int local_5h @ esp+0x5
|           ; var int local_8h @ esp+0x8
|           ; var int local_ah @ esp+0xa
|           ; var int local_10h @ esp+0x10
|           ; arg int arg_70h @ esp+0x70
|           0x00401080      sub  esp, 0x64 ; 'd'
|           0x00401083      push edi
|           0x00401084      mov  ecx, 0x18 ; 24
|           0x00401089      xor  eax, eax
|           0x0040108b      lea  edi, [local_5h] ; 5
|           0x0040108f      mov  byte [local_4h], 0
|           0x00401094      push 0x64 ; 'd' ; 100
|           0x00401096      rep  stosd dword es:[edi], eax
|           0x00401098      stosw word es:[edi], ax
|           0x0040109a      stosb byte es:[edi], al
|           0x0040109b      mov  edi, dword [arg_70h] ; [0x70:4]=-1 ; 'p' ; 112
|           0x0040109f      lea  eax, [local_8h] ; 8 ;; !local_4h
|           0x004010a3      push eax
|           0x004010a4      push 0x3e8 ; 1000
|           0x004010a9      push edi
|           0x004010aa      call dword [sym.imp.USER32.dll_GetDlgItemTextA] ; 0x40509c ; "\U"
|           0x004010b0      cmp  byte [local_5h], 0x61 ; 'a' ; [0x5:1]=255 ; 97
|       ,=< 0x004010b5      jne  0x401135
|       |   0x004010b7      push 2 ; 2
|       |   0x004010b9      lea  ecx, 
|           0x004010b9      lea  ecx, [local_ah] ; 0xa ; 10 ;; local_6h
|           0x004010bd      push 0x406078 ; 'x`@' ; "5y"
|           0x004010c2      push ecx
|           0x004010c3      call fcn.00401150
|           0x004010c8      add  esp, 0xc
|           0x004010cb      test eax, eax
|       ,=< 0x004010cd      jne  0x401135
|       |   0x004010cf      push ebx
|       |   0x004010d0      push esi
|       |   0x004010d1      mov  esi, 0x40606c ; 'l`@' ; "R3versing"
|       |   0x004010d6      lea  eax, [local_10h] ; 0x10 ; 16 ;; local_8h
|      .--> 0x004010da      mov  dl, byte [eax]
|      :|   0x004010dc      mov  bl, byte [esi]
|      :|   0x004010de      mov  cl, dl
|      :|   0x004010e0      cmp  dl, bl
|     ,===< 0x004010e2      jne  0x401102
|     |:|   0x004010e4      test cl, cl
|    ,====< 0x004010e6      je   0x4010fe
|    ||:|   0x004010e8      mov  dl, byte [eax + 1] ; [0x1:1]=255 ; 1
|    ||:|   0x004010eb      mov  bl, byte [esi + 1] ; [0x1:1]=255 ; 1
|    ||:|   0x004010ee      mov  cl, dl
|    ||:|   0x004010f0      cmp  dl, bl
|   ,=====< 0x004010f2      jne  0x401102
|   |||:|   0x004010f4      add  eax, 2
|   |||:|   0x004010f7      add  esi, 2
|   |||:|   0x004010fa      test cl, cl
|   |||`==< 0x004010fc      jne  0x4010da
|   |`----> 0x004010fe      xor  eax, eax
|   | |,==< 0x00401100      jmp  0x401107
|   `-`---> 0x00401102      sbb  eax, eax
|      ||   0x00401104      sbb  eax, 0xffffffffffffffff
|      `--> 0x00401107      pop  esi
|       |   0x00401108      pop  ebx
|       |   0x00401109      test eax, eax
|      ,==< 0x0040110b      jne  0x401135
|      ||   0x0040110d      cmp  byte [local_4h], 0x45 ; 'E' ; [0x4:1]=255 ; 69
|     ,===< 0x00401112      jne  0x401135
|     |||   0x00401114      push 0x40 ; '@' ; 64
|     |||   0x00401116      push str.EasyCrackMe ; 0x406058 ; "EasyCrackMe"
|     |||   0x0040111b      push str.Congratulation ; 0x406044 ; "Congratulation !!"
{% endhighlight %}

由于这个函数的局部变量由esp索引，而R2没有捕捉到esp的变化，导致函数中的变量名的使用会有些误导，在分析时需要注意。举例来说，上面的代码片段14行有一处push，导致第20行的local_8h（esp+8）实际应为local_4h。我在有问题的语句后做了注释。

首先来看第24行，`GetDlgItemText`是一个Win32 API，其中第三个参数是字符串的地址。第21行压入的eax即为第三个参数，它指向的是`local_4h`，因此`local_4h`就是字符串的第零个字符的地址。

随后，第25行判断了一下第一个字符的内容是否为`a`；第32行将`5y`和第三个字符地址的地址传入了`fcn.00401150`。去看一下这个函数：

{% highlight nasm %}
/ (fcn) fcn.00401150 56
|   fcn.00401150 (int arg_8h, unsigned int arg_ch, int arg_10h);
|           ; arg int arg_8h @ ebp+0x8
|           ; arg unsigned int arg_ch @ ebp+0xc
|           ; arg int arg_10h @ ebp+0x10
|           0x00401150      push ebp
|           0x00401151      mov  ebp, esp
|           0x00401153      push edi
|           0x00401154      push esi
|           0x00401155      push ebx
|           0x00401156      mov  ecx, dword [arg_10h] ; [0x10:4]=-1 ; 16
|       ,=< 0x00401159      jecxz 0x401181
|       |   0x0040115b      mov  ebx, ecx
|       |   0x0040115d      mov  edi, dword [arg_8h] ; [0x8:4]=-1 ; 8
|       |   0x00401160      mov  esi, edi
|       |   0x00401162      xor  eax, eax
|       |   0x00401164      repne scasb al, byte es:[edi]
|       |   0x00401166      neg  ecx
|       |   0x00401168      add  ecx, ebx
|       |   0x0040116a      mov  edi, esi
|       |   0x0040116c      mov  esi, dword [arg_ch] ; [0xc:4]=-1 ; 12
|       |   0x0040116f      repe cmpsb byte [esi], byte ptr es:[edi]
|       |   0x00401171      mov  al, byte [esi - 1]
|       |   0x00401174      xor  ecx, ecx
|       |   0x00401176      cmp  al, byte [edi - 1]
|      ,==< 0x00401179      ja   0x40117f
|     ,===< 0x0040117b      je   0x401181
|     |||   0x0040117d      dec  ecx
|     |||   0x0040117e      dec  ecx
|     |`--> 0x0040117f      not  ecx
|     `-`-> 0x00401181      mov  eax, ecx
|           0x00401183      pop  ebx
|           0x00401184      pop  esi
|           0x00401185      pop  edi
|           0x00401186      leave
\           0x00401187      ret
{% endhighlight %}

看起来只是在做字符串比较，所以第三四个字符应该是`5y`。再继续看，从第38行开始，字符串`R3versing`出现了，下面的代码又是在不断地比较每一个字符是否与`R3versing`相同。最后64行比较了第一个字符是否为`E`，至此密码已经找到了：<flag>Ea5yR3versing</flag>。

{% include writeup_end.html %}
