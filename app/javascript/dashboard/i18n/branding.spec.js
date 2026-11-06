import { applyBranding } from './branding';

describe('applyBranding', () => {
  it('replaces standalone brand mentions recursively', () => {
    const messages = { en: { LOGIN: { TITLE: 'Login to Chatwoot' }, L: ['Chatwoot!'] } };
    expect(applyBranding(messages, 'Smartlub Chat')).toEqual({
      en: { LOGIN: { TITLE: 'Login to Smartlub Chat' }, L: ['Smartlub Chat!'] },
    });
  });

  it('keeps placeholders and identifiers intact', () => {
    const text = 'Update {latestChatwootVersion} X-Chatwoot-Version';
    expect(applyBranding({ a: text }, 'Smartlub Chat')).toEqual({ a: text });
  });

  it('is a no-op for the default name', () => {
    const messages = { a: 'Chatwoot' };
    expect(applyBranding(messages, 'Chatwoot')).toBe(messages);
  });
});
