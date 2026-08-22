export type ProviderType = 'kimi' | 'glm' | 'minimax' | 'deepseek' | 'newapi';

export interface ProviderConfig {
  id: string;
  name: string;
  type: ProviderType;
  baseUrl: string;
  apiKey: string;
  accessToken: string;
  userId: string;
  enabled: boolean;
}

// ArkTS 不允许 Record<联合类型, T> 形式的对象字面量，用显式接口
export interface ProviderTypeLabels {
  kimi: string;
  glm: string;
  minimax: string;
  deepseek: string;
  newapi: string;
}

export const PROVIDER_TYPE_LABELS: ProviderTypeLabels = {
  kimi: 'Kimi',
  glm: 'GLM',
  minimax: 'MiniMax',
  deepseek: 'DeepSeek',
  newapi: 'NewAPI'
};

export function defaultProviderName(type: ProviderType): string {
  return PROVIDER_TYPE_LABELS[type];
}
