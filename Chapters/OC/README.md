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

## 事件响应链

UIApplication 会触发 func sendEvent(_ event: UIEvent) 将一个封装好的 UIEvent 传给 UIWindow，也就是当前展示的 UIWindow，通常情况接下来会传给当前展示的 UIViewController，接下来传给 UIViewController 的根视图。这个过程是一条龙服务，没有分叉。但是在传递给当前 UIViewController 的根视图，然后在传递给controller的view,检测是否可接受事件，检测坐标是否在自己内部，遍历子视图，重复上面步骤，找到合适的控件进行响应事件。

