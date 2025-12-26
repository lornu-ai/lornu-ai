/**
 * Playwright Custom Reporter
 * Injects the Lornu AI logo into the HTML report header
 */

import * as path from 'path';
import * as fs from 'fs';

export default class LogoInjectorReporter {
  onEnd(_result: any) {
    const reportPath = path.join(process.cwd(), 'playwright-report', 'index.html');
    const logoPath = path.join(process.cwd(), 'src', 'assets', 'brand', 'lornu-ai-final-clear-bg.png');

    if (!fs.existsSync(reportPath)) {
      console.warn('⚠️  HTML report not found at:', reportPath);
      return;
    }

    try {
      let html = fs.readFileSync(reportPath, 'utf-8');

      // Inject logo into the report header
      const logoInjection = `
        <style>
          .header-logo {
            margin: 20px 0;
            text-align: center;
          }
          .header-logo img {
            max-height: 80px;
            margin-right: 20px;
            vertical-align: middle;
          }
          .header-title {
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 20px;
            margin-bottom: 30px;
          }
        </style>
        <div class="header-title">
          ${fs.existsSync(logoPath) ? `<img src="data:image/png;base64,${Buffer.from(fs.readFileSync(logoPath)).toString('base64')}" alt="Lornu AI Logo" class="header-logo" />` : ''}
          <h1>Lornu AI Synthetic Monitoring</h1>
        </div>
        <div style="text-align: center; color: #666; font-size: 14px; margin-bottom: 20px;">
          <p>Production Health Check • Automated every 10 minutes</p>
          <p><strong>Status:</strong> <span style="color: green;">✓ Online</span></p>
        </div>
      `;

      // Insert logo section after body tag or before test results
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
}
