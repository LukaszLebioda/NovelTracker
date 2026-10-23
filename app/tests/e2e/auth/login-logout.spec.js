import { test, expect } from '@playwright/test';
import {
  MESSAGES,
  ACCOUNT,
  uniqueEmail,
  mixedCaseEmail,
  seedAccount,
  currentUserStatus
} from './helpers.js';

// UI E2E for spec/features/auth/login-logout.feature.

async function submitLogin(page, { email, password }) {
  await page.goto('/login');
  if (email !== undefined) {
    await page.getByTestId('login-email').fill(email);
  }
  if (password !== undefined) {
    await page.getByTestId('login-password').fill(password);
  }
  await page.getByTestId('login-submit').click();
}

test.describe('auth / login and logout', () => {
  test('@req:auth#REQ-008 Log in with the registered email and the correct password', async ({ page, request }) => {
    const email = uniqueEmail('login');
    await seedAccount(request, { email, password: ACCOUNT.password });

    await submitLogin(page, { email, password: ACCOUNT.password });

    await expect(page.getByTestId('logout-button')).toBeVisible();
    expect(await currentUserStatus(page), 'session must be established').toBe(200);
  });

  test('@req:auth#REQ-009 Log in with the wrong password', async ({ page, request }) => {
    const email = uniqueEmail('wrongpw');
    await seedAccount(request, { email, password: ACCOUNT.password });

    await submitLogin(page, { email, password: 'wrong-horse' });

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('login-error')).toContainText(MESSAGES.invalidCredentials);
    await expect(page.getByTestId('logout-button')).toHaveCount(0);
    expect(await currentUserStatus(page)).toBe(401);
  });

  test('@req:auth#REQ-010 Log in with an email that has no account', async ({ page }) => {
    const email = uniqueEmail('ghost');

    await submitLogin(page, { email, password: 'whatever-pass' });

    // Same exact message constant as REQ-009: no hint that the email is unknown.
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('login-error')).toContainText(MESSAGES.invalidCredentials);
    await expect(page.getByTestId('logout-button')).toHaveCount(0);
    expect(await currentUserStatus(page)).toBe(401);
  });

  test('@req:auth#REQ-007 Log in with a differently-cased email and the correct password', async ({ page, request }) => {
    const email = uniqueEmail('caselogin');
    await seedAccount(request, { email, password: ACCOUNT.password });

    await submitLogin(page, { email: mixedCaseEmail(email), password: ACCOUNT.password });

    await expect(page.getByTestId('logout-button')).toBeVisible();
    expect(await currentUserStatus(page)).toBe(200);
  });

  test('@req:auth#REQ-011 Log out of an active session', async ({ page, request }) => {
    const email = uniqueEmail('logout');
    await seedAccount(request, { email, password: ACCOUNT.password });

    // Sign in through the real UI.
    await submitLogin(page, { email, password: ACCOUNT.password });
    await expect(page.getByTestId('logout-button')).toBeVisible();

    await page.getByTestId('logout-button').click();

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('logout-button')).toHaveCount(0);
    expect(await currentUserStatus(page), 'session must really have ended').toBe(401);

    // A protected route now redirects back to the login screen.
    await page.goto('/');
    await expect(page).toHaveURL(/\/login$/);
  });

  test('@req:auth#REQ-012 Log out while already signed out', async ({ page }) => {
    // Fresh context: no session. /logout is the performable trigger for REQ-012.
    await page.goto('/logout');

    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('login-error')).toBeHidden();
    await expect(page.getByTestId('logout-button')).toHaveCount(0);

    // Repeating it is still error-free.
    await page.goto('/logout');
    await expect(page).toHaveURL(/\/login$/);
    await expect(page.getByTestId('login-error')).toBeHidden();
  });
});
