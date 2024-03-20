# Category

主要使用在方法拆分、不改变原类的基础上增加方法、属性等。

```c++
struct category_t{
    const char *name;   // 扩展类名
    struct _class_t *cls;   // 
    const struct _method_list_t *instance_methods;  // 对象方法列表
    const struct _method_list_t *class_methods; // 类方法类别
    const struct _protoclo_list_t *protocols  // 协议列表
    const struct _prop_list_t *properties;    // 属性列表
}
```

## 加载过程

- 通过runtime加载某个类的所有Category数据
- 把所有的Category方法、属性、协议合并到一个新数组中
- 将合并后的分类数据插入到类原有的数据前面

注：因为分类数据是插入到类原有数据前面，所以调用属性、方法、协议等都优先调用分类中的数据。

## 与Extension区别

- Category是在运行时才把分类数据添加进类信息中
- Extension编译是就把数据添加进类信息中

## load

- load方法会在runtime加载类、分类时调用
- 每个类、分类的+load,在程序运行过程中只调用一次

注：分类的+load不会覆盖类的+load

##### 调用顺序

- 先调用类的+load
  - 按编译先后顺序调用（先编译先调用）
  - 调用子类的+load之前会先调用父类的+load
- 再调用分类的+load
  - 按编译先后顺序调用（先编译先调用）

## initialize

- initialize方法会在类第一次接收到消息时调用

###### 调用顺序

- 先调用父类的+initialize,再调用子类的+initialize(子类不存在时不调用)
- 先初始化父类，在初始化子类，每个类只初始化一次

## load与initialize

- +initialize是通过objc_msgSend进行调用；+load是根据函数地址直接调用。
- 如果子类没有实现+initialize，会调用父类的+initialize，所以父类的+initialize可能会调用多次
- 如果分类实现的+initialize，就覆盖类本身的+initialize调用

## 成员变量

- 不能直接给Category添加成员变量，因为Category结构中没有属性列表，但是可以通过runtime的关联机制实现相同的效果

## 属性关联

- 关联对象并不是存储在被关联对象本身内存中
- 关联对象存储在全局的统一的一个AssociationsManager中
- 设置关联对象为nil，就相当于是移除关联对象