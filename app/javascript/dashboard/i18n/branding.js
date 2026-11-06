// [custom] Replaces hardcoded "Chatwoot" mentions in UI translations with the
// installation name (INSTALLATION_NAME), so the brand is consistent everywhere.
// Placeholders like {latestChatwootVersion} and identifiers like X-Chatwoot-*
// are preserved because only the standalone word is matched.
const BRAND_REGEX = /(?<![\w{-])Chatwoot(?![\w}-])/g;

const replaceDeep = (value, name) => {
  if (typeof value === 'string') return value.replace(BRAND_REGEX, name);
  if (Array.isArray(value)) return value.map(item => replaceDeep(item, name));
  if (value && typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, item]) => [key, replaceDeep(item, name)])
    );
  }
  return value;
};

export const applyBranding = (messages, name) => {
  if (!name || name === 'Chatwoot') return messages;
  return replaceDeep(messages, name);
};

export const brandedMessages = messages =>
  applyBranding(messages, window.globalConfig?.INSTALLATION_NAME);
