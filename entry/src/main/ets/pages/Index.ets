import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import formProvider from '@ohos.app.form.formProvider';
import formBindingData from '@ohos.app.form.formBindingData';
import { ProviderConfig, PROVIDER_TYPE_LABELS } from '../common/model/ProviderConfig';
import { UsageInfo, UsageWindow } from '../common/model/UsageInfo';
import { ProviderStore } from '../common/store/ProviderStore';
import { UsageCache } from '../common/store/UsageCache';
import { QuotaService } from '../common/api/QuotaService';

@Entry
@Component
struct Index {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State providers: ProviderConfig[] = [];
  @State usageMap: Record<string, UsageInfo> = {};
  @State refreshing: boolean = false;

  async aboutToAppear(): Promise<void> {
    await this.loadData();
    await this.refreshAll();
  }

  private async loadData(): Promise<void> {
    this.providers = await ProviderStore.get(this.context);
    const usageList = UsageCache.get(this.context);
    const map: Record<string, UsageInfo> = {};
    for (const u of usageList) {
      map[u.providerId] = u;
    }
    this.usageMap = map;
  }

  private async updateForms(): Promise<void> {
    const usage = UsageCache.get(this.context);
    const data = formBindingData.createFormBindingData({ providers: JSON.stringify(usage) });
    const ids = UsageCache.getFormIds(this.context);
    for (const id of ids) {
      try {
        await formProvider.updateForm(id, data);
      } catch (e) {
        console.error(`updateForm failed for ${id}: ${e instanceof Error ? e.message : String(e)}`);
      }
    }
  }

  private async refreshAll(): Promise<void> {
    this.refreshing = true;
    const usage = await QuotaService.queryAll(this.providers);
    UsageCache.set(this.context, usage);
    await this.updateForms();
    const map: Record<string, UsageInfo> = {};
    for (const u of usage) {
      map[u.providerId] = u;
    }
    this.usageMap = map;
    this.refreshing = false;
  }

  private cloneUsageMap(source: Record<string, UsageInfo>, excludeId?: string): Record<string, UsageInfo> {
    const next: Record<string, UsageInfo> = {};
    for (const key of Object.keys(source)) {
      if (key !== excludeId) {
        next[key] = source[key];
      }
    }
    return next;
  }

  private async refreshOne(provider: ProviderConfig): Promise<void> {
    const usage = await QuotaService.queryProvider(provider);
    const list = UsageCache.get(this.context);
    const idx = list.findIndex(u => u.providerId === provider.id);
    if (idx >= 0) {
      list[idx] = usage;
    } else {
      list.push(usage);
    }
    UsageCache.set(this.context, list);
    await this.updateForms();
    const next = this.cloneUsageMap(this.usageMap);
    next[provider.id] = usage;
    this.usageMap = next;
  }

  private deleteProvider(provider: ProviderConfig): void {
    const list = this.providers.filter(p => p.id !== provider.id);
    this.providers = list;
    ProviderStore.set(this.context, list);
    const usageList = UsageCache.get(this.context).filter(u => u.providerId !== provider.id);
    UsageCache.set(this.context, usageList);
    this.usageMap = this.cloneUsageMap(this.usageMap, provider.id);
  }

  private progressColor(percent: number): string {
    if (percent < 20) {
      return '#FF4D4F';
    }
    if (percent < 50) {
      return '#FF7D00';
    }
    return '#00B578';
  }

  private formatTime(ts: number): string {
    if (ts <= 0) {
      return '未刷新';
    }
    const d = new Date(ts);
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  }

  // build/@Builder 中不允许声明局部变量，通过方法获取展示数据
  private getInfo(providerId: string): UsageInfo {
    const found = this.usageMap[providerId];
    if (found !== undefined) {
      return found;
    }
    return { providerId: providerId, windows: [], updatedAt: 0 };
  }

  private mostUrgentWindow(info: UsageInfo): UsageWindow {
    if (info.windows.length === 0) {
      return { label: '', remaining: 0, limit: 0, remainingPercent: 0, resetTime: '' };
    }
    let min = info.windows[0];
    for (const w of info.windows) {
      if (w.remainingPercent < min.remainingPercent) {
        min = w;
      }
    }
    return min;
  }

  @Builder
  DeleteButton(provider: ProviderConfig) {
    Row() {
      Text('删除')
        .fontColor(Color.White)
        .fontSize(14)
    }
    .width(64)
    .height('100%')
    .backgroundColor('#FF4D4F')
    .justifyContent(FlexAlign.Center)
    .onClick(() => this.deleteProvider(provider))
  }

  @Builder
  ProviderItem(provider: ProviderConfig, info: UsageInfo) {
    Column() {
      Row() {
        Text(provider.name || PROVIDER_TYPE_LABELS[provider.type])
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        Text(PROVIDER_TYPE_LABELS[provider.type])
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      if (info.error !== undefined && info.error.length > 0) {
        Text(`错误: ${info.error}`)
          .fontSize(12)
          .fontColor('#FF4D4F')
          .width('100%')
          .margin({ top: 4 })
      } else if (info.balance !== undefined) {
        Text(`余额: ${info.balance.toFixed(4)} ${info.balanceUnit ?? ''}`)
          .fontSize(14)
          .fontColor('#333333')
          .width('100%')
          .margin({ top: 4 })
      } else if (info.windows.length > 0) {
        Row() {
          Text(this.mostUrgentWindow(info).label)
            .fontSize(12)
            .fontColor('#666666')
          Text(`${this.mostUrgentWindow(info).remainingPercent.toFixed(0)}%`)
            .fontSize(12)
            .fontColor(this.progressColor(this.mostUrgentWindow(info).remainingPercent))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 4 })

        Stack({ alignContent: Alignment.Start }) {
          Row()
            .width('100%')
            .height(6)
            .backgroundColor('#E8E8E8')
            .borderRadius(3)
          Row()
            .width(`${this.mostUrgentWindow(info).remainingPercent}%`)
            .height(6)
            .backgroundColor(this.progressColor(this.mostUrgentWindow(info).remainingPercent))
            .borderRadius(3)
        }
        .width('100%')
        .height(6)
        .margin({ top: 4 })
      } else {
        Text('点击刷新获取用量')
          .fontSize(12)
          .fontColor('#999999')
          .width('100%')
          .margin({ top: 4 })
      }

      Row() {
        Text(`更新: ${this.formatTime(info.updatedAt)}`)
          .fontSize(11)
          .fontColor('#AAAAAA')
          .layoutWeight(1)
        Text('刷新')
          .fontSize(12)
          .fontColor('#1677FF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .onClick(() => this.refreshOne(provider))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .onClick(() => {
      router.pushUrl({ url: 'pages/ProviderEditPage', params: { id: provider.id } });
    })
  }

  build() {
    Column({ space: 12 }) {
      Row() {
        Text('AiQuota')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('+')
          .fontSize(28)
          .fontColor('#1677FF')
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/ProviderEditPage' });
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(Color.White)

      Refresh({ refreshing: this.refreshing, offset: 120, friction: 100 }) {
        List({ space: 12 }) {
          ForEach(this.providers, (provider: ProviderConfig) => {
            ListItem() {
              this.ProviderItem(provider, this.getInfo(provider.id))
            }
            .swipeAction({ end: this.DeleteButton(provider) })
          }, (provider: ProviderConfig) => provider.id)
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
        .layoutWeight(1)
      }
      .onRefreshing(() => this.refreshAll())
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
