import { promptAction } from '@kit.ArkUI';

export class CodeSenderController {
  changeErrMsg = (value: string) => {
  }
  changeSucMsg = (value: string) => {
  }
}

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

@Component
export struct CodeSender {
  private codeCountDown: TextTimerController = new TextTimerController()
  private loadingRef: CustomDialogController = new CustomDialogController({
    builder: ReqLoading(),
    customStyle: true
  })
  @State private isSending: boolean = false
  @State private isSend: boolean = false
  @State private receiving: boolean = false
  private countTime: number = 59000
  errMsg: string = "发送失败，请稍后重试"
  sucMsg: string = "发送成功"
  isShowErr: boolean = false
  send: () => Promise<boolean> = () => {
    return Promise.resolve(true)
  }
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

  build() {
    Stack({ alignContent: Alignment.End }) {
      Text(this.isSend ? "重新获取" : "获取验证码")
        .fontColor('#FF97989E')
        .onClick(() => {
          if (this.isSending) {
            return;
          }
          this.isSending = true
          this.loadingRef.open()
          this.send().then((isSuc: boolean) => {
            if (isSuc) {
              this.isSend = true
              this.receiving = true;
              this.codeCountDown.start()
              promptAction.showToast({ message: this.sucMsg, alignment: Alignment.Top })
              setTimeout(() => {
                this.receiving = false;
                this.codeCountDown.reset()
              }, this.countTime)
            } else if (this.isShowErr && this.errMsg) {
              promptAction.showToast({ message: this.errMsg, alignment: Alignment.Top })
            }
          }).finally(() => {
            this.loadingRef.close();
            this.isSending = false
          })
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
