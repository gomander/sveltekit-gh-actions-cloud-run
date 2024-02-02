// @ts-check
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  webServer: {
    command: 'npm run build && npm run preview',
    port: 4173
  },
  testDir: 'tests/e2e',
  testMatch: /(.+\.)?(test|spec)\.[jt]s/,
  projects: [
    {
      name: 'Desktop Chromium',
      use: devices['Desktop Chrome']
    },
    {
      name: 'Mobile Safari',
      use: devices['iPhone 12']
    }
  ]
});
