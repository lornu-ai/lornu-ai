import * as path from 'path';
import * as fs from 'fs';

/**
 * Global teardown hook for Playwright
 * Injects the Lornu AI logo into the HTML report after tests complete
 */
async function globalTeardown() {
  try {
    const reportPath = path.join(process.cwd(), 'playwright-report', 'index.html');
    const logoPath = path.join(process.cwd(), 'src', 'assets', 'brand', 'lornu-ai-final-clear-bg.png');

    if (!fs.existsSync(reportPath)) {
      console.warn('⚠️  HTML report not found at:', reportPath);
      return;
    }

    let html = fs.readFileSync(reportPath, 'utf-8');

    // Inject custom header with logo
    const logoBase64 = fs.existsSync(logoPath)
      ? Buffer.from(fs.readFileSync(logoPath)).toString('base64')
      : '';

    const logoInjection = `
      <style>
        .lornu-header {
          background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%);
          color: white;
          padding: 30px;
          text-align: center;
          border-bottom: 3px solid #60a5fa;
          margin: 0;
        }
        .lornu-header-content {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 20px;
          max-width: 1200px;
          margin: 0 auto;
        }
        .lornu-logo {
          max-height: 80px;
          flex-shrink: 0;
        }
        .lornu-title {
          text-align: left;
        }
        .lornu-title h1 {
          margin: 0;
          font-size: 28px;
          font-weight: bold;
        }
        .lornu-title p {
          margin: 8px 0 0 0;
          font-size: 14px;
          opacity: 0.9;
        }
        .lornu-metadata {
          margin-top: 15px;
          font-size: 12px;
          opacity: 0.8;
          border-top: 1px solid rgba(255, 255, 255, 0.2);
          padding-top: 15px;
        }
      </style>
      <div class="lornu-header">
        <div class="lornu-header-content">
          ${logoBase64 ? `<img src="data:image/png;base64,${logoBase64}" alt="Lornu AI" class="lornu-logo" />` : ''}
          <div class="lornu-title">
            <h1>🚀 Lornu AI Synthetic Monitoring</h1>
            <p>Production Health Check • Live Dashboard</p>
            <div class="lornu-metadata">
              Tests run every 10 minutes • Last run: ${new Date().toISOString()} • Powered by Playwright & GitHub Actions
            </div>
          </div>
        </div>
      </div>
    `;

    // Insert after opening body tag
    const bodyMatch = html.match(/<body[^>]*>/i);
    if (bodyMatch) {
      html = html.replace(bodyMatch[0], bodyMatch[0] + logoInjection);
    }

    fs.writeFileSync(reportPath, html);
    console.log('✅ Logo injected into Playwright HTML report');
  } catch (error) {
    console.error('❌ Failed to inject logo into report:', error);
    // Don't fail the entire test run if logo injection fails
  }
}

export default globalTeardown;
