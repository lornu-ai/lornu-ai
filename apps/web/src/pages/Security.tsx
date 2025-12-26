import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { ArrowLeft, ShieldCheck, Lock, Key, Eye, CloudArrowUp } from '@phosphor-icons/react'
import { Logo } from '@/components/Logo'
import SEOHead from '@/components/SEOHead'
import ThemeToggle from '@/components/ThemeToggle'
import SocialLinks from '@/components/SocialLinks'

export default function Security() {
  return (
    <>
      <SEOHead
        title="Security Standards"
        description="Security information for LornuAI platform. Learn about our security practices and how we protect your enterprise data."
        canonical="/security"
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
            <h1 className="text-4xl lg:text-5xl font-bold mb-4 gradient-text">Security Standards</h1>
            <p className="text-muted-foreground mb-8">Last Updated: December 13, 2025</p>

            <Card className="mb-8">
              <CardContent className="pt-6 space-y-8">
                <section>
                  <h2 className="text-2xl font-semibold mb-4">Our Commitment to Security</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    At LornuAI, security is fundamental to everything we do. We are committed to protecting your data and
                    maintaining the highest standards of security across our infrastructure, development practices, and
                    operational procedures.
                  </p>
                  <p className="text-muted-foreground leading-relaxed">
                    This document outlines our security architecture, practices, and policies to provide transparency about
                    how we protect your information when you use our AI-powered RAG service.
                  </p>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <CloudArrowUp size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">1. Infrastructure Security</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">1.1 Distributed Cloud Infrastructure (GKE / EKS)</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    Our Service operates on enterprise-grade managed Kubernetes platforms (Google Kubernetes Engine and Amazon EKS):
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Isolation:</strong> Each service component runs in isolated containers within private namespaces, ensuring strict process and network isolation.</li>
                    <li><strong>Multi-Region Availability:</strong> Deployed across global cloud regions for high availability and low latency.</li>
                    <li><strong>Dynamic Scaling:</strong> Automatic resource adjustment to handle varying loads without performance degradation.</li>
                    <li><strong>DDoS Protection:</strong> Native cloud-provider protection against sophisticated network-level attacks.</li>
                    <li><strong>Cloud Armor / AWS WAF:</strong> Enterprise Web Application Firewalls protecting against common vulnerabilities (SQLi, XSS, etc.).</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">1.2 AI Infrastructure Security</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    All AI inference requests are managed via secure, private endpoints with the following protections:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Private Connectivity:</strong> Direct, internal routing to AI providers (Google Vertex AI, AWS Bedrock) avoiding the public internet.</li>
                    <li><strong>Rate Limiting:</strong> Granular control over request frequency per client and service.</li>
                    <li><strong>Robust Monitoring:</strong> Real-time observability through cloud-native metrics and centralized logging.</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">1.3 Data Storage Security</h3>
                  <div className="bg-secondary/20 p-4 rounded-lg mb-4">
                    <h4 className="font-semibold mb-2 flex items-center gap-2">
                      <Lock size={20} weight="bold" className="text-accent" />
                      Enterprise Database (Firestore / DynamoDB)
                    </h4>
                    <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4 text-sm">
                      <li>Encrypted at rest using industry-standard AES-256</li>
                      <li>Encrypted in transit using TLS 1.3/TLS 1.2</li>
                      <li>High availability with automatic cross-zone replication</li>
                      <li>Access controlled via granular IAM policies</li>
                      <li>Audit logging enabled for all data plane operations</li>
                    </ul>
                  </div>

                  <div className="bg-secondary/20 p-4 rounded-lg">
                    <h4 className="font-semibold mb-2 flex items-center gap-2">
                      <Lock size={20} weight="bold" className="text-accent" />
                      Object Storage (GCS / S3)
                    </h4>
                    <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4 text-sm">
                      <li>Encrypted at rest with provider-managed or customer-managed keys (CMEK)</li>
                      <li>Strict Access Control Lists (ACLs) and Bucket Policies</li>
                      <li>Private bucket access only; no public read/write allowed</li>
                      <li>Data lifecycle management for automated retention and deletion</li>
                      <li>Comprehensive object-level auditing and access tracking</li>
                    </ul>
                  </div>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <Key size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">2. Secret and Credential Management</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">2.1 API Key Storage</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    All sensitive credentials (API keys, tokens, secrets) are managed using industry best practices:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Kubernetes Secrets:</strong> Production secrets are managed via K8s Secret resources and external secret managers (Google Secret Manager / AWS Secrets Manager)</li>
                    <li><strong>GitHub Secrets:</strong> CI/CD pipeline secrets stored securely in GitHub's encrypted secrets storage</li>
                    <li><strong>Environment Variables:</strong> Runtime configurations injected securely into containerized environments</li>
                    <li><strong>No Hardcoding:</strong> Zero tolerance policy for hardcoded credentials in source code</li>
                    <li><strong>Secret Rotation:</strong> Regular rotation schedule for all API keys and access tokens</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">2.2 Access Control</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We implement principle of least privilege across all systems:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Role-Based Access:</strong> Team members have access only to resources required for their role</li>
                    <li><strong>Multi-Factor Authentication:</strong> MFA required for all cloud provider and version control accounts</li>
                    <li><strong>API Scoping:</strong> Third-party API keys are scoped to minimum required permissions</li>
                    <li><strong>Audit Trails:</strong> All access to production secrets is logged and monitored</li>
                  </ul>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <ShieldCheck size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">3. Application Security</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">3.1 Secure Development Practices</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>TypeScript:</strong> Strongly-typed codebase reduces runtime errors and improves security</li>
                    <li><strong>Input Validation:</strong> All user inputs are validated and sanitized before processing</li>
                    <li><strong>Pre-commit Hooks:</strong> Automated security checks run before every commit:
                      <ul className="list-circle list-inside ml-6 mt-1 space-y-1">
                        <li>Private key detection (prevents accidental credential leaks)</li>
                        <li>Environment variable validation (blocks .env file commits)</li>
                        <li>Merge conflict detection</li>
                        <li>YAML syntax validation</li>
                        <li>Large file blocking (prevents binary/secret file commits)</li>
                      </ul>
                    </li>
                    <li><strong>Dependency Management:</strong> Regular updates and security audits of third-party packages</li>
                    <li><strong>Code Review:</strong> All changes require peer review before merging to production branches</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">3.2 Transport Security</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>TLS 1.3:</strong> All data in transit is encrypted using the latest TLS protocol</li>
                    <li><strong>HTTPS Only:</strong> No support for insecure HTTP connections</li>
                    <li><strong>HSTS:</strong> HTTP Strict Transport Security headers enforce secure connections</li>
                    <li><strong>Certificate Management:</strong> Automatic certificate provisioning and renewal using Cert-Manager and Cloud DNS / Route53</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">3.3 API Security</h3>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Rate Limiting:</strong> Per-IP and per-user rate limits prevent abuse</li>
                    <li><strong>Request Size Limits:</strong> Maximum payload sizes enforced to prevent resource exhaustion</li>
                    <li><strong>CORS Policies:</strong> Strict Cross-Origin Resource Sharing policies</li>
                    <li><strong>Error Handling:</strong> Generic error messages prevent information leakage</li>
                  </ul>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <Eye size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">4. Data Privacy and Retention</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">4.1 Data Minimization</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We collect and retain only the minimum data necessary to provide the Service:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>No PII Collection:</strong> We do not collect names, addresses, phone numbers, or other personal identifiers unless explicitly provided (e.g., contact form)</li>
                    <li><strong>Query Hashing:</strong> Full query text is not stored; only cryptographic hashes for cache keys</li>
                    <li><strong>Minimal Logging:</strong> Logs contain only metadata (timestamp, model, latency) not query content</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">4.2 Data Retention Policy</h3>
                  <div className="bg-secondary/20 p-4 rounded-lg">
                    <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4 text-sm">
                      <li><strong>KV Cache:</strong> Automatic expiration after 7 days of inactivity</li>
                      <li><strong>R2 Storage:</strong> User-controlled retention; data deleted upon request</li>
                      <li><strong>Request Logs:</strong> 30-day retention for analytics and security, then purged</li>
                      <li><strong>Third-Party Processing:</strong> Google Vertex AI and AWS Bedrock process queries in real-time with enterprise-grade privacy (see <Link to="/privacy" className="text-accent hover:underline">Privacy Policy</Link>)</li>
                    </ul>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-6">4.3 Data Deletion</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    Users can request deletion of their data at any time by contacting privacy@lornu.ai. We will delete all
                    personal data within 30 days of a verified deletion request, except where retention is required by law.
                  </p>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <ShieldCheck size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">5. Third-Party Security</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">5.1 Vendor Security Assessment</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We carefully vet all third-party services used in our platform:
                  </p>

                  <div className="bg-secondary/20 p-4 rounded-lg mb-4">
                    <h4 className="font-semibold mb-2">Google Cloud (GCP)</h4>
                    <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4 text-sm">
                      <li>SOC 1, 2, and 3 compliant</li>
                      <li>ISO/IEC 27001, 27017, 27018 certified</li>
                      <li>PCI DSS and HIPAA compliant</li>
                      <li>Enterprise-grade SLAs for uptime and security</li>
                      <li>Advanced threat detection and identity management (IAM)</li>
                    </ul>
                  </div>

                  <div className="bg-secondary/20 p-4 rounded-lg">
                    <h4 className="font-semibold mb-2">Amazon Web Services (AWS)</h4>
                    <ul className="list-disc list-inside text-muted-foreground space-y-1 ml-4 text-sm">
                      <li>SOC 1, 2, and 3 certified</li>
                      <li>ISO/IEC 27001, 27017, 27018 certified</li>
                      <li>FedRAMP High Authorization</li>
                      <li>GDPR, HIPAA, and PCI DSS Level 1 compliant</li>
                      <li>Data-at-rest and data-in-transit encryption by default</li>
                    </ul>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-6">5.2 Data Processing Agreements</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    We maintain Data Processing Agreements (DPAs) with all third-party processors to ensure they meet our
                    security and privacy standards. These agreements include provisions for data security, breach notification,
                    and compliance with applicable data protection regulations.
                  </p>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <ShieldCheck size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">6. Incident Response</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">6.1 Security Monitoring</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We continuously monitor our systems for security threats:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Real-Time Alerts:</strong> Automated alerting for anomalous behavior and potential threats</li>
                    <li><strong>Log Analysis:</strong> Centralized logging with automated analysis for security events</li>
                    <li><strong>Performance Monitoring:</strong> Real-time APM (Application Performance Monitoring) and distributed tracing</li>
                    <li><strong>Dependency Scanning:</strong> Automated scanning for vulnerable dependencies in our codebase</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">6.2 Incident Response Plan</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    In the event of a security incident, we follow a structured response process:
                  </p>
                  <ol className="list-decimal list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Detection:</strong> Identify and verify the security incident</li>
                    <li><strong>Containment:</strong> Isolate affected systems to prevent spread</li>
                    <li><strong>Investigation:</strong> Determine scope, cause, and impact of the incident</li>
                    <li><strong>Remediation:</strong> Address vulnerabilities and restore normal operations</li>
                    <li><strong>Notification:</strong> Notify affected users within 72 hours if personal data is compromised</li>
                    <li><strong>Post-Mortem:</strong> Document lessons learned and implement preventive measures</li>
                  </ol>

                  <h3 className="text-xl font-semibold mb-3 mt-6">6.3 Breach Notification</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    In the unlikely event of a data breach affecting personal information, we will notify affected users and
                    relevant authorities as required by applicable law (e.g., GDPR, CCPA). Notifications will include details
                    about the nature of the breach, data affected, and steps being taken to address the incident.
                  </p>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <ShieldCheck size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">7. Compliance and Certifications</h2>
                  </div>

                  <h3 className="text-xl font-semibold mb-3 mt-4">7.1 Regulatory Compliance</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    LornuAI is committed to compliance with applicable data protection and privacy regulations:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>GDPR:</strong> General Data Protection Regulation (EU)</li>
                    <li><strong>CCPA:</strong> California Consumer Privacy Act (US)</li>
                    <li><strong>SOC 2:</strong> Service Organization Control 2 (via Cloudflare infrastructure)</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">7.2 Security Audits</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    We conduct regular security assessments and audits of our platform, including vulnerability scanning,
                    penetration testing, and code security reviews. While LornuAI is an early-stage company, we leverage the
                    security certifications and audits of our infrastructure providers (Google Cloud, AWS) to ensure
                    enterprise-grade security.
                  </p>
                </section>

                <Separator />

                <section>
                  <div className="flex items-center gap-3 mb-4">
                    <ShieldCheck size={32} weight="duotone" className="text-accent" />
                    <h2 className="text-2xl font-semibold">8. Reporting Security Issues</h2>
                  </div>

                  <p className="text-muted-foreground leading-relaxed mb-4">
                    We take security vulnerabilities seriously and appreciate responsible disclosure from the security community.
                  </p>

                  <h3 className="text-xl font-semibold mb-3 mt-4">8.1 Responsible Disclosure</h3>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    If you discover a security vulnerability in our Service, please report it to us responsibly:
                  </p>
                  <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                    <li><strong>Email:</strong> security@lornu.ai (PGP key available upon request)</li>
                    <li><strong>Scope:</strong> lornu.ai domain and all subdomains</li>
                    <li><strong>Response Time:</strong> We aim to acknowledge reports within 48 hours</li>
                    <li><strong>Confidentiality:</strong> Please do not disclose vulnerabilities publicly until we have addressed them</li>
                  </ul>

                  <h3 className="text-xl font-semibold mb-3 mt-6">8.2 Bug Bounty Program</h3>
                  <p className="text-muted-foreground leading-relaxed">
                    We do not currently have a formal bug bounty program but may offer recognition or compensation for
                    significant vulnerability disclosures on a case-by-case basis.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">9. Security Updates</h2>
                  <p className="text-muted-foreground leading-relaxed">
                    This Security Standards document is reviewed and updated regularly to reflect changes in our security
                    practices, infrastructure, and threat landscape. Material changes will be communicated via our website
                    and email notifications to registered users.
                  </p>
                </section>

                <Separator />

                <section>
                  <h2 className="text-2xl font-semibold mb-4">10. Contact Us</h2>
                  <p className="text-muted-foreground leading-relaxed mb-4">
                    For security-related inquiries, please contact:
                  </p>
                  <div className="bg-secondary/20 p-4 rounded-lg">
                    <p className="text-muted-foreground">
                      <strong>LornuAI Inc.</strong><br />
                      Security Team: security@lornu.ai<br />
                      Privacy Contact: privacy@lornu.ai<br />
                      General Inquiries: <a href="mailto:contact@lornu.ai" className="text-accent hover:underline">contact@lornu.ai</a>
                    </p>
                  </div>
                </section>
              </CardContent>
            </Card>

            <div className="flex justify-center gap-4 flex-wrap">
              <Link to="/">
                <Button variant="outline">
                  <ArrowLeft weight="bold" className="mr-2" />
                  Back to Home
                </Button>
              </Link>
              <Link to="/privacy">
                <Button variant="default">
                  Privacy Policy
                </Button>
              </Link>
              <Link to="/terms">
                <Button variant="default">
                  Terms of Service
                </Button>
              </Link>
            </div>
          </motion.div>
        </div>
      </div>
    </>
  )
}
