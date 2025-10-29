# RPC

## 原理

![image](https://www.cs.rutgers.edu/~pxk/417/notes/images/rpc-flow.png)

什么是Stub？

Stub是一段代码，用来转换RPC过程中传递的参数。处理内容包括不同OS之间的大小端问题。另外，Client端一般叫Stub，Server端一般叫Skeleton。

生产方式：
1. 手动生成，比较麻烦；
2. 自动生成，使用IDL（InterfaceDescriptionLanguate），定义C/S的接口


## RPC的套路：

自古深情留不住 唯有套路留人心

RPC最本质的就是通过socket把方法信息传输到远程服务器并执行相应method

在java界的rpc框架的实现手法：

- 服务端：socket + 反射
- 客户端：动态代理 + socket

之前也解析过motain框架，[《motain客服端分析》](https://mp.weixin.qq.com/s/kESoK3NmRp9Cwkg5GlI9DQ)、《motain服务端分析》

# thrift
由于我司框架是通过thrift改造，发现这个框架没有按java套路出牌，可能这是跨语言类RPC的套路，有必要了解一下

> thrift最初由facebook开发用做系统内各语言之间的RPC通信 。2007年由facebook贡献到apache基金 ，08年5月进入apache孵化器,支持多种语言之间的RPC方式的通信：php语言client可以构造一个对象，调用相应的服务方法来调用java语言的服务 ，跨越语言的C/S RPC调用
　　

![thrift](http://p7c3y4vhx.bkt.clouddn.com/201809192020_382.png)

## 示例

### IDL文件
```
//HelloService.thrfit
namespace java com.jack.thrift
service HelloService{
    string helloString(1:string what)
}
```

### 生成代码
```
运行  thrift -gen HelloService.thrfit

```
会生成一个HelloService类

### 实现服务端与客服端

让服务端打印出客户端传入的参数

#### 服务端

```
public class ThriftServer {

    /**
     * 启动thrift服务器
     * @param args
     */
    public static void main(String[] args) throws Exception {
        try {
            System.out.println("服务端开启....");
            TProcessor tprocessor = new HelloService.Processor<HelloService.Iface>(new HelloServiceImpl());
            // 简单的单线程服务模型
            TServerSocket serverTransport = new TServerSocket(9898);
            TServer.Args tArgs = new TServer.Args(serverTransport);
            tArgs.processor(tprocessor);
            tArgs.protocolFactory(new TBinaryProtocol.Factory());
            TServer server = new TSimpleServer(tArgs);
            server.serve();
        }catch (Exception e) {
            e.printStackTrace();
        }
    }

}
```

#### 客户端

```
public class ThriftClient {

    public static void main(String[] args) {
        System.out.println("客户端启动....");
        TTransport transport = null;
        try {
            transport = new TSocket("localhost", 9898, 30000);
            // 协议要和服务端一致
            TProtocol protocol = new TBinaryProtocol(transport);
            HelloService.Client client = new HelloService.Client(protocol);
            transport.open();
            String result = client.helloString("哈哈");
            System.out.println(result);
        } catch (TTransportException e) {
            e.printStackTrace();
        } catch (TException e) {
            e.printStackTrace();
        } finally {
            if (null != transport) {
                transport.close();
            }
        }
    }
}
```

## 解析
可以看出server,client代码相对很简单，主要看看生成的HelloService类，这个类就是stub代码

来看一下，这个类是如何封装，把method和args传输到远程的

### client
```
HelloService.Client client = new HelloService.Client(protocol);
String result = client.helloString("哈哈");
```

关键点在HelloService.Client.helloString()方法
```
public String helloString(String what) throws org.apache.thrift.TException
    {
      send_helloString(what);
      return recv_helloString();
    }
```

#### 发送消息
```
public void send_helloString(String what) throws org.apache.thrift.TException
    {
      helloString_args args = new helloString_args();
      args.setWhat(what);
      sendBase("helloString", args);
    }
```
1. 把args抽象成了一个类
2. 属性赋值
3. 发送

主要看下sendBase()方法
```
 private void sendBase(String methodName, TBase<?,?> args, byte type) throws TException {
    oprot_.writeMessageBegin(new TMessage(methodName, type, ++seqid_));
    args.write(oprot_);
    oprot_.writeMessageEnd();
    oprot_.getTransport().flush();
  }
```
- 1.oprot_.writeMessageBegin  根据Protocol写数据，比如这儿使用的TBinaryProtocol，以二进制写数据
```
public void writeMessageBegin(TMessage message) throws TException {
    if (strictWrite_) {
      int version = VERSION_1 | message.type;
      writeI32(version);
      writeString(message.name);
      writeI32(message.seqid);
    } else {
      writeString(message.name);
      writeByte(message.type);
      writeI32(message.seqid);
    }
  }
```
再深入看看怎么写二进制数据的

int类型
```
public void writeI32(int i32) throws TException {
    inoutTemp[0] = (byte)(0xff & (i32 >> 24));
    inoutTemp[1] = (byte)(0xff & (i32 >> 16));
    inoutTemp[2] = (byte)(0xff & (i32 >> 8));
    inoutTemp[3] = (byte)(0xff & (i32));
    trans_.write(inoutTemp, 0, 4);
  }
```

string类型，先写长度，再写bytes
```
public void writeString(String str) throws TException {
    try {
      byte[] dat = str.getBytes("UTF-8");
      writeI32(dat.length);
      trans_.write(dat, 0, dat.length);
    } catch (UnsupportedEncodingException uex) {
      throw new TException("JVM DOES NOT SUPPORT UTF-8");
    }
  }
```
这儿写最终还是使用Transport.write,比如这儿使用的TSocket
```
public void write(byte[] buf, int off, int len) throws TTransportException {
    if (outputStream_ == null) {
      throw new TTransportException(TTransportException.NOT_OPEN, "Cannot write to null outputStream");
    }
    try {
      outputStream_.write(buf, off, len);
    } catch (IOException iox) {
      throw new TTransportException(TTransportException.UNKNOWN, iox);
    }
  }
```
就是写到
```
outputStream_ = new BufferedOutputStream(socket_.getOutputStream(), 1024);
```

- 2.args.write(oprot_);
```
public void write(org.apache.thrift.protocol.TProtocol oprot, helloString_args struct) throws org.apache.thrift.TException {
        struct.validate();

        oprot.writeStructBegin(STRUCT_DESC);
        if (struct.what != null) {
          oprot.writeFieldBegin(WHAT_FIELD_DESC);
          oprot.writeString(struct.what);
          oprot.writeFieldEnd();
        }
        oprot.writeFieldStop();
        oprot.writeStructEnd();
      }
```
这就是写field,也就是向输出流里写参数内容

- 3.oprot_.writeMessageEnd();
这表示消息写完成了，各个协议处理不同，比如二进制就是空实现，但如json就需要写个"}"，以完成json格式

- 4.oprot_.getTransport().flush();  直接flush
```
/**
   * Flushes the underlying output stream if not null.
   */
  public void flush() throws TTransportException {
    if (outputStream_ == null) {
      throw new TTransportException(TTransportException.NOT_OPEN, "Cannot flush null outputStream");
    }
    try {
      outputStream_.flush();
    } catch (IOException iox) {
      throw new TTransportException(TTransportException.UNKNOWN, iox);
    }
  }
```

#### client总结
整个发送消息就结束了，虽然没有按套路使用动态代理，而是通过生成的stub代码，把methodName,args给封装好了

### server
服务端也没有通过反射的方式


主要逻辑在生成的HelloService$Processor类中
```
public static class Processor<I extends Iface> extends org.apache.thrift.TBaseProcessor<I> implements org.apache.thrift.TProcessor {
    private static final org.slf4j.Logger _LOGGER = org.slf4j.LoggerFactory.getLogger(Processor.class.getName());
    public Processor(I iface) {
      super(iface, getProcessMap(new java.util.HashMap<String, org.apache.thrift.ProcessFunction<I, ? extends org.apache.thrift.TBase>>()));
    }

    protected Processor(I iface, java.util.Map<String, org.apache.thrift.ProcessFunction<I, ? extends org.apache.thrift.TBase>> processMap) {
      super(iface, getProcessMap(processMap));
    }

    private static <I extends Iface> java.util.Map<String,  org.apache.thrift.ProcessFunction<I, ? extends org.apache.thrift.TBase>> getProcessMap(java.util.Map<String, org.apache.thrift.ProcessFunction<I, ? extends  org.apache.thrift.TBase>> processMap) {
      processMap.put("helloString", new helloString());
      return processMap;
    }

    public static class helloString<I extends Iface> extends org.apache.thrift.ProcessFunction<I, helloString_args> {
      public helloString() {
        super("helloString");
      }

      public helloString_args getEmptyArgsInstance() {
        return new helloString_args();
      }

      protected boolean isOneway() {
        return false;
      }

      @Override
      protected boolean handleRuntimeExceptions() {
        return false;
      }

      public helloString_result getResult(I iface, helloString_args args) throws org.apache.thrift.TException {
        helloString_result result = new helloString_result();
        result.success = iface.helloString(args.what);
        return result;
      }
    }

  }
```

- 1.先看构造函数
```
protected Processor(I iface, java.util.Map<String, org.apache.thrift.ProcessFunction<I, ? extends org.apache.thrift.TBase>> processMap) {
      super(iface, getProcessMap(processMap));
    }

    private static <I extends Iface> java.util.Map<String,  org.apache.thrift.ProcessFunction<I, ? extends org.apache.thrift.TBase>> getProcessMap(java.util.Map<String, org.apache.thrift.ProcessFunction<I, ? extends  org.apache.thrift.TBase>> processMap) {
      processMap.put("helloString", new helloString());
      return processMap;
    }
```
这段把methodName与对应的处理类映射，那后面的事就简单了，当接受到消息，取得methodName,通过map获取对就的处理类回调就可以

```
public static class helloString<I extends Iface> extends org.apache.thrift.ProcessFunction<I, helloString_args> {
      public helloString() {
        super("helloString");
      }

      public helloString_args getEmptyArgsInstance() {
        return new helloString_args();
      }

      protected boolean isOneway() {
        return false;
      }

      @Override
      protected boolean handleRuntimeExceptions() {
        return false;
      }

      public helloString_result getResult(I iface, helloString_args args) throws org.apache.thrift.TException {
        helloString_result result = new helloString_result();
        result.success = iface.helloString(args.what);
        return result;
      }
    }
```
处理类，继承ProcessFunction类，实现getResult(),这个方法就是调用了对应service.helloString()

可以再深入看一下,在socket监听消息时
```
client = serverTransport_.accept();
        if (client != null) {
          processor = processorFactory_.getProcessor(client);
          inputTransport = inputTransportFactory_.getTransport(client);
          outputTransport = outputTransportFactory_.getTransport(client);
          inputProtocol = inputProtocolFactory_.getProtocol(inputTransport);
          outputProtocol = outputProtocolFactory_.getProtocol(outputTransport);
          if (eventHandler_ != null) {
            connectionContext = eventHandler_.createContext(inputProtocol, outputProtocol);
          }
          while (true) {
            if (eventHandler_ != null) {
              eventHandler_.processContext(connectionContext, inputTransport, outputTransport);
            }
            if(!processor.process(inputProtocol, outputProtocol)) {
              break;
            }
          }
```
关键行：processor.process(inputProtocol, outputProtocol)

```
public boolean process(TProtocol in, TProtocol out) throws TException {
    TMessage msg = in.readMessageBegin();
    ProcessFunction fn = processMap.get(msg.name);
    if (fn == null) {
      TProtocolUtil.skip(in, TType.STRUCT);
      in.readMessageEnd();
      TApplicationException x = new TApplicationException(TApplicationException.UNKNOWN_METHOD, "Invalid method name: '"+msg.name+"'");
      out.writeMessageBegin(new TMessage(msg.name, TMessageType.EXCEPTION, msg.seqid));
      x.write(out);
      out.writeMessageEnd();
      out.getTransport().flush();
      return true;
    }
    fn.process(msg.seqid, in, out, iface);
    return true;
  }
```
这就很明显了，通过methodName从map中取得ProccessFunction，再执行process方法，调用相应service的方法

# 总结
虽然thrift没有按以往java套路出牌，但最根本的把method发送到远程执行是一致的。可能对于多语言来讲，便于所以语言一致性，的确需要通过生成的stub代码手法来实现RPC

当然thrift并不简单，还有很多的内容需要深挖学习，但至少这个简单示例可以了解跨语言型的RPC，相关IDL,Stub的知识，有清晰认知，而不局限于概念