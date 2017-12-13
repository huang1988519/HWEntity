## 创建`万能Model`

### 原理简介

使用 NSProxy 做方法分发，拦截 Protocol中的属性 get & set方法，替换为 `NSDictionary` 中的 `objectForKey` & `setObeject:forKey `. 达到 赋值 、 取值。

json -> dic

转为NSDictionary 之后，每次取值时会判断对应key的value是否为 NSDictionary。

```
value = dic.objectFor(key)

if value is NSDictionary
  new model = HWEntiry(value)
  dic(model, forKey: key)
```

如果对应value为数组，则替换数组中的所有字典为 HWEntity

```
value = dic.objectFor(key)

tempArrays = NSMutableArray()

if values is NSArray
  for v in values
    if v is NSDictionary
      new model = HWEntiry(value)
      tempArrays.add(model)

dic(tempArrays, forKey:key)
```

### Usage


创建
```
@property (nonatomic, strong)id<XXTestEntiry>obj;

self.obj = HWEntiryWithJson(json);
```

取值
```
NSLog(@"origin about value = %@", self.obj.about);

```

赋值
```
self.obj.about = @"who am i";
```

嵌套 model取值
```
NSArray * objs = self.obj.friends;
    for (id<XXTestFriend>friend in objs) {
        NSLog(@"\n\n Hi friedn, my name is : %@, code : %@ \n\n", friend.name,friend._id);
    }
```

生成model预览
```
    |XXTestEntiry
        |about
        |balance
        |isActive
        |age
        |subEntiry <XXTestSubEntiry>
        |tags
            [string]
        |friends
            [XXTestFriend]
        |nullValue

```


### 集成

**CocoaPods**
```
pod 'HWEntity', :git => 'git@gitlab.alibaba-inc.com:weihua.hwh/HWEntity.git'

```

**源码集成**
下载源码，将 HWEntiry .h .m 两个文件拖入功能。

### 扩展

`+ (NSArray *)proxyMethods` NSProxy 默认 `isKindOfClass:` 也会拦截，还有其他常用的NSObject方法都未实现。把未实现的方法加入列表，然后在.m文件实现，否则会发生`crash`。

`+ (NSArray *)reserves` ios 保留关键词。防止json中的key和ios保留字冲突。
