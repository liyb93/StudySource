# Category

主要使用在方法拆分、不改变原类的基础上增加方法、属性等。

```c++
typedef struct category_t {
    const char *name;//类的名字 主类名字
    classref_t cls;//类
    struct method_list_t *instanceMethods;//实例方法的列表
    struct method_list_t *classMethods;//类方法的列表
    struct protocol_list_t *protocols;//所有协议的列表
    struct property_list_t *instanceProperties;//添加的所有属性
} category_t;
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

- 不能直接给Category添加成员变量，因为Category结构中没有成员变量列表
- 结合category与原类的结合时机总结：分类并不会改变原有类的内存分布的情况，它是在运行期间决定的，此时内存的分布已经确定，若此时再添加实例会改变内存的分布情况，这对编译性语言是灾难，是不允许的。

## 方法和属性

方法和属性并不“属于”类实例，而成员变量“属于”类实例。我们所说的“类实例”概念，指的是一块内存区域，包含了isa指针和所有的成员变量。所以假如允许动态修改类成员变量布局，已经创建出的类实例就不符合类定义了，变成了无效对象。但方法定义是在objc_class中管理的，不管如何增删类方法，都不影响类实例的内存布局，已经创建出的类实例仍然可正常使用。

## 属性关联

- 关联对象并不是存储在被关联对象本身内存中
- 关联对象存储在全局的统一的一个AssociationsManager中
- 设置关联对象为nil，就相当于是移除关联对象

```objc
class AssociationsManager {
    static OSSpinLock _lock;
    static AssociationsHashMap *_map;               // associative references:  object pointer -> PtrPtrHashMap.
public:
    AssociationsManager()   { OSSpinLockLock(&_lock); }
    ~AssociationsManager()  { OSSpinLockUnlock(&_lock); }
    
    AssociationsHashMap &associations() {
        if (_map == NULL)
            _map = new AssociationsHashMap();
        return *_map;
    }
};
```

AssociationsManager里面是由一个静态AssociationsHashMap来存储所有的关联对象的。这相当于把所有对象的关联对象都存在一个全局map里面。而map的的key是这个对象的指针地址（任意两个不同对象的指针地址一定是不同的），而这个map的value又是另外一个AssociationsHashMap，里面保存了关联对象的键值对。