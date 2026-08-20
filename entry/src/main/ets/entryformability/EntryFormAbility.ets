import FormExtensionAbility from '@ohos.app.form.FormExtensionAbility';
import formBindingData from '@ohos.app.form.formBindingData';
import formProvider from '@ohos.app.form.formProvider';
import Want from '@ohos.app.ability.Want';
import common from '@ohos.app.ability.common';
import { UsageCache } from '../common/store/UsageCache';
import { ProviderStore } from '../common/store/ProviderStore';
import { QuotaService } from '../common/api/QuotaService';

function buildFormData(context: common.Context): formBindingData.FormBindingData {
  const usage = UsageCache.get(context);
  return formBindingData.createFormBindingData({ providers: JSON.stringify(usage) });
}

async function refreshAll(context: common.Context): Promise<void> {
  const providers = await ProviderStore.get(context);
  const usage = await QuotaService.queryAll(providers);
  UsageCache.set(context, usage);
  const ids = UsageCache.getFormIds(context);
  for (const id of ids) {
    try {
      formProvider.updateForm(id, buildFormData(context));
    } catch (e) {
      console.error(`updateForm failed for ${id}: ${e instanceof Error ? e.message : String(e)}`);
    }
  }
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.['ohos.extra.param.key.form_identity'] as string ?? '';
    if (formId) {
      UsageCache.addFormId(this.context, formId);
    }
    return buildFormData(this.context);
  }

  onCastToNormalForm(formId: string): void {
    UsageCache.addFormId(this.context, formId);
  }

  onUpdateForm(formId: string): void {
    refreshAll(this.context);
  }

  onFormEvent(formId: string, message: string): void {
    try {
      const params = JSON.parse(message) as Record<string, string>;
      if (params['msg'] === 'refresh') {
        refreshAll(this.context);
      }
    } catch (e) {
      // 非 JSON message 直接忽略
    }
  }

  onRemoveForm(formId: string): void {
    UsageCache.removeFormId(this.context, formId);
  }
}
