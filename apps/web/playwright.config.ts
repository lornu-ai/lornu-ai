import { defineConfig, devices } from '@playwright/test';
import * as path from 'path';
import * as fs from 'fs';

/**
 * Playwright configuration for E2E tests
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './tests/e2e',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  /* Opt out of parallel tests on CI. */
  workers: process.env.CI ? 1 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: [
    ['html', {
      outputFolder: 'playwright-report',
      open: 'never',
    }],
    ['json', { outputFile: 'test-results/results.json' }],
  ],
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:5174',
    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
    /* Screenshot on failure */
    screenshot: 'only-on-failure',
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  /* Run your local dev server before starting the tests */
  webServer: {
    command: 'bun run dev',
    url: 'http://localhost:5174',
    reuseExistingServer: !process.env.CI,
    timeout: 120 * 1000,
  },

  /* Inject logo into HTML report after tests complete */
  globalTeardown: path.join(__dirname, 'playwright-global-teardown.ts'),
});

// Export setup function for logo injection
export async function injectLogoIntoReport() {
  try {
    const reportPath = path.join(process.cwd(), 'playwright-report', 'index.html');
    const logoPath = path.join(process.cwd(), 'src', 'assets', 'brand', 'lornu-ai-final-clear-bg.png');

    if (!fs.existsSync(reportPath)) {
      console.warn('⚠️  HTML report not found');
      return;
    }

    let html = fs.readFileSync(reportPath, 'utf-8');

    // Inject custom header with logo before the main content
    const logoInjection = `
      <style>
        .lornu-header {
          background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
          color: white;
          padding: 30px;
          text-align: center;
          border-bottom: 3px solid #60a5fa;
        }
        .lornu-header-content {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 20px;
        }
        .lornu-logo {
          max-height: 80px;
        }
        .lornu-title h1 {
          margin: 0;
          font-size: 28px;
        }
        .lornu-title p {
          margin: 8px 0 0 0;
          font-size: 14px;
          opacity: 0.9;
        }
      </style>
      <div class="lornu-header">
        <div class="lornu-header-content">
          ${fs.existsSync(logoPath) ? `<img src="data:image/png;base64,${Buffer.from(fs.readFileSync(logoPath)).toString('base64')}" alt="Lornu AI" class="lornu-logo" />` : ''}
          <div class="lornu-title">
            <h1>🚀 Lornu AI Synthetic Monitoring</h1>
            <p>Production Health Check • Live Dashboard</p>
            <p>Tests run every 10 minutes | Last run: ${new Date().toISOString()}</p>
          </div>
        </div>
      </div>
    `;

    const bodyMatch = html.match(/<body[^>]*>/i);
    if (bodyMatch) {
      html = html.replace(bodyMatch[0], bodyMatch[0] + logoInjection);
    }

    fs.writeFileSync(reportPath, html);
    console.log('✅ Logo injected into Playwright report');
  } catch (error) {
    console.error('❌ Failed to inject logo:', error);
  }
}
