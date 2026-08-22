// 注意：ArkTS 卡片不支持 import 其它 .ets 文件，接口需在本文件内定义
interface UsageWindowVM {
  label: string;
  remainingPercent: number;
}

interface UsageInfoVM {
  providerId: string;
  providerName?: string;
  windows: UsageWindowVM[];
  balance?: number;
  balanceUnit?: string;
  error?: string;
}

interface RowVM {
  id: string;
  name: string;
  kind: string; // 'window' 显示进度条 | 'text' 显示文本
  text: string;
  percent: number;
  color: string;
}

let storage = new LocalStorage();

@Entry(storage)
@Component
struct WidgetCard {
  @LocalStorageProp('providers') providersJson: string = '[]';

  private colorOf(percent: number): string {
    if (percent < 20) {
      return '#FF4D4F';
    }
    if (percent < 50) {
      return '#FF7D00';
    }
    return '#00B578';
  }

  private buildRows(): RowVM[] {
    const rows: RowVM[] = [];
    let list: UsageInfoVM[] = [];
    try {
      list = JSON.parse(this.providersJson) as UsageInfoVM[];
    } catch (e) {
      list = [];
    }
    const max = list.length < 4 ? list.length : 4;
    for (let i = 0; i < max; i++) {
      const info = list[i];
      let name = info.providerId;
      if (info.providerName !== undefined && info.providerName.length > 0) {
        name = info.providerName;
      }
      if (info.error !== undefined && info.error.length > 0) {
        rows.push({ id: info.providerId, name: name, kind: 'text', text: '失败', percent: 0, color: '#FF4D4F' });
        continue;
      }
      if (info.balance !== undefined) {
        const unit = info.balanceUnit !== undefined ? info.balanceUnit : '';
        rows.push({ id: info.providerId, name: name, kind: 'text', text: info.balance.toFixed(2) + ' ' + unit, percent: 0, color: '#333333' });
        continue;
      }
      if (info.windows !== undefined && info.windows.length > 0) {
        let min = info.windows[0];
        for (const w of info.windows) {
          if (w.remainingPercent < min.remainingPercent) {
            min = w;
          }
        }
        const pct = Math.max(0, Math.min(100, min.remainingPercent));
        rows.push({ id: info.providerId, name: name, kind: 'window', text: pct.toFixed(0) + '%', percent: pct, color: this.colorOf(pct) });
        continue;
      }
      rows.push({ id: info.providerId, name: name, kind: 'text', text: '-', percent: 0, color: '#999999' });
    }
    return rows;
  }

  build() {
    Column({ space: 4 }) {
      Row() {
        Text('AiQuota')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      if (this.buildRows().length === 0) {
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
        ForEach(this.buildRows(), (row: RowVM) => {
          Row() {
            Text(row.name)
              .fontSize(12)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width(56)

            if (row.kind === 'window') {
              Stack({ alignContent: Alignment.Start }) {
                Row()
                  .width('100%')
                  .height(5)
                  .backgroundColor('#E8E8E8')
                  .borderRadius(2)
                Row()
                  .width(row.percent + '%')
                  .height(5)
                  .backgroundColor(row.color)
                  .borderRadius(2)
              }
              .height(5)
              .layoutWeight(1)

              Text(row.text)
                .fontSize(11)
                .fontColor(row.color)
                .width(32)
                .textAlign(TextAlign.End)
            } else {
              Text(row.text)
                .fontSize(11)
                .fontColor(row.color)
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
          }
          .width('100%')
          .height(22)
          .alignItems(VerticalAlign.Center)
        }, (row: RowVM) => row.id)
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
