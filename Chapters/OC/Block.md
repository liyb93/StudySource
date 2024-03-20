# Block

block本质上也是一个OC对象，它内部也有个isa指针

block是封装了函数调用以及函数调用环境的OC对象

```c++
struct Block_layout {
    void *isa;
    int flags;
    int reserved;
   // block执行时调用的函数指针，block定义时内部的执行代码都在这个函数中
    void (*invoke)(void *, ...);
    // block的详细描述
    struct Block_descriptor *descriptor;
    /* Imported variables. */
};
struct Block_descriptor {
    unsigned long int reserved;
    unsigned long int size;
    // copy/dispose，辅助拷贝/销毁函数，处理block范围外的变量时使用
    void (*copy)(void *dst, void *src);
    void (*dispose)(void *);
};
```

## Block变量捕获

为了保证block内部能够正常访问外部的变量，block有个变量捕获机制

|     变量类型     |             捕获到block内部              | 访问方式 |
| :--------------: | :--------------------------------------: | :------: |
|  局部变量(auto)  | <input type="checkbox" checked disabled> |  值传递  |
| 局部变量(static) | <input type="checkbox" checked disabled> | 指针传递 |
|     全局变量     |     <input type="checkbox" disabled>     | 直接访问 |

auto变量被捕获时直接传入的变量的值，而static变量被捕获时传入的是变量的地址，由于auto变量出了当前作用域内存就会被销毁，所以需要将auto变量的值捕获；

static变量是一直存在内存中，但出了作用域就访问不了啦，所以只需要捕获static变量的内存地址就可以了；

全局变量是不会被捕获的，因为全局变量在哪里都可以访问，不需要进行捕获。

## __block

`__block`修饰auto变量，在block内使用，block会把修饰的变量包装成对象，所以使用`__block`修饰的变量可以进行修改，这是因为block内使用的指针进行修改

```c++
struct 包装的属性对象 {
    void *isa;
    // 指向自己
    void *forwarding;
    int flag;
    int size;
    // 修饰的变量
    ...
};
```

- block在修改NSMutableArray时需要进行`__blcok`吗?
  - 不需要，因为array使用的是指针修改，不存在无法修改的问题。

## copy修饰

block一旦没有进行copy操作,就不会在堆上,就无法控制block的生命周期

在ARC环境下，编译器会根据情况自动将栈上的block复制到堆上，比如以下情况

- block作为函数返回值时`return ^{ } ;`

- 将block赋值给__strong指针时`Block bolck = ^{ };`

- block作为Cocoa API中方法名含有usingBlock的方法参数时

  ```objective-c
  [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
  }] ;
  ```

- block作为GCD API的方法参数时

  ```objective-c
  dispatch_once(&onceToken, ^{
  });
  ```

所以ARC下使用strong/copy都可以，MRC下编译器不会自动将栈上的block复制到堆上，所以只能使用copy

## 类型

| 类型          | 介绍                                                         |
| ------------- | :----------------------------------------------------------- |
| NSGlobalBlock | 没有访问auto变量的block，存放在数据段。调用copy什么都不做。  |
| NSStackBlock  | 访问auto变量,存放在栈中，注意ARC中测试时会显示为NSMallockBlock,这是因为编译器对block做了处理，关闭ARC即可。会自动销毁，所以需要用copy修饰，把block存到堆中 |
| NSMallocBlock | NSStackBlock调用copy；调用copy引用计数器加1                  |

## 应用程序的内存分配

| 区域              | block类型              | 存放数据类型                     |
| ----------------- | ---------------------- | -------------------------------- |
| 程序区域(.text区) |                        | 存放代码                         |
| 数据区域(.data区) | _NSConcreteGlobalBlock | 全局变量存储的位置               |
| 堆                | _NSConcreteMallocBlock | alloc出的对象，手动释放          |
| 栈                | _NSConcreteStackBlock  | 局部变量存放的位置，系统自动释放 |
