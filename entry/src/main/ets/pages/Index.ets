import { CodeSender, CodeSenderController } from "../view/CodeSender"

@Extend(TextInput)
function inputStyle() {
  .placeholderColor('#FF97989E')
  .backgroundColor("#fff")
  .height(48)
  .fontSize(16)
  .padding({
    left: 12,
    right: 12
  })
  .inputFilter('[0-9]', (val) => {
    return 1;
  })
}


@Extend(Button)
function submitStyle(status: 'disabled' | 'normal') {
  .fontColor('white')
  .fontSize(16)
  .backgroundColor(status === 'disabled' ? '#FFCACACC' : '#FF4A77FF')
}

@Entry
@Component
struct Login {
  @State phone: string = '';
  @State code: string = '';
  private sendCodeRef = new CodeSenderController()
  // 发送验证码
  getCodeReq = () => {
    const sendCodeReq: Promise<boolean> = new Promise((resolve: Function) => {
      if (!this.phone) {
        this.sendCodeRef.changeErrMsg("请先输入手机号！")
        resolve(false)
        return
      }
      if (/^(0|86|17951)?(13[0-9]|15[012356789]|166|17[3678]|18[0-9]|14[57])[0-9]{8}$/.test(this.phone)) {
        setTimeout(() => {
          resolve(true)
        }, 3000);
      } else {
        this.sendCodeRef.changeErrMsg("请输入正确的手机号码！")
        resolve(false)
      }
    })
    return sendCodeReq
  }

  @Builder
  LoginForm() {
    Column() {
      TextInput({ placeholder: '请输入手机号' })
        .maxLength(11)
        .inputStyle()
        .onChange((value: string) => {
          this.phone = value;
        })
      Line()
        .width("100%")
        .height('0.5vp')
        .backgroundColor("#0D000000")
        .margin({
          left: 12,
          right: 12
        })
      Row() {
        TextInput({ placeholder: "请输入验证码" })
          .maxLength(4)
          .inputStyle()
          .onChange((value: string) => {
            this.code = value;
          })
          .flexShrink(1)
        CodeSender({
          send: this.getCodeReq,
          sucMsg: "验证码发送成功",
          isShowErr: true,
          controller: this.sendCodeRef
        })
      }.width("100%")

      Column({
        space: 12
      }) {
        Button("登录").width("100%").submitStyle(this.phone && this.code ? 'normal' : 'disabled')
      }.margin({ top: 16 })
    }
    .padding({
      top: 16,
      bottom: 16
    })
    .width('100%')
    .backgroundColor("#FFFFFFFF")
    .borderRadius(16)
  }

  build() {
    Column({
      space: 8
    }) {
      this.LoginForm()
    }.padding(16)
  }
}