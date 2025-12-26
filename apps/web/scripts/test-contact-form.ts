#!/usr/bin/env bun
/**
 * Test script for contact form email functionality
 *
 * This script helps debug contact form email issues by:
 * 1. Testing the local/production API endpoint
 * 2. Testing Resend API directly
 * 3. Checking configuration
 *
 * Usage:
 *   bun run scripts/test-contact-form.ts [--local|--production] [--resend-only]
 */

type TestDetails =
  | { emailId: string; status: string }
  | { rateLimitRemaining: string | null; [key: string]: unknown }
  | { stderr: string }
  | { output: string[] }
  | Record<string, unknown>;

interface TestResult {
  name: string;
  success: boolean;
  error?: string;
  details?: TestDetails;
}

const results: TestResult[] = [];

function logResult(result: TestResult) {
  results.push(result);
  const icon = result.success ? '✅' : '❌';
  console.log(`${icon} ${result.name}`);
  if (result.error) {
    console.log(`   Error: ${result.error}`);
  }
  if (result.details) {
    console.log(`   Details:`, JSON.stringify(result.details, null, 2));
  }
}

async function testResendAPI(apiKey: string): Promise<TestResult> {
  try {
    const testEmail = {
      from: 'LornuAI Contact Form <noreply@lornu.ai>',
      to: ['contact@lornu.ai'],
      subject: 'Test Email from Contact Form Script',
      html: '<p>This is a test email from the contact form test script.</p>',
      text: 'This is a test email from the contact form test script.',
    };

    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey}`,
      },
      body: JSON.stringify(testEmail),
    });

    const data = await response.json();

    if (!response.ok) {
      return {
        name: 'Resend API Direct Test',
        success: false,
        error: `HTTP ${response.status}: ${data.message || response.statusText}`,
        details: data,
      };
    }

    return {
      name: 'Resend API Direct Test',
      success: true,
      details: {
        emailId: data.id,
        status: 'sent',
      },
    };
  } catch (error) {
    return {
      name: 'Resend API Direct Test',
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function testContactAPI(baseUrl: string): Promise<TestResult> {
  try {
    const testData = {
      name: 'Test User',
      email: 'test@example.com',
      message: 'This is a test message from the contact form test script.',
    };

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    // Optional CI bypass headers to avoid rate limiting and real email sends
    if (process.env.RATE_LIMIT_BYPASS_SECRET) {
      headers['X-Bypass-Rate-Limit'] = process.env.RATE_LIMIT_BYPASS_SECRET;
    }
    if (process.env.EMAIL_BYPASS_SECRET) {
      headers['X-Bypass-Email'] = process.env.EMAIL_BYPASS_SECRET;
    }

    const response = await fetch(`${baseUrl}/api/contact`, {
      method: 'POST',
      headers,
      body: JSON.stringify(testData),
    });

    const data = await response.json();
    const rateLimitRemaining = response.headers.get('X-RateLimit-Remaining');

    if (!response.ok) {
      return {
        name: `Contact API Test (${baseUrl})`,
        success: false,
        error: `HTTP ${response.status}: ${data.error || response.statusText}`,
        details: {
          ...data,
          rateLimitRemaining,
        },
      };
    }

    return {
      name: `Contact API Test (${baseUrl})`,
      success: true,
      details: {
        ...data,
        rateLimitRemaining,
      },
    };
  } catch (error) {
    return {
      name: `Contact API Test (${baseUrl})`,
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    };
  }
}

async function checkEnvironmentVariables(): Promise<TestResult> {
  try {
    const resendApiKey = process.env.RESEND_API_KEY;
    const contactEmail = process.env.CONTACT_EMAIL;

    const hasResendKey = !!resendApiKey;
    const hasContactEmail = !!contactEmail;

    return {
      name: 'Environment Variables Check',
      success: hasResendKey && hasContactEmail,
      error:
        !hasResendKey || !hasContactEmail
          ? `Missing: ${!hasResendKey ? 'RESEND_API_KEY' : ''} ${!hasContactEmail ? 'CONTACT_EMAIL' : ''}`
          : undefined,
      details: {
        RESEND_API_KEY: hasResendKey ? '***set***' : 'not set',
        CONTACT_EMAIL: hasContactEmail ? contactEmail : 'not set',
      },
    };
  } catch (error) {
    return {
      name: 'Environment Variables Check',
      success: false,
      error: error instanceof Error ? error.message : 'Failed to check secrets',
    };
  }
}

async function main() {
  console.log('🧪 Contact Form Test Script\n');
  console.log('This script will test your contact form email functionality.\n');

  const args = process.argv.slice(2);
  const isLocal = args.includes('--local');
  const isProduction = args.includes('--production');
  const resendOnly = args.includes('--resend-only');

  // Check for required environment variables
  const resendApiKey = process.env.RESEND_API_KEY;

  if (!resendApiKey) {
    console.log('⚠️  RESEND_API_KEY environment variable not set.');
    console.log('   Checking environment variables...\n');

    const secretCheck = await checkEnvironmentVariables();
    logResult(secretCheck);

    if (!secretCheck.success) {
      console.log('\n❌ Cannot proceed without environment variables.');
      console.log('   Please set RESEND_API_KEY and CONTACT_EMAIL environment variables:\n');
      console.log('   export RESEND_API_KEY="your-api-key"');
      console.log('   export CONTACT_EMAIL="contact@example.com"\n');
      process.exit(1);
    }
  }

  // Test Resend API directly
  if (resendApiKey) {
    console.log('\n📧 Testing Resend API directly...\n');
    const resendTest = await testResendAPI(resendApiKey);
    logResult(resendTest);
  } else {
    console.log('\n⚠️  Skipping Resend API test (no API key provided)\n');
  }

  if (resendOnly) {
    console.log('\n✅ Resend-only test complete.\n');
    printSummary();
    return;
  }

  // Test contact API endpoints
  console.log('\n🌐 Testing Contact API endpoints...\n');

  if (isLocal || (!isLocal && !isProduction)) {
    const localTest = await testContactAPI('http://localhost:5173');
    logResult(localTest);
  }

  if (isProduction || (!isLocal && !isProduction)) {
    const prodBase = process.env.PLAYWRIGHT_BASE_URL || 'https://lornu.ai';
    const prodTest = await testContactAPI(prodBase);
    logResult(prodTest);
  }

  printSummary();
}

function printSummary() {
  console.log('\n' + '='.repeat(50));
  console.log('📊 Test Summary');
  console.log('='.repeat(50));

  const passed = results.filter(r => r.success).length;
  const failed = results.filter(r => !r.success).length;

  console.log(`✅ Passed: ${passed}`);
  console.log(`❌ Failed: ${failed}`);
  console.log(`📝 Total:  ${results.length}`);

  if (failed > 0) {
    console.log('\n🔍 Troubleshooting Tips:');
    console.log('1. Verify domain is verified in Resend dashboard');
    console.log('2. Check Resend API key has correct permissions');
    console.log('3. Check Cloudflare Worker logs for errors');
    console.log('4. Ensure RESEND_API_KEY secret is set in Wrangler');
    console.log('5. Test Resend API directly with curl (see CONTACT_FORM_SETUP.md)');
  }

  console.log('\n');
}

main().catch(console.error);
