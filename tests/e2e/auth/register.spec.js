import { test, expect } from '@playwright/test';
import {
  MESSAGES,
  ACCOUNT,
  uniqueEmail,
  registerViaApi,
  seedAccount,
  loginViaApi,
  expectNoAccount,
  currentUserStatus
} from './helpers.js';

// UI E2E for spec/features/auth/register.feature.
// Seeding is done through POST /api/auth/register (per the design test plan),
// never through the register UI, except where the register UI is the subject.

async function submitRegister(page, { email, password }) {
  await page.goto('/register');
  if (email !== undefined) {
    await page.getByTestId('register-email').fill(email);
  }
  if (password !== undefined) {
    await page.getByTestId('register-password').fill(password);
  }
  await page.getByTestId('register-submit').click();
}

test.describe('auth / register', () => {
  test('@req:auth#REQ-001 Register with a new email and a valid password', async ({ page }) => {
    const email = uniqueEmail('new');

    await submitRegister(page, { email, password: 'correct-horse' });

    // Confirmation is shown on the login screen: the user is not signed in.
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('login-flash')).toContainText(MESSAGES.registerSuccessFlash);
    await expect(page.getByTestId('logout-button')).toHaveCount(0);
    expect(await currentUserStatus(page), 'registration must not create a session').toBe(401);
  });

  test('@req:auth#REQ-002 Register with an email that already has an account', async ({ page, request }) => {
    const email = uniqueEmail('dup');
    await seedAccount(request, { email, password: ACCOUNT.password });

    await submitRegister(page, { email, password: 'another-pass-123' });

    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.emailTaken);
    // Exactly one account: the original credentials still work...
    expect((await loginViaApi(request, { email, password: ACCOUNT.password })).status()).toBe(200);
    // ...and the second attempt did not overwrite them.
    expect((await loginViaApi(request, { email, password: 'another-pass-123' })).status()).toBe(401);
  });

  test('@req:auth#REQ-003 Register with a malformed email', async ({ page, request }) => {
    const email = 'not-an-email';

    await submitRegister(page, { email, password: 'correct-horse' });

    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.emailInvalid);
    await expectNoAccount(request, { email, password: 'correct-horse' });
  });

  test('@req:auth#REQ-004 Register with a password shorter than 8 characters', async ({ page, request }) => {
    const email = uniqueEmail('short');

    await submitRegister(page, { email, password: 'short7' });

    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.passwordTooShort);
    await expectNoAccount(request, { email, password: 'short7' });
  });

  test('@req:auth#REQ-005 Register without an email', async ({ page }) => {
    await submitRegister(page, { email: '', password: 'correct-horse' });

    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.emailRequired);
  });

  test('@req:auth#REQ-006 Register without a password', async ({ page, request }) => {
    const email = uniqueEmail('nopass');

    await submitRegister(page, { email, password: '' });

    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.passwordRequired);
    await expectNoAccount(request, { email, password: '' });
  });

  test('@req:auth#REQ-007 Register with a different casing of an existing email', async ({ page, request }) => {
    const local = uniqueEmail('case').split('@')[0];
    const stored = `${local}@example.com`;
    const mixed = `${local.toUpperCase()}@Example.com`;
    await seedAccount(request, { email: stored, password: ACCOUNT.password });

    await submitRegister(page, { email: mixed, password: 'another-pass-123' });

    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.emailTaken);
    // Still exactly one account, with the original password.
    expect((await loginViaApi(request, { email: stored, password: ACCOUNT.password })).status()).toBe(200);
    expect((await loginViaApi(request, { email: stored, password: 'another-pass-123' })).status()).toBe(401);
  });

  test('@req:auth#REQ-004 Register with a password of exactly 8 characters', async ({ page, request }) => {
    const email = uniqueEmail('eight');

    await submitRegister(page, { email, password: '12345678' });

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('login-flash')).toContainText(MESSAGES.registerSuccessFlash);
    await expect(page.getByTestId('logout-button')).toHaveCount(0);
    expect(await currentUserStatus(page)).toBe(401);
    // The boundary account is usable.
    expect((await loginViaApi(request, { email, password: '12345678' })).status()).toBe(200);
  });

  test('@req:auth#REQ-003 Register with a whitespace-only email', async ({ page }) => {
    await submitRegister(page, { email: '   ', password: 'correct-horse' });

    // Whitespace-only is invalid, not missing (REQ-003 acceptance criterion).
    await expect(page.getByTestId('register-error')).toContainText(MESSAGES.emailInvalid);
    await expect(page.getByTestId('register-error')).not.toContainText(MESSAGES.emailRequired);
  });

  test('guard (non-scenario): successful registration sets no session cookie', async ({ request }) => {
    // Protects REQ-001 ("not signed in") from a regression.
    const email = uniqueEmail('nocookie');
    const response = await registerViaApi(request, { email, password: ACCOUNT.password });
    expect(response.status()).toBe(201);
    expect(response.headers()['set-cookie']).toBeUndefined();
  });
});
