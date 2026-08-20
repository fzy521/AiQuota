import { UsageInfo, UsageWindow } from '../../common/model/UsageInfo';

let storage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('providers') providers: string = '[]';

  private parseProviders(): UsageInfo[] {
    try {
      return JSON.parse(this.providers) as UsageInfo[];
    } catch (e) {
      return [];
    }
  }

  private mostUrgent(info: UsageInfo): UsageWindow | undefined {
    if (!info.windows || info.windows.length === 0) return undefined;
    let min = info.windows[0];
    for (const w of info.windows) {
      if (w.remainingPercent < min.remainingPercent) {
        min = w;
      }
    }
    return min;
  }

  private progressColor(percent: number): string {
    if (percent < 20) return '#FF4D4F';
    if (percent < 50) return '#FF7D00';
    return '#00B578';
  }

  build() {
    const list = this.parseProviders();
    Column({ space: 4 }) {
      Row() {
        Text('AiQuota')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      if (list.length === 0) {
        Column() {
          Text('请先在 App 中')
            .fontSize(12)
            .fontColor('#666666')
          Text('添加 Provider')
            .fontSize(12)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          postCardAction(this, { action: 'router', abilityName: 'EntryAbility' });
        })
      } else {
        ForEach(list.slice(0, 4), (info: UsageInfo) => {
          const urgent = this.mostUrgent(info);
          Row() {
            Text(info.providerName ?? info.providerId)
              .fontSize(12)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(56)

            if (info.error) {
              Text('失败')
                .fontSize(11)
                .fontColor('#FF4D4F')
                .layoutWeight(1)
            } else if (info.balance !== undefined) {
              Text(`${info.balance.toFixed(2)} ${info.balanceUnit ?? ''}`)
                .fontSize(11)
                .fontColor('#333333')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            } else if (urgent) {
              Stack({ alignContent: Alignment.Start }) {
                Row()
                  .width('100%')
                  .height(5)
                  .backgroundColor('#E8E8E8')
                  .borderRadius(2)
                Row()
                  .width(`${urgent.remainingPercent}%`)
                  .height(5)
                  .backgroundColor(this.progressColor(urgent.remainingPercent))
                  .borderRadius(2)
              }
              .width('100%')
              .height(5)
              .layoutWeight(1)

              Text(`${urgent.remainingPercent.toFixed(0)}%`)
                .fontSize(11)
                .fontColor(this.progressColor(urgent.remainingPercent))
                .width(32)
                .textAlign(TextAlign.End)
            } else {
              Text('-')
                .fontSize(11)
                .fontColor('#999999')
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
          }
          .width('100%')
          .height(22)
          .alignItems(VerticalAlign.Center)
        }, (info: UsageInfo) => info.providerId)
      }

      Row() {
        Text('刷新')
          .fontSize(12)
          .fontColor(Color.White)
          .padding({ left: 10, right: 10, top: 2, bottom: 2 })
          .backgroundColor('#1677FF')
          .borderRadius(4)
          .onClick(() => {
            postCardAction(this, { action: 'message', params: { msg: 'refresh' } });
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .padding(8)
    .backgroundColor('#FFFFFF')
  }
}
