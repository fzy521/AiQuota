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

// ArkTS 不允许对接口字段做索引访问（arkts-no-props-by-index），用 switch 函数
export function providerTypeLabel(type: ProviderType): string {
  switch (type) {
    case 'kimi':
      return 'Kimi';
    case 'glm':
      return 'GLM';
    case 'minimax':
      return 'MiniMax';
    case 'deepseek':
      return 'DeepSeek';
    case 'newapi':
      return 'NewAPI';
  }
}

export function defaultProviderName(type: ProviderType): string {
  return providerTypeLabel(type);
}
