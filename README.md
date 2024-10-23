![](https://cdn.nlark.com/yuque/0/2024/gif/680023/1729663173758-24bf774b-58da-404e-b90b-12dcf0b36844.gif)

登录场景中，使用手机验证码登录的场景及其常见，下面我们来封装一个简单的验证码倒计时组件，它需要提供以下功能：

+ 接受一个发送验证码的接口请求方法，UI 组件自己控制发送时机以及 UI 展示状态
+ 进行数字倒计时，结束倒计时后，文案显示为“重新获取”
+ 倒计时期间，不允许再次进行发送验证码请求
+ 自定义信息提示文案

在我们进行封装之后，我们的调用将会非常简单，将接口请求方法传入 CodeSender 即可，剩下的就交个组件自己处理了；

```arkts
@Entry
@Component
struct Login {
  @State phone: string = '';
  @State code: string = '';
  private sendCodeRef = new CodeSenderController()
  // 发送验证码
  sendCode = () => {
    // 接口请求，返回一个Promise
  }

  @Builder
  LoginForm() {
    Column() {
      // ...代码省略
      Row() {
        TextInput({ placeholder: "请输入验证码" })
          .maxLength(4)
          // 自定义样式
          .inputStyle()
          .onChange((value: string) => {
            this.code = value;
          })
          .flexShrink(1)
        CodeSender({
          send: this.sendCode,
          sucMsg: "验证码发送成功",
          isShowErr: true,
          controller: this.sendCodeRef
        })
      }
      // ...代码省略
    }
  }
```

## 开始封装
### 样式及基础控制
先把样式写出来

```arkts
@Component
struct CodeSender {
  // 控制倒计时组件
  private codeCountDown: TextTimerController = new TextTimerController()
  // 是否在倒计时中
  @State private receiving: boolean = false
  // 是否已经发送过一次验证码
  @State private isSend: boolean = false
  // 倒计时 59 秒
  private countTime: number = 59000

  build() {
    Stack({ alignContent: Alignment.End }) {
      Text(this.isSend ? "重新获取" : "获取验证码")
        .fontColor('#FF97989E')
        .onClick(() => {
          // TODO:【重新获取】和【获取验证码】文案展示时，进行接口请求发送
        })
        .textAlign(TextAlign.End)
        .visibility(!this.receiving ? Visibility.Visible : Visibility.Hidden)
      Row() {
        TextTimer({
          isCountDown: true,
          count: this.countTime,
          controller: this.codeCountDown
        }).format('ss').fontColor('#FF97989E')
        Text("秒后重新获取").fontColor('#FF97989E')
      }.visibility(this.receiving ? Visibility.Visible : Visibility.Hidden).justifyContent(FlexAlign.End)
    }
  }
}
```

这里我们简单的使用了 Stack 组件来进行布局，使用了 visibility 结合 isSending 变量，来控制是否现实倒计时组件，用到了 TextTimer 组件，使用它我们能很方便的进行倒计时的 UI 展示；

同时通过 isSend 变量来控制展示“重新获取”，还是“获取验证码”；

### 发送验证码方法调用方式
接下来我们继续完善，我们的核心目标是将发送验证码请求方法直接传入这个组件内，让它自己处理验证码发送的过程；因此我们需要定义一个方法，使得外部调用时，可以直接传入请求方法。

同时，在点击获取验证码的时候，能够触发外部调用传入的方法：

```arkts
@Component
  struct CodeSender {
    // ...省略代码
    // 接受一个方法，必须返回一个 Promise
    send: () => Promise<boolean> = () => {
      return Promise.resolve(true)
    }

    build() {
      Stack({ alignContent: Alignment.End }) {
        Text(this.isSend ? "重新获取" : "获取验证码")
          .onClick(() => {
            // TODO:【重新获取】和【获取验证码】文案展示时，进行接口请求发送
            this.send()
          })
        // 省略代码...
      }
    }
  }
```

调用时我们传入获取验证码的接口请求：

```arkts
// 调用方
@Component
  struct Login {
    getCodeReq(){
      // 发起获取验证码的请求，返回一个 Promise
    }
    build(){
      // 调用时
      CodeSender({
        send: this.getCodeReq
      })
    }
  }
```

此时我们能够在外部调用时，传入业务方法，发送一条验证码请求，并返回一个 Promise<boolean>，通过 boolean 返回值，我们在CodeSender 内部，就能通过这个值来判断做出什么样的处理了；

### 完善 CodeSender发送时的逻辑控制
在前面，我们已经可以通过 send 参数，将业务请求方法传入组件内部了，此时我们在 CodeSender 内把这个逻辑控制完善一下：

```arkts
@Component
  struct CodeSender {
    // 控制倒计时组件
    private codeCountDown: TextTimerController = new TextTimerController()
    // 是否在倒计时中
    @State private receiving: boolean = false
    // 请求中
    @State private isSending: boolean = false
    // 是否已经发送过一次验证码
    @State private isSend: boolean = false
    // 倒计时 59 秒
    private countTime: number = 59000
    // 接受一个方法，必须返回一个 Promise
    send: () => Promise<boolean> = () => {
      return Promise.resolve(true)
    }

    errMsg: string = "发送失败，请稍后重试"
    sucMsg: string = "发送成功"
    // 默认不展示错误信息
    isShowErr: boolean = false

    build() {
      Stack({ alignContent: Alignment.End }) {
        Text(this.isSend ? "重新获取" : "获取验证码")
          .onClick(() => {
            // 是否已经发送过请求了
            if (this.isSending) {
              return;
            }
            // 已发送
            this.isSending = true
            this.send().then((isSuc: boolean) => {
              // 发送成功
              if (isSuc) {
                // 已经发送过一次了
                this.isSend = true
                // 用户正在接收中
                this.receiving = true;
                // 倒计时开始
                this.codeCountDown.start()
                // 提示用户发送成功
                promptAction.showToast({ message: this.sucMsg, alignment: Alignment.Top })
                setTimeout(() => {
                  // 倒计时结束时，重置状态
                  this.receiving = false;
                  this.codeCountDown.reset()
                }, this.countTime)
              } else if (this.isShowErr && this.errMsg) {
                // 发送不成功，并且需要展示错误信息，并且 errMsg 存在，则弹窗提示用户
                promptAction.showToast({ message: this.errMsg, alignment: Alignment.Top })
              }
            }).finally(() => {
              // 请求发送结束响
              this.isSending = false
            })
          })
        // 省略代码...
      }
    }
  }
```

在点击“发送验证码”的时候，调用业务方传入的发送验证码请求方法，如果成功，则进行一系列的控制，并开启倒计时；如果失败，则根据配置的提示信息进行展示；

```arkts
// 调用方
@Component
  struct Login {
    getCodeReq(){
      // 发起获取验证码的请求，返回一个 Promise
    }
    build(){
      // 调用时
      CodeSender({
        send: this.getCodeReq,
        sucMsg: "验证码发送成功",
        errMsg:"发送失败",
        isShowErr: true,
      })
    }
  }
```

### 模拟业务请求验证码
接下来我们模拟写一个验证码发送的请求：

```arkts
// 调用方
@Component
  struct Login {
    @State phone: string = '';
    @State code: string = '';
    
    getCodeReq(){
      const sendCodeReq: Promise<boolean> = new Promise((resolve: Function) => {
        if (!this.phone) {
          // 未填写手机号
          resolve(false)
          return
        }
        if (/^(0|86|17951)?(13[0-9]|15[012356789]|166|17[3678]|18[0-9]|14[57])[0-9]{8}$/.test(this.phone)) {
          // 验证通过，真正发起请求
          setTimeout(() => {
            resolve(true)
          }, 3000);
        } else {
          // 手机号码验证不通过
          resolve(false)
        }
      })
      return sendCodeReq
    }
    build(){
      // 调用时
      CodeSender({
        send: this.getCodeReq,
        sucMsg: "验证码发送成功",
        errMsg:"发送失败",
        isShowErr: true,
      })
    }
  }
```

在业务方，我们模拟了一个发送验证码的请求，并返回了一个 Promise；

那现在出现一个问题，当未填写手机号码，和手机号码填写错误的情况下，怎么通过 CodeSender 来进行提示呢？

### 封装一个 controller 更改 CodeSender 的 msg
```arkts
class CodeSenderController {
  changeErrMsg = (value: string) => {
  }
  changeSucMsg = (value: string) => {
  }
}

@Component
  struct CodeSender {
    // 省略代码
    controller: CodeSenderController = new CodeSenderController()

    aboutToAppear(): void {
      if (this.controller) {
        this.controller.changeErrMsg = this.changeErrMsg
        this.controller.changeSucMsg = this.changeSucMsg
      }
    }

    private changeErrMsg = (value: string) => {
      this.errMsg = value;
    }
    private changeSucMsg = (value: string) => {
      this.sucMsg = value;
    }
    // ..省略代码
  }
```

我们声明了一个 contoller，在 aboutToAppear 的时候，将赋值内部的 changeErrMsg 和 changeSucMsg 方法，通过这个 controller，我们能在请求的过程中，动态的修改 Msg；

```arkts
// 调用方
@Component
  struct Login {
    private sendCodeRef = new CodeSenderController()
    
    getCodeReq(){
      const sendCodeReq: Promise<boolean> = new Promise((resolve: Function) => {
        if (!this.phone) {
          // 未填写手机号
          this.sendCodeRef.changeErrMsg("请先输入手机号！")
          resolve(false)
          return
        }
        if (/^(0|86|17951)?(13[0-9]|15[012356789]|166|17[3678]|18[0-9]|14[57])[0-9]{8}$/.test(this.phone)) {
          // 验证通过，真正发起请求
          setTimeout(() => {
            this.sendCodeRef.changeSucMsg("发送成功啦！")
            resolve(true)
          }, 3000);
        } else {
          // 手机号码验证不通过
          this.sendCodeRef.changeErrMsg("请输入正确的手机号码！")
          resolve(false)
        }
      })
      return sendCodeReq
    }
    build(){
      // 省略代码
    }
  }
```

通过这种方式，省去了调用方自己去写弹窗的逻辑，虽然也不费事，但是一旦都沉淀到CodeSender 内部之后，以后再调用也会很方便了；

### 提升请求过程的用户感知
在发起请求的时候，如果接口响应得很慢，则用户只会感觉到界面无响应，因此我们需要封装一个 loading 的提示框进去，当发起用户请求的时候，自动弹起 loading；

在这里我们通过@CustomDialog 来创建一个弹窗，并且用了 LoadingProgress 这个 UI 组件简单实现了一下；

```arkts
@CustomDialog
struct ReqLoading {
  controller: CustomDialogController = new CustomDialogController({
    builder: ReqLoading({}),
  })

  build() {
    LoadingProgress()
      .color(Color.Blue)
      .width(40).height(40)
  }
}
```

在 codeSender 中我们通过初始化CustomDialogController 来控制这个 loading 弹窗，并把它的逻辑放入请求过程中：

```arkts

@Component
  struct CodeSender {
    // 省略代码
    private loadingRef: CustomDialogController = new CustomDialogController({
      builder: ReqLoading(),
      customStyle: true
    })
    Stack({ alignContent: Alignment.End }) {
        Text(this.isSend ? "重新获取" : "获取验证码")
          .onClick(() => {
            // 是否已经发送过请求了
            if (this.isSending) {
              return;
            }
            // 已发送
            this.isSending = true
            this.loadingRef.open()
            this.send().finally(() => {
              this.loadingRef.close();
              // 请求发送结束响
              this.isSending = false
            })
          })
        // 省略代码...
      }
    // ..省略代码
  }
```

### 总结
ok，到目前为止，基本的功能已经封装进去了，还剩一些属于个性化的东西大家就自行封装把；比如：

+ loading 弹窗替换成自己项目的一套
+ 样式的封装以及自定义
+ ...

过渡封装也不是一件好事儿哦，封装虽好，可不要贪封哦；

## 源码地址
[zhoocoo/CodeSender](https://github.com/zhoocoo/CodeSender)



