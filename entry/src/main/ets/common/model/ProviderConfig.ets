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

export const PROVIDER_TYPE_LABELS: Record<ProviderType, string> = {
  kimi: 'Kimi',
  glm: 'GLM',
  minimax: 'MiniMax',
  deepseek: 'DeepSeek',
  newapi: 'NewAPI'
};

export function defaultProviderName(type: ProviderType): string {
  return PROVIDER_TYPE_LABELS[type];
}
