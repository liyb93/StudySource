# Objective-C

## 基础知识

- 一个NSObject对象占用多少内存？
  - 系统分配了16个字节给NSObject对象（通过malloc_size函数获得）
  - 但NSObject对象内部只使用了8个字节的空间（64bit环境下，可以通过class_getInstanceSize函数获得）
- 对象的isa指针指向哪里？
  - instance对象的isa指向class对象
  - class对象的isa指向meta-class对象
  - meta-class对象的isa指向基类的meta-class对象
- OC的类信息存放在哪里？
  - 对象方法、属性、成员变量、协议信息，存放在class对象中
  - 类方法，存放在meta-class对象中
  - 成员变量的具体值，存放在instance对象
- isa、superclass总结
  - instance的isa指向class
  - class的isa指向meta-class
  - meta-class的isa指向基类的meta-class
  - class的superclass指向父类的class
    - 如果没有父类，superclass指针为nil
  - meta-class的superclass指向父类的meta-class
    - 基类的meta-class的superclass指向基类的class
  - instance调用对象方法的轨迹
    - isa找到class，方法不存在，就通过superclass找父类
  - class调用类方法的轨迹
    - isa找meta-class，方法不存在，就通过superclass找父类

## 锁

- 互斥锁:防止两条线程同时对同一公共资源(比如全局变量)进行读写的机制。当获取锁操作失败时，线程会进入睡眠，等待锁释放时被唤醒
  - 递归锁:可重入锁，同一个线程在锁释放前可再次获取锁，即可以递归调用
  - 非递归锁:不可重入，必须等锁释放后才能再次获取锁
- 自旋锁:线程反复检查锁变量是否可⽤。由于线程在这⼀过程中保持执⾏， 因此是⼀种忙等待。⼀旦获取了⾃旋锁，线程会⼀直保持该锁，直⾄显式释 放⾃旋锁。⾃旋锁避免了进程上下⽂的调度开销，因此对于线程只会阻塞很短时间的场合是有效的
- 区别
  - 互斥锁在线程获取锁但没有获取到时，线程会进入休眠状态，等锁被释放时线程会被唤醒
  - 自旋锁的线程则会一直处于等待状态（忙等待）不会进入休眠——因此效率高

## 事件响应链

- UIApplication 会触发 func sendEvent(_ event: UIEvent) 将一个封装好的 UIEvent 传给 UIWindow，也就是当前展示的 UIWindow，通常情况接下来会传给当前展示的 UIViewController，接下来传给 UIViewController 的根视图。这个过程是一条龙服务，没有分叉。但是在传递给当前 UIViewController 的根视图，然后在传递给controller的view,检测是否可接受事件，检测坐标是否在自己内部，遍历子视图，重复上面步骤，找到合适的控件进行响应事件。

## Block

### 原理与本质

- block本质上也是一个OC对象，它内部也有个isa指针
- block是封装了函数调用以及函数调用环境的OC对象

### Block结构

```
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

### block变量捕获

- 为了保证block内部能够正常访问外部的变量，block有个变量捕获机制

  
  
  |     变量类型     |             捕获到block内部              | 访问方式 |
  | :--------------: | :--------------------------------------: | :------: |
  |  局部变量(auto)  | <input type="checkbox" checked disabled> |  值传递  |
  | 局部变量(static) | <input type="checkbox" checked disabled> | 指针传递 |
  |     全局变量     |     <input type="checkbox" disabled>     | 直接访问 |

### __block

#### 原理

- `__block`修饰auto变量，在block内使用，block会把修饰的变量包装成对象，所以使用`__block`修饰的变量可以进行修改，这是因为block内使用的指针进行修改

  ```
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

- block在修改NSMutableArray时需要进行`__blcok`吗
  - 不需要，因为array使用的是指针修改，不存在无法修改的问题。

### copy修饰

- 在ARC环境下，编译器会根据情况自动将栈上的block复制到堆上，比如以下情况
  - block作为函数返回值时
  - 将block赋值给__strong指针时
  - block作为Cocoa API中方法名含有usingBlock的方法参数时
  - block作为GCD API的方法参数时
  - ARC下使用strong/copy都可以
- MRC下只能使用copy

### 类型

| 类型          | 介绍                                                         |
| ------------- | :----------------------------------------------------------- |
| NSGlobalBlock | 没有访问auto变量的block，存放在数据段。调用copy什么都不做。  |
| NSStackBlock  | 访问auto变量,存放在栈中，注意ARC中测试时会显示为NSMallockBlock,这是因为编译器对block做了处理，关闭ARC即可。会自动销毁，所以需要用copy修饰，把block存到堆中 |
| NSMallocBlock | NSStackBlock调用copy；调用copy引用计数器加1                  |

## Category

### 使用场合

- 方法拆分、不改变原类的基础上增加方法、属性等。

### 结构

```
struct category_t{
    const char *name;   // 扩展类名
    struct _class_t *cls;   // 
    const struct _method_list_t *instance_methods;  // 对象方法列表
    const struct _method_list_t *class_methods; // 类方法类别
    const struct _protoclo_list_t *protocols  // 协议列表
    const struct _prop_list_t *properties;    // 属性列表
}
```

### 加载过程

- 通过runtime加载某个类的所有Category数据
- 把所有的Category方法、属性、协议合并到一个新数组中
- 将合并后的分类数据插入到类原有的数据前面
- 注：因为分类数据是插入到类原有数据前面，所以调用属性、方法、协议等都优先调用分类中的数据。

### 与Extension区别

- Category是在运行时才把分类数据添加进类信息中
- Extension编译是就把数据添加进类信息中

### load

- load方法会在runtime加载类、分类时调用
- 每个类、分类的+load,在程序运行过程中只调用一次
- 注：分类的+load不会覆盖类的+load

#### 调用顺序

- 先调用类的+load
  - 按编译先后顺序调用（先编译先调用）
  - 调用子类的+load之前会先调用父类的+load
- 再调用分类的+load
  - 按编译先后顺序调用（先编译先调用）

### initialize

- initialize方法会在类第一次接收到消息时调用

#### 调用顺序

- 先调用父类的+initialize,再调用子类的+initialize(子类不存在时不调用)
- 先初始化父类，在初始化子类，每个类只初始化一次

### load与initialize

- +initialize是通过objc_msgSend进行调用；+load是根据函数地址直接调用。
- 如果子类没有实现+initialize，会调用父类的+initialize，所以父类的+initialize可能会调用多次
- 如果分类实现的+initialize，就覆盖类本身的+initialize调用

### 成员变量

- 不能直接给Category添加成员变量，因为Category结构中没有属性列表，但是可以通过runtime的关联机制实现相同的效果

### 属性关联

- 关联对象并不是存储在被关联对象本身内存中
- 关联对象存储在全局的统一的一个AssociationsManager中
- 设置关联对象为nil，就相当于是移除关联对象

## KVC

### 查找顺序

- 按照getKey、key、isKey、_key顺序查找方法
  - 找到直接调用方法
  - 未找到：查看accessInstanceVariablesDirectly方法返回值，默认为Yes；方法意思是是否允许直接访问成员变量。
    - Yes：按照_key、_isKey、key、isKey的顺序查找
      - 找到直接赋值
      - 未找到
    - No：调用valueForUndefinedKey:方法，抛出NSUnKnownKeyException异常

### 赋值顺序

- 按照setKey、_setKey顺序查找方法
  - 找到方法：传递参数，调用方法
  - 未找到：查看accessInstanceVariablesDirectly方法返回值，默认为Yes；方法意思是是否允许直接访问成员变量。
    - Yes：按照_key、_isKey、key、isKey的顺序查找
      - 找到直接赋值
      - 未找到
    - No：调用setValue:forUndefinedKey:方法，抛出NSUnKnownKeyException异常

## KVO

### 原理

- 利用Runtime机制功态生成个子类，并且让instance对象的isa指针指向这个全新的类
- 当修改instance对象的属性时，会调用foundation的_NSSetXXXValueAndNotify函数
- 调用顺序
  - willChangeValueForKey:
  - setValue:
  - didChangeValueForKey:
- 内部会触发监听器（Oberser）的监听方法

### 派生类重写方法

- set方法：变化监听
- class：屏蔽方法实现
- dealloc：后续收尾
- ＿isKvoA：

### 手动触发

- 手动调用WillChangeValueForKey
- set方法赋值
- 手动调用DidChangeValueForKey

### 问题

- 直接修改属性不会执行属性监听方法

## Runloop

- 运行循环
- 在程序运行过程中循环做一些事情

### 应用

- 定时器（Timer）、PerformSelector
- GCD Async Main Queue
- 事件响应、手势识别、界面刷新
- 网络请求
- AutoreleasePool

### 作用

- 保持程序的持续运行
- 处理App中的各种事件（比如触摸事件、定时器事件等）
- 节省CPU资源，提高程序性能

### 具体应用

- 控制线程生命周期（线程保活）
- 解决NSTimer在滑动时停止工作的问题
- 监控应用卡顿
- 性能优化

### Runloop与线程

- 每条线程都有唯一的一个与之对应的RunLoop对象
- RunLoop保存在一个全局的Dictionary里，线程作为key，RunLoop作为value
- 线程刚创建时并没有RunLoop对象，RunLoop会在第一次获取它时创建
- RunLoop会在线程结束时销毁
- 主线程的RunLoop已经自动获取（创建），子线程默认没有开启RunLoop

### CFRunloopModeRef

- CFRunLoopModeRef代表RunLoop的运行模式
- 一个RunLoop包含若干个Mode，每个Mode又包含Source0/Source1/Timer/Observer
- RunLoop启动时只能选择其中一个Mode，作为currentMode
- 如果需要切换Mode，只能退出当前Loop，再重新选择一个Mode进入
  - 不同组的Source0/Source1/Timer/Observer能分隔开来，互不影响
- 如果Mode里没有任何Source0/Source1/Timer/Observer，RunLoop会立马退出

#### 常用的Mode

- kCFRunLoopDefaultMode（NSDefaultRunLoopMode）：App的默认Mode，通常主线程是在这个Mode下运行
- UITrackingRunLoopMode：界面跟踪 Mode，用于 ScrollView 追踪触摸滑动，保证界面滑动时不受其他 Mode 影响

#### Mode

- source0:触摸事件处理
- source1:基于port的线程通信和系统事件捕捉
- timer:定时器事件
- observer:runloop状态监听

## Runtime

- OC是一门动态性语言，允许很多操作在运行是进行操作
- OC的动态性就是靠runtime进行实现，runtime是一套C语言的API,封装了很多动态性相关的函数
- 平时编写的OC代码，底层都是转成runtime api调用

### 具体应用

- 利用关联对象给分类添加属性
- 遍历类的所有成员变量（修改textfiled占位文字颜色、字典转模型、自动归档解档等）
- 交换方法（替换系统方法实现）
- 利用消息转发机制解决方法找不到的异常问题

### isa

- 在arm64架构之前，isa就是一个普通的指针，存储着Class、Meta-Class对象的内存地址
- 从arm64架构开始，对isa进行了优化，使用一个64位的共用体（union）结构存储数据，其中的33位存储内存地址，其余存储其他数据

```
union isa_t {
    Class cls;
    uintptr_t bits;
    struct {
    /*
        0，代表普通的指针，存储着Class、Meta-Class对象的内存地址
        1，代表优化过，使用位域存储更多的信息
    */
        uintptr_t nonpointer; 
        // 是否有设置过关联对象，如果没有，释放时会更快
        uintptr_t has_assoc;
        // 是否有C++的析构函数（.cxx_destruct），如果没有，释放时会更快
        uintptr_t has_cxx_dtor;
        // 存储着Class、Meta-Class对象的内存地址信息
        uintptr_t shiftcls;
        // 用于在调试时分辨对象是否未完成初始化
        uintptr_t magic;
        // 是否有被弱引用指向过，如果没有，释放时会更快
        uintptr_t weakly_referenced;
        // 对象是否正在释放
        uintptr_t deallocating;
        /*
            引用计数器是否过大无法存储在isa中
            如果为1，那么引用计数会存储在一个叫SideTable的类的属性中
        */ 
        uintptr_t has_sidetable_rc;
        // 里面存储的值是引用计数器减1
        uintptr_t extra_rc;
    }
}
```

### 消息转发机制

#### 消息发送

- 检测receiver(接收者)是否为nil,为nil退出
- receiver通过isa指针找到receiverClass
- receiverClass的cache中查找方法，找到调用方法，结束查找
- receiverClass的class_rw_t中查找方法,找到方法，调用方法并把方法缓存到receiverClass的cache中，结束查找。
- receiverClass通过superclass指针找到superClass，重复上面步骤

#### 动态分析

- 是否曾经有动态解析，有的话直接消息转发
- 调用+resolveInstanceMethod或+resolveClassMethod来动态解析方法
- 标记为已动态解析
- 动态解析过后，会重新走“消息发送”的流程(从receiverClass的cache中查找方法)

#### 消息转发

- 调用forwardingTargetForSelector:检测是否有备用接收者
  - 返回值不为nil,执行objc_msgSend(返回值, SEL)
  - 为nil，调用methodSignatureForSelector进行签名
    - 不为nil, 调用forwardInvocation:方法
    - 为nil，调用doesNotRecognizeSelector

### weak原理

- runtime维持了一个weak表；当一个对象obj被weak指针指向时，这个weak指针会以obj的指针作为key，存储到sideTable类的weak_table这个散列表上对应的一个weak指针数组里面。 当一个对象obj的dealloc方法被调用时，Runtime会以obj的指针为key，从sideTable的weak_table散列表中，找出对应的weak指针列表，然后将里面的weak指针逐个置为nil

```
struct SideTable {
    // 保证原子操作的自旋锁
    spinlock_t slock;
    // 引用计数的 hash 表
    RefcountMap refcnts;
    // weak 引用全局 hash 表
    weak_table_t weak_table;
}
struct weak_table_t {
    // 保存了所有指向指定对象的 weak 指针
    weak_entry_t *weak_entries;
    // 存储空间
    size_t    num_entries;
    // 参与判断引用计数辅助量
    uintptr_t mask;
    // hash key 最大偏移值
    uintptr_t max_hash_displacement;
}
```

## 性能优化

### App启动优化

- APP的启动可以分为2种
  - 冷启动（Cold Launch）：从零开始启动APP
  - 热启动（Warm Launch）：APP已经在内存中，在后台存活着，再次点击图标启动APP
- 通过添加环境变量可以打印出APP的启动时间分析（Edit scheme -> Run -> Arguments）
  - DYLD_PRINT_STATISTICS设置为1
  - 如果需要更详细的信息，那就将DYLD_PRINT_STATISTICS_DETAILS设置为1
- dyld
  - 减少动态库、合并一些动态库（定期清理不必要的动态库）
  - 减少Objc类、分类的数量、减少Selector数量（定期清理不必要的类、分类）
  - 减少C++虚函数数量
  - Swift尽量使用struct
- runtime
  - 用+initialize方法和dispatch_once取代所有的__attribute__((constructor))、C++静态构造器、ObjC的+load
- main
  - 在不影响用户体验的前提下，尽可能将一些操作延迟，不要全部都放在finishLaunching方法中
  - 按需加载

### 安装包瘦身

#### 资源（图片、音频、视频等）

- 采取无损压缩
- 去除没有用到的资源

#### 可执行文件瘦身

- 编译器优化
  - Strip Linked Product、Make Strings Read-Only、Symbols Hidden by Default设置为YES
  - 去掉异常支持，Enable C++ Exceptions、Enable Objective-C Exceptions设置为NO， Other C Flags添加-fno-exceptions
- 利用AppCode（https://www.jetbrains.com/objc/）检测未使用的代码：菜单栏 -> Code -> Inspect Code
- 编写LLVM插件检测出重复代码、未被调用的代码

### CPU和GPU

- CPU: 对象的创建和销毁、对象属性的调整、布局计算、文本的计算和排版、图片的格式转换和解码、图像的绘制（Core Graphics)
  - 主要思路：尽可能减少CPU、GPU资源消耗
  - 尽量用轻量级的对象，比如用不到事件处理的地方，可以考虑使用CALayer取代UIView
  - 不要频繁地调用UIView的相关属性，比如frame、bounds、transform等属性，尽量减少不必要的修改
  - 尽量提前计算好布局，在有需要时一次性调整对应的属性，不要多次修改属性
  - Autolayout会比直接设置frame消耗更多的CPU资源
  - 图片的size最好刚好跟UIImageView的size保持一致
  - 控制一下线程的最大并发数量
  - 尽量把耗时的操作放到子线程
    - 文本处理（尺寸计算、绘制）
    - 图片处理（解码、绘制）
- GPU: 纹理的渲染
  - 尽量避免短时间内大量图片的显示，尽可能将多张图片合成一张进行显示
  - GPU能处理的最大纹理尺寸是4096x4096，一旦超过这个尺寸，就会占用CPU资源进行处理，所以纹理尽量不要超过这个尺寸
  - 尽量减少视图数量和层次
  - 减少透明的视图（alpha<1），不透明的就设置opaque为YES
  - 尽量避免出现离屏渲染

### 离屏渲染

- 在OpenGL中，GPU有2种渲染方式
  - On-Screen Rendering：当前屏幕渲染，在当前用于显示的屏幕缓冲区进行渲染操作
  - Off-Screen Rendering：离屏渲染，在当前屏幕缓冲区以外新开辟一个缓冲区进行渲染操作
- 离屏渲染消耗性能的原因
  - 需要创建新的缓冲区
  - 离屏渲染的整个过程，需要多次切换上下文环境，先是从当前屏幕（On-Screen）切换到离屏（Off-Screen）；等到离屏渲染结束以后，将离屏缓冲区的渲染结果显示到屏幕上，又需要将上下文环境从离屏切换到当前屏幕
- 哪些操作会触发离屏渲染？
  - 光栅化，layer.shouldRasterize = YES
  - 遮罩，layer.mask
  - 圆角，同时设置layer.masksToBounds = YES、layer.cornerRadius大于0
    - 考虑通过CoreGraphics绘制裁剪圆角，或者叫美工提供圆角图片
  - 阴影，layer.shadowXXX
    - 如果设置了layer.shadowPath就不会产生离屏渲染

### 卡顿检测

- 可以添加Observer到主线程RunLoop中，通过监听RunLoop状态切换的耗时，以达到监控卡顿的目的

### 耗电优化

- CPU优化
  - 尽可能降低CPU、GPU功耗
  - 少用定时器
  - 优化I/O操作
    - 尽量不要频繁写入小数据，最好批量一次性写入
    - 读写大量重要数据时，考虑用dispatch_io，其提供了基于GCD的异步操作文件I/O的API。用dispatch_io系统会优化磁盘访问
    - 数据量比较大的，建议使用数据库（比如SQLite、CoreData）
  - 网络优化
    - 减少、压缩网络数据
    - 如果多次请求的结果是相同的，尽量使用缓存
    - 使用断点续传，否则网络不稳定时可能多次传输相同的内容
    - 网络不可用时，不要尝试执行网络请求
    - 让用户可以取消长时间运行或者速度很慢的网络操作，设置合适的超时时间
    - 批量传输，比如，下载视频流时，不要传输很小的数据包，直接下载整个文件或者一大块一大块地下载。如果下载广告，一次性多下载一些，然后再慢慢展示。如果下载电子邮件，一次下载多封，不要一封一封地下载
- 定位优化
  - 如果只是需要快速确定用户位置，最好用CLLocationManager的requestLocation方法。定位完成后，会自动让定位硬件断电
  - 如果不是导航应用，尽量不要实时更新位置，定位完毕就关掉定位服务
  - 尽量降低定位精度，比如尽量不要使用精度最高的kCLLocationAccuracyBest
  - 需要后台定位时，尽量设置pausesLocationUpdatesAutomatically为YES，如果用户不太可能移动的时候系统会自动暂停位置更新
  - 尽量不要使用startMonitoringSignificantLocationChanges，优先考虑startMonitoringForRegion:
- 硬件检测优化
  - 用户移动、摇晃、倾斜设备时，会产生动作(motion)事件，这些事件由加速度计、陀螺仪、磁力计等硬件检测。在不需要检测的场合，应该及时关闭这些硬件

## 三方库

### SDWebImage

#### 原理解析

- 入口 setImageWithURL:placeholderImage:options:会先把 placeholderImage显示，然后 SDWebImageManager根据 URL 开始处理图片。（以URL的MD5值作为key）
- 进入SDImageCache从内存缓存查找SDImageCacheDelegate回调给SDWebImageManager，然后通过NSDWebImageManagerDelegate回调展示
- 如果内存缓存中没有，生成 ｀NSOperation｀添加到队列，开始从硬盘（Disk）查找图片是否已经下载
  - 有： 回主线程进行结果回调 NotifyDelegate，将图片添加到内存缓存中SDImageCache，再回调展示
  - 无： 共享或重新生成一个SDWebImageDownloader下载图片，由 NSURLSession实现相关 delegate，来判断图片下载中、下载完成和下载失败。
- 下载完后，放入硬盘，加入缓存，再回调展示

#### SDWebImage缓存为什么使用MapTable

- NSMaptable是可变的，没有不可变的类
- 可以持有键和值的弱引用，当键值当中的一个被释放时，整个这一项都会移除掉
- 可以对成员进行copy操作
- 可以存储任意的指针，通过指针来进行相等性和散列检查

### AFNetworking

#### 框架核心

##### NSURLSession

- AFURLSessionManager
- AFHTTPSessionManager

##### 序列化/反序列化

- AFURLRequestSerialization上传的数据转换成JSON格式
- AFJSONResponseSerializer JSON解析器

##### 安全协议

- AFSecurityPolicy 是针对 HTTPS的 服务

##### 网络管理器

- AFNetworkReachabilityManager，网络状态检测

##### UIKit

- 提供了网络请求过程中与UI界面显示相关的操作接口 ActivityIndicator、UIAlertView、UIButton、UIImageView、UIprogressView、UIWebView

#### 请求过程

- 初始化会话管理类：AFURLSessionManager
- 配置会话模式类型：NSURLSessionConfig
- 创建任务Task对象，启动任务
- 通过KVO监听download进度和upload进度
- 由任务代理回调处理：AFURLSessionmanagerTaskDelegate，数据响应，错误响应

### MJExtension

- NSString、NSData 转化成JSON对象：(NSDictionary本身就是json对象) [keyValuesArray mj_JSONObject]
- 遍历属性，返回属性列表，映射成对象MJProperty。 在Block回调中可以获取到每一个MJProperty（封装的属性） 通过单例做属性缓存
