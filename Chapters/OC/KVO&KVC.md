# KVO&KVC

## KVC

##### 查找顺序

- 按照getKey、key、isKey、_key顺序查找方法
  - 找到直接调用方法
  - 未找到：查看accessInstanceVariablesDirectly方法返回值，默认为Yes；方法意思是是否允许直接访问成员变量。
    - Yes：按照_key、_isKey、key、isKey的顺序查找
      - 找到直接赋值
      - 未找到
    - No：调用valueForUndefinedKey:方法，抛出NSUnKnownKeyException异常

##### 赋值顺序

- 按照setKey、_setKey顺序查找方法
  - 找到方法：传递参数，调用方法
  - 未找到：查看accessInstanceVariablesDirectly方法返回值，默认为Yes；方法意思是是否允许直接访问成员变量。
    - Yes：按照_key、_isKey、key、isKey的顺序查找
      - 找到直接赋值
      - 未找到
    - No：调用setValue:forUndefinedKey:方法，抛出NSUnKnownKeyException异常

## KVO

##### 原理

- 利用Runtime机制功态生成个子类，并且让instance对象的isa指针指向这个全新的类
- 当修改instance对象的属性时，会调用foundation的_NSSetXXXValueAndNotify函数
- 调用顺序
  - willChangeValueForKey:
  - setValue:
  - didChangeValueForKey:
- 内部会触发监听器（Oberser）的监听方法

##### 派生类重写方法

- set方法：变化监听
- class：屏蔽方法实现
- dealloc：后续收尾
- ＿isKvoA：

##### 手动触发

- 手动调用WillChangeValueForKey
- set方法赋值
- 手动调用DidChangeValueForKey

##### 问题

- 直接修改属性不会执行属性监听方法