import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { ArrowLeft } from '@phosphor-icons/react'
import { Logo } from '@/components/Logo'
import SEOHead from '@/components/SEOHead'
import ThemeToggle from '@/components/ThemeToggle'
import SocialLinks from '@/components/SocialLinks'

export default function Privacy() {
  return (
    <>
      <SEOHead
        title="Privacy Policy"
        description="Privacy Policy for LornuAI platform. Learn how we protect and handle your data with our AI-powered enterprise solutions."
        canonical="/privacy"
      />
      <div className="min-h-screen bg-background">
        <nav className="bg-card/80 backdrop-blur-lg shadow-lg sticky top-0 z-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between h-16">
              <Link to="/" className="text-2xl font-bold gradient-text" aria-label="LornuAI home">
                <Logo width={120} height={40} />
              </Link>
              <div className="flex items-center gap-3">
                <Link to="/">
                  <Button variant="ghost" className="gap-2">
                    <ArrowLeft weight="bold" />
                    Back to Home
                  </Button>
                </Link>
                <ThemeToggle />
                <SocialLinks />
              </div>
            </div>
          </div>
        </nav>

        <div className="max-w-4xl mx-auto px-4 py-12">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
          >
            <h1 className="text-4xl lg:text-5xl font-bold mb-4 gradient-text">Privacy Policy</h1>
            <p className="text-muted-foreground mb-8">Last Updated: December 13, 2025</p>

            <Card className="mb-8">
              <CardContent className="pt-6 space-y-8">
                <section>
                  <h2 className="text-2xl font-semibold mb-4">1. Introduction</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    LornuAI Inc. ("we", "our", or "us") is committed to protecting your privacy. This Privacy Policy explains
                    how we collect, use, disclose, and safeguard your information when you use our AI-powered Retrieval-Augmented
                    Generation (RAG) service ("Service").
                  </p>
                  <p className="text-muted-foreground leading-relaxed">
                    Please read this privacy policy carefully. If you do not agree with the terms of this privacy policy,
                    please do not access the Service.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">2. Information We Collect</h2>

                  <h3 className="text-xl font-semibold mb-3 mt-4">2.1 Information You Provide</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    When you use the Service, we collect the following information that you directly provide:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Query Content:</strong> The text prompts, questions, and inputs you submit to our AI models</li>
                    <li><strong>Contact Information:</strong> Name and email address if you submit an inquiry through our contact form</li>
                    <li><strong>Feedback:</strong> Any feedback, comments, or suggestions you provide about the Service</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">2.2 Automatically Collected Information</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    When you access the Service, we automatically collect certain technical information:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>IP Address:</strong> Your device's Internet Protocol (IP) address (collected by Cloudflare AI Gateway)</li>
                    <li><strong>Timestamps:</strong> Date and time of your requests and interactions</li>
                    <li><strong>Browser Information:</strong> Browser type, version, and user agent string</li>
                    <li><strong>Device Information:</strong> Device type, operating system, and screen resolution</li>
                    <li><strong>Usage Patterns:</strong> Pages visited, features used, and interaction frequency</li>
                    <li><strong>Performance Metrics:</strong> Request latency, response times, and error rates</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">2.3 Cookies and Tracking Technologies</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    We use minimal cookies and tracking technologies for essential Service functionality. These are primarily
                    session cookies required for authentication and routing through Cloudflare's infrastructure. We do not use
                    third-party advertising cookies or cross-site tracking.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">3. How We Use Your Information</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We use the collected information for the following purposes:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Service Delivery:</strong> To process your queries through AI models and return generated responses</li>
                    <li><strong>Performance Optimization:</strong> To cache frequently requested content in Cloudflare KV/R2 for faster response times</li>
                    <li><strong>Analytics:</strong> To understand usage patterns and improve Service performance through Cloudflare AI Gateway analytics</li>
                    <li><strong>Security:</strong> To detect, prevent, and respond to security incidents, abuse, and fraudulent activity</li>
                    <li><strong>Service Improvement:</strong> To develop new features and improve existing functionality</li>
                    <li><strong>Communication:</strong> To respond to your inquiries and provide customer support</li>
                    <li><strong>Compliance:</strong> To comply with legal obligations and enforce our Terms of Service</li>
                  </ul>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">4. Data Storage and Retention</h2>

                  <h3 className="text-xl font-semibold mb-3 mt-4">4.1 Cloudflare KV (Key-Value Storage)</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We use Cloudflare KV to cache AI responses for performance optimization:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>What is Stored:</strong> Query hashes (not full query text) and associated AI-generated responses</li>
                    <li><strong>Purpose:</strong> To serve repeated queries faster without re-invoking AI models</li>
                    <li><strong>Retention:</strong> Cached data expires automatically after 7 days of inactivity</li>
                    <li><strong>Location:</strong> Distributed globally across Cloudflare's edge network</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">4.2 Cloudflare R2 (Object Storage)</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We may use Cloudflare R2 for longer-term data storage related to RAG functionality:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>What is Stored:</strong> Indexed document embeddings and metadata (if you upload documents for RAG)</li>
                    <li><strong>Purpose:</strong> To enable retrieval-augmented generation with your custom knowledge base</li>
                    <li><strong>Retention:</strong> Data is retained until you explicitly delete it or terminate your account</li>
                    <li><strong>Location:</strong> Cloudflare's global object storage infrastructure</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">4.3 Logs and Analytics</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    Request logs (IP address, timestamp, query metadata) are retained in Cloudflare AI Gateway for up to 30 days
                    for analytics and security purposes. These logs do not contain full query content, only metadata such as
                    request size, model used, and response time.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">5. Third-Party Data Sharing and Processing</h2>

                  <h3 className="text-xl font-semibold mb-3 mt-4">5.1 AI Model Providers</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    Your queries are processed by third-party AI providers. We explicitly disclose what data is shared:
                  </p>

                  <div className="bg-secondary/20 p-4 rounded-lg mb-4">
                    <h4 className="font-semibold mb-2">Cloudflare Workers AI</h4>
                    <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4 text-sm">
                      <li><strong>Data Shared:</strong> Your query text and selected model parameters</li>
                      <li><strong>Purpose:</strong> AI inference using Llama 2 and other models hosted on Cloudflare's network</li>
                      <li><strong>Retention by Provider:</strong> Cloudflare does not retain query content after processing (per their <a href="https://www.cloudflare.com/trust-hub/privacy-and-data-protection/" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">AI Privacy Policy</a>)</li>
                      <li><strong>Privacy Policy:</strong> <a href="https://www.cloudflare.com/privacypolicy/" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">Cloudflare Privacy Policy</a></li>
                    </ul>
                  </div>

                  <div className="bg-secondary/20 p-4 rounded-lg">
                    <h4 className="font-semibold mb-2">Google Vertex AI (Gemini Models)</h4>
                    <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4 text-sm">
                      <li><strong>Data Shared:</strong> Your query text and model configuration</li>
                      <li><strong>Purpose:</strong> AI inference using Google's Gemini models</li>
                      <li><strong>Retention by Provider:</strong> Google may retain queries for up to 30 days for abuse prevention, then deletes them (per <a href="https://cloud.google.com/terms/service-terms#3" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">Vertex AI terms</a>)</li>
                      <li><strong>Training:</strong> Google does not use your queries to train or improve their models when accessed via Vertex AI API</li>
                      <li><strong>Privacy Policy:</strong> <a href="https://cloud.google.com/terms/cloud-privacy-notice" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">Google Cloud Privacy Notice</a></li>
                    </ul>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-6">5.2 Infrastructure Providers</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    Our Service is hosted entirely on Cloudflare's infrastructure:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Cloudflare Workers:</strong> Serverless compute platform executing all Service logic</li>
                    <li><strong>Cloudflare AI Gateway:</strong> Unified routing, analytics, and caching layer for AI requests</li>
                    <li><strong>Cloudflare KV & R2:</strong> Data storage for caching and RAG functionality</li>
                  </ul>
                  <p className="text-muted-foreground leading-relaxed mt-4">
                    Cloudflare acts as a data processor on our behalf. Their security and privacy practices are detailed in their
                    <a href="https://www.cloudflare.com/trust-hub/" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline ml-1">Trust Hub</a>.
                  </p>

                  <h3 className="text-xl font-semibold mb-3 mt-6">5.3 Analytics Services</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We use Google Analytics to help us understand how our Service is used. Google Analytics collects information sent
                    by your browser as part of a web page request, including cookies and your IP address.
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Purpose:</strong> To analyze user behavior, site performance, and traffic sources</li>
                    <li><strong>Consent:</strong> Google Analytics cookies are only set if you explicitly consent via our cookie banner</li>
                    <li><strong>Opt-out:</strong> You may opt-out of Google Analytics by declining cookies or installing the <a href="https://tools.google.com/dlpage/gaoptout" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">Google Analytics Opt-out Browser Add-on</a></li>
                    <li><strong>Privacy Policy:</strong> <a href="https://policies.google.com/privacy" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline">Google Privacy & Terms</a></li>
                  </ul>
                  <p className="text-muted-foreground leading-relaxed mt-4">
                    We also use internal analytics metrics provided by Cloudflare AI Gateway, which do not rely on tracking cookies.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">6. Data Security</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We implement industry-standard security measures to protect your data:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Encryption in Transit:</strong> All data transmission uses TLS 1.3 encryption</li>
                    <li><strong>Encryption at Rest:</strong> Data stored in Cloudflare KV/R2 is encrypted using AES-256</li>
                    <li><strong>Access Controls:</strong> Strict authentication and authorization for all Service components</li>
                    <li><strong>Secret Management:</strong> API keys and secrets are stored securely using Kubernetes Secrets and environment variables</li>
                    <li><strong>Edge Security:</strong> Cloudflare Workers run in a secure, isolated sandbox environment</li>
                    <li><strong>DDoS Protection:</strong> Cloudflare's network provides protection against distributed denial-of-service attacks</li>
                  </ul>
                  <p className="text-muted-foreground leading-relaxed mt-4">
                    However, no method of transmission over the Internet or electronic storage is 100% secure. While we strive to
                    use commercially acceptable means to protect your data, we cannot guarantee its absolute security.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">7. Your Privacy Rights</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    Depending on your location, you may have the following rights regarding your personal data:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Access:</strong> Request access to the personal data we hold about you</li>
                    <li><strong>Correction:</strong> Request correction of inaccurate or incomplete data</li>
                    <li><strong>Deletion:</strong> Request deletion of your personal data (subject to legal retention requirements)</li>
                    <li><strong>Portability:</strong> Request a copy of your data in a structured, machine-readable format</li>
                    <li><strong>Objection:</strong> Object to processing of your data for specific purposes</li>
                    <li><strong>Restriction:</strong> Request restriction of processing under certain circumstances</li>
                    <li><strong>Withdrawal:</strong> Withdraw consent where processing is based on consent</li>
                  </ul>
                  <p className="text-muted-foreground leading-relaxed mt-4">
                    To exercise these rights, please contact us at privacy@lornu.ai. We will respond to your request within 30 days.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">8. Children's Privacy</h2>
                  <p className="text-muted-foreground leading-relaxed">
                    Our Service is not intended for children under the age of 13. We do not knowingly collect personal information
                    from children under 13. If you become aware that a child has provided us with personal information, please
                    contact us. If we become aware that we have collected personal information from children without verification
                    of parental consent, we will take steps to remove that information from our servers.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">9. International Data Transfers</h2>
                  <p className="text-muted-foreground leading-relaxed">
                    Your information may be processed in countries other than your country of residence. These countries may have
                    data protection laws that are different from the laws of your country. By using the Service, you consent to
                    the transfer of information to the United States and other countries where Cloudflare operates data centers.
                    Cloudflare maintains appropriate safeguards for international data transfers as detailed in their
                    <a href="https://www.cloudflare.com/trust-hub/gdpr/" target="_blank" rel="noopener noreferrer" className="text-accent hover:underline ml-1">GDPR compliance documentation</a>.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">10. Changes to This Privacy Policy</h2>
                  <p className="text-muted-foreground leading-relaxed">
                    We may update this Privacy Policy from time to time. We will notify you of any material changes by posting
                    the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this
                    Privacy Policy periodically for any changes. Changes to this Privacy Policy are effective when they are posted
                    on this page. Your continued use of the Service after any modifications indicates your acceptance of the updated policy.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">11. Contact Us</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    If you have any questions about this Privacy Policy, please contact us:
                  </p>
                  <div className="bg-secondary/20 p-4 rounded-lg">
                    <p className="text-muted-foreground">
                      <strong>LornuAI Inc.</strong><br />
                      Privacy Contact: privacy@lornu.ai<br />
                      Legal Contact: legal@lornu.ai<br />
                      Website: <Link to="/" className="text-accent hover:underline">lornu.ai</Link>
                    </p>
                  </div>
                </section>
              </CardContent>
            </Card>

            <div className="flex justify-center gap-4">
              <Link to="/">
                <Button variant="outline">
                  <ArrowLeft weight="bold" className="mr-2" />
                  Back to Home
                </Button>
              </Link>
              <Link to="/terms">
                <Button variant="default" className="gradient-bg">
                  Read Terms of Service
                </Button>
              </Link>
            </div>
          </motion.div>
        </div>
      </div>
    </>
  )
}
