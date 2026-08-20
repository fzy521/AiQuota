import router from '@ohos.router';
import common from '@ohos.app.ability.common';
import { ProviderConfig, ProviderType, PROVIDER_TYPE_LABELS, defaultProviderName } from '../common/model/ProviderConfig';
import { ProviderStore } from '../common/store/ProviderStore';
import { UsageCache } from '../common/store/UsageCache';
import { QuotaService } from '../common/api/QuotaService';

const TYPE_OPTIONS: { value: string }[] = [
  { value: 'Kimi' },
  { value: 'GLM' },
  { value: 'MiniMax' },
  { value: 'DeepSeek' },
  { value: 'NewAPI' },
];
const TYPES: ProviderType[] = ['kimi', 'glm', 'minimax', 'deepseek', 'newapi'];

function generateId(): string {
  return `${Date.now()}${Math.floor(Math.random() * 1000000)}`;
}

@Entry
@Component
struct ProviderEditPage {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @State id: string = '';
  @State name: string = '';
  @State type: ProviderType = 'kimi';
  @State apiKey: string = '';
  @State baseUrl: string = '';
  @State accessToken: string = '';
  @State userId: string = '';
  @State enabled: boolean = true;

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, string> | undefined;
    const editId = params?.['id'];
    if (editId) {
      const list = await ProviderStore.get(this.context);
      const found = list.find(p => p.id === editId);
      if (found) {
        this.id = found.id;
        this.name = found.name;
        this.type = found.type;
        this.apiKey = found.apiKey;
        this.baseUrl = found.baseUrl;
        this.accessToken = found.accessToken;
        this.userId = found.userId;
        this.enabled = found.enabled;
      }
    } else {
      this.name = defaultProviderName(this.type);
    }
  }

  private typeIndex(): number {
    return TYPES.indexOf(this.type);
  }

  private async save(): Promise<void> {
    const isNew = !this.id;
    const provider: ProviderConfig = {
      id: isNew ? generateId() : this.id,
      name: this.name || defaultProviderName(this.type),
      type: this.type,
      baseUrl: this.baseUrl,
      apiKey: this.apiKey,
      accessToken: this.accessToken,
      userId: this.userId,
      enabled: this.enabled,
    };

    let providers = await ProviderStore.get(this.context);
    if (isNew) {
      providers.push(provider);
    } else {
      providers = providers.map(p => p.id === provider.id ? provider : p);
    }
    ProviderStore.set(this.context, providers);

    const usage = await QuotaService.queryProvider(provider);
    const cache = UsageCache.get(this.context);
    const idx = cache.findIndex(u => u.providerId === provider.id);
    if (idx >= 0) {
      cache[idx] = usage;
    } else {
      cache.push(usage);
    }
    UsageCache.set(this.context, cache);

    router.back();
  }

  build() {
    Column({ space: 16 }) {
      Row() {
        Text('返回')
          .fontSize(16)
          .fontColor('#1677FF')
          .onClick(() => router.back())
        Text(this.id ? '编辑 Provider' : '添加 Provider')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text('保存')
          .fontSize(16)
          .fontColor('#1677FF')
          .onClick(() => this.save())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 8 })
      .backgroundColor(Color.White)

      Column({ space: 12 }) {
        Row() {
          Text('类型')
            .fontSize(14)
            .width(80)
          Select(TYPE_OPTIONS)
            .selected(this.typeIndex())
            .value(PROVIDER_TYPE_LABELS[this.type])
            .onSelect((index: number) => {
              this.type = TYPES[index];
              this.name = defaultProviderName(this.type);
              if (this.type === 'glm' && this.baseUrl === '') {
                this.baseUrl = 'https://open.bigmodel.cn';
              }
              if (this.type !== 'glm' && this.type !== 'newapi') {
                this.baseUrl = '';
              }
            })
            .width(200)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Text('名称')
            .fontSize(14)
            .width(80)
          TextInput({ placeholder: '显示名称', text: this.name })
            .placeholderColor('#AAAAAA')
            .onChange((value: string) => this.name = value)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        Row() {
          Text(this.type === 'newapi' ? 'Key' : 'API Key')
            .fontSize(14)
            .width(80)
          TextInput({ placeholder: '必填', text: this.apiKey })
            .placeholderColor('#AAAAAA')
            .type(InputType.Password)
            .onChange((value: string) => this.apiKey = value)
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)

        if (this.type === 'glm' || this.type === 'newapi') {
          Row() {
            Text('Base URL')
              .fontSize(14)
              .width(80)
            TextInput({ placeholder: this.type === 'glm' ? 'https://open.bigmodel.cn' : 'https://...', text: this.baseUrl })
              .placeholderColor('#AAAAAA')
              .onChange((value: string) => this.baseUrl = value)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }

        if (this.type === 'newapi') {
          Row() {
            Text('AccessToken')
              .fontSize(14)
              .width(80)
            TextInput({ placeholder: '必填', text: this.accessToken })
              .placeholderColor('#AAAAAA')
              .type(InputType.Password)
              .onChange((value: string) => this.accessToken = value)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)

          Row() {
            Text('User ID')
              .fontSize(14)
              .width(80)
            TextInput({ placeholder: '必填', text: this.userId })
              .placeholderColor('#AAAAAA')
              .onChange((value: string) => this.userId = value)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
        }
      }
      .width('100%')
      .padding(16)
      .backgroundColor(Color.White)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
