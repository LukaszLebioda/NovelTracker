import { expect } from '@playwright/test';

// API origin. The client (`baseURL`) and the API are separate processes in dev;
// override the API origin with API_BASE_URL when they are not on localhost:3000.
export const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000';

// Verbatim user-facing strings from the design docs (the contract). UI tests
// assert these exact sentences so wording drift is caught. The two login failure
// scenarios deliberately import the same constant (anti-enumeration, REQ-009/010).
export const MESSAGES = {
  registerSuccessFlash: 'Account created. Please log in.',
  emailRequired: 'The email is required.',
  emailInvalid: 'The email address is not valid.',
  passwordRequired: 'The password is required.',
  passwordTooShort: 'The password must be at least 8 characters long.',
  emailTaken: 'The email is already registered.',
  invalidCredentials: 'The email or password is invalid.',
  unauthenticated: 'You are not signed in.'
};

export const ACCOUNT = {
  email: 'reader@example.com',
  password: 'correct-horse'
};

let seq = 0;

// Unique emails keep the parallel suite independent without needing a DB reset
// between tests; the scenarios only require specific spellings where the string
// itself is the subject (malformed / whitespace) or where casing must collide.
export function uniqueEmail(prefix = 'reader') {
  seq += 1;
  return `${prefix}-${Date.now()}-${process.pid}-${seq}@example.com`;
}

// Capitalize the local part (leaf) so the mixed-case spelling differs from the
// stored lowercase form while still referring to the same account (REQ-007).
export function mixedCaseEmail(email) {
  const [local, domain] = email.split('@');
  return `${local.toUpperCase()}@${domain}`;
}

export async function registerViaApi(request, { email, password }) {
  return request.post(`${API_BASE_URL}/api/auth/register`, {
    data: { email, password }
  });
}

export async function seedAccount(request, { email = ACCOUNT.email, password = ACCOUNT.password } = {}) {
  const response = await registerViaApi(request, { email, password });
  expect(response.status(), `seed account ${email} must be created (201)`).toBe(201);
  return { email, password };
}

export async function loginViaApi(request, { email, password }) {
  return request.post(`${API_BASE_URL}/api/auth/login`, {
    data: { email, password }
  });
}

// "No account was created" probe: a fresh login for those credentials must fail.
export async function expectNoAccount(request, { email, password }) {
  const response = await loginViaApi(request, { email, password });
  expect(response.status(), 'no account should exist for these credentials').toBe(401);
}

// Reads the current session through the browser context's cookies (shares the
// cookie jar with the page, so it reflects what the user is actually signed in as).
export async function currentUserStatus(page) {
  const response = await page.request.get(`${API_BASE_URL}/api/auth/me`);
  return response.status();
}
