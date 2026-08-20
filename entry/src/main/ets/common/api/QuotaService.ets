import { ProviderConfig } from '../model/ProviderConfig';
import { UsageInfo } from '../model/UsageInfo';
import { KimiProvider } from './providers/KimiProvider';
import { GlmProvider } from './providers/GlmProvider';
import { MiniMaxProvider } from './providers/MiniMaxProvider';
import { DeepSeekProvider } from './providers/DeepSeekProvider';
import { NewApiProvider } from './providers/NewApiProvider';

export class QuotaService {
  static async queryProvider(config: ProviderConfig): Promise<UsageInfo> {
    try {
      let result: UsageInfo;
      switch (config.type) {
        case 'kimi':
          result = await KimiProvider.query(config);
          break;
        case 'glm':
          result = await GlmProvider.query(config);
          break;
        case 'minimax':
          result = await MiniMaxProvider.query(config);
          break;
        case 'deepseek':
          result = await DeepSeekProvider.query(config);
          break;
        case 'newapi':
          result = await NewApiProvider.query(config);
          break;
        default:
          throw new Error(`Unknown provider type: ${config.type}`);
      }
      result.providerName = config.name;
      return result;
    } catch (e) {
      return {
        providerId: config.id,
        providerName: config.name,
        windows: [],
        updatedAt: Date.now(),
        error: e instanceof Error ? e.message : String(e),
      };
    }
  }

  static async queryAll(providers: ProviderConfig[]): Promise<UsageInfo[]> {
    const enabled = providers.filter(p => p.enabled);
    const promises = enabled.map(p => QuotaService.queryProvider(p));
    return await Promise.all(promises);
  }
}
