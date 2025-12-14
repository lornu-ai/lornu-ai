import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Separator } from '@/components/ui/separator'
import { ArrowLeft } from '@phosphor-icons/react'
import { Logo } from '@/components/Logo'
import SEOHead from '@/components/SEOHead'

export default function Terms() {
  return (
    <>
      <SEOHead
        title="Terms of Service - LornuAI"
        description="Terms of Service for LornuAI platform. Read our terms and conditions for using our AI-powered enterprise solutions."
        canonical="/terms"
      />
      <div className="min-h-screen bg-background">
      <nav className="bg-card/80 backdrop-blur-lg shadow-lg sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <Link to="/" className="text-2xl font-bold gradient-text" aria-label="LornuAI home">
              <Logo width={120} height={40} />
            </Link>
            <Link to="/">
              <Button variant="ghost" className="gap-2">
                <ArrowLeft weight="bold" />
                Back to Home
              </Button>
            </Link>
          </div>
        </div>
      </nav>

      <div className="max-w-4xl mx-auto px-4 py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <h1 className="text-4xl lg:text-5xl font-bold mb-4 gradient-text">Terms of Service</h1>
          <p className="text-muted-foreground mb-8">Last Updated: December 13, 2025</p>

          <Card className="mb-8">
            <CardContent className="pt-6 space-y-8">
              <section>
                <h2 className="text-2xl font-semibold mb-4">1. Acceptance of Terms</h2>
                <p className="text-muted-foreground leading-relaxed">
                  By accessing or using LornuAI's services ("Service"), you agree to be bound by these Terms of Service
                  ("Terms"). If you disagree with any part of the terms, you may not access the Service. These Terms apply
                  to all visitors, users, and others who access or use the Service.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">2. Description of Service</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  LornuAI provides an AI-powered Retrieval-Augmented Generation (RAG) platform that enables users to
                  interact with artificial intelligence models for information retrieval, content generation, and data analysis.
                  Our Service utilizes multiple AI providers including:
                </p>
                <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                  <li>Cloudflare Workers AI (Llama models)</li>
                  <li>Google Vertex AI (Gemini models)</li>
                </ul>
                <p className="text-muted-foreground leading-relaxed mt-4">
                  All AI inference requests are routed through Cloudflare AI Gateway for analytics, caching, and optimization.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">3. Acceptable Use Policy</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">You agree not to use the Service to:</p>
                <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                  <li>Violate any applicable local, state, national, or international law</li>
                  <li>Generate content that is unlawful, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, or otherwise objectionable</li>
                  <li>Impersonate any person or entity, or falsely state or otherwise misrepresent your affiliation with a person or entity</li>
                  <li>Attempt to gain unauthorized access to the Service, other accounts, computer systems, or networks</li>
                  <li>Interfere with or disrupt the Service or servers or networks connected to the Service</li>
                  <li>Use the Service to generate spam, phishing attempts, or malicious content</li>
                  <li>Scrape, data mine, or use automated tools to access the Service without authorization</li>
                  <li>Bypass any rate limiting, authentication, or security measures</li>
                </ul>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">4. Intellectual Property Rights</h2>

                <h3 className="text-xl font-semibold mb-3 mt-4">4.1 Service Content</h3>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  The Service and its original content (excluding user-generated content and AI outputs), features, and
                  functionality are and will remain the exclusive property of LornuAI Inc. and its licensors. The Service
                  is protected by copyright, trademark, and other laws of both the United States and foreign countries.
                </p>

                <h3 className="text-xl font-semibold mb-3 mt-4">4.2 AI-Generated Content</h3>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  Content generated by AI models through the Service ("AI Outputs") is provided to you under the following terms:
                </p>
                <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                  <li>You retain ownership of your input prompts and queries</li>
                  <li>AI Outputs are provided "as-is" and may be subject to the terms of the underlying AI model providers (Cloudflare, Google)</li>
                  <li>You are responsible for reviewing and verifying the accuracy of AI Outputs before use</li>
                  <li>LornuAI makes no claim of ownership to AI Outputs but reserves the right to use anonymized interactions for service improvement</li>
                  <li>You grant LornuAI a license to process and cache AI Outputs as necessary to provide the Service</li>
                </ul>

                <h3 className="text-xl font-semibold mb-3 mt-4">4.3 User Responsibilities</h3>
                <p className="text-muted-foreground leading-relaxed">
                  You are solely responsible for ensuring that your use of AI Outputs complies with applicable laws,
                  including but not limited to copyright, trademark, and data protection regulations. LornuAI is not
                  responsible for any claims arising from your use of AI Outputs.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">5. Service Availability and Modifications</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  We reserve the right to withdraw or amend our Service, and any service or material we provide via the Service,
                  in our sole discretion without notice. We will not be liable if for any reason all or any part of the Service
                  is unavailable at any time or for any period.
                </p>
                <p className="text-muted-foreground leading-relaxed">
                  From time to time, we may restrict access to some parts of the Service, or the entire Service, to users,
                  including registered users. The Service is provided through third-party infrastructure (Cloudflare Workers,
                  Google Vertex AI) and may be subject to downtime or performance issues beyond our control.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">6. Limitation of Liability</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL LORNUAI INC., ITS AFFILIATES,
                  DIRECTORS, EMPLOYEES, OR AGENTS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR
                  PUNITIVE DAMAGES, INCLUDING WITHOUT LIMITATION, LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE
                  LOSSES, RESULTING FROM:
                </p>
                <ul className="list-disc list-inside text-muted-foreground space-y-2 ml-4">
                  <li>Your access to or use of or inability to access or use the Service</li>
                  <li>Any conduct or content of any third party on the Service, including AI model providers</li>
                  <li>Any AI-generated content or outputs provided through the Service</li>
                  <li>Unauthorized access, use, or alteration of your transmissions or content</li>
                  <li>Any bugs, viruses, or harmful code transmitted through the Service</li>
                </ul>
                <p className="text-muted-foreground leading-relaxed mt-4">
                  WHETHER BASED ON WARRANTY, CONTRACT, TORT (INCLUDING NEGLIGENCE), OR ANY OTHER LEGAL THEORY, WHETHER OR
                  NOT WE HAVE BEEN INFORMED OF THE POSSIBILITY OF SUCH DAMAGE.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">7. Disclaimer of Warranties</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  THE SERVICE IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS. LORNUAI INC. EXPRESSLY DISCLAIMS ALL
                  WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
                  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NON-INFRINGEMENT.
                </p>
                <p className="text-muted-foreground leading-relaxed">
                  We make no warranty that the Service will meet your requirements, be available on an uninterrupted, timely,
                  secure, or error-free basis, or that AI-generated content will be accurate, reliable, complete, or current.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">8. Indemnification</h2>
                <p className="text-muted-foreground leading-relaxed">
                  You agree to defend, indemnify, and hold harmless LornuAI Inc., its affiliates, licensors, and service providers,
                  and its and their respective officers, directors, employees, contractors, agents, licensors, suppliers, successors,
                  and assigns from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses, or fees
                  (including reasonable attorneys' fees) arising out of or relating to your violation of these Terms or your use of
                  the Service, including, but not limited to, your use of AI-generated content.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">9. Termination</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  We may terminate or suspend your access to the Service immediately, without prior notice or liability, for any
                  reason whatsoever, including without limitation if you breach the Terms. Upon termination, your right to use
                  the Service will immediately cease.
                </p>
                <p className="text-muted-foreground leading-relaxed">
                  All provisions of the Terms which by their nature should survive termination shall survive termination, including,
                  without limitation, ownership provisions, warranty disclaimers, indemnity, and limitations of liability.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">10. Governing Law</h2>
                <p className="text-muted-foreground leading-relaxed">
                  These Terms shall be governed and construed in accordance with the laws of the State of Delaware, United States,
                  without regard to its conflict of law provisions. Our failure to enforce any right or provision of these Terms
                  will not be considered a waiver of those rights.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">11. Changes to Terms</h2>
                <p className="text-muted-foreground leading-relaxed">
                  We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is
                  material, we will try to provide at least 30 days' notice prior to any new terms taking effect. What constitutes
                  a material change will be determined at our sole discretion. By continuing to access or use our Service after
                  those revisions become effective, you agree to be bound by the revised terms.
                </p>
              </section>

              <Separator />

              <section>
                <h2 className="text-2xl font-semibold mb-4">12. Contact Information</h2>
                <p className="text-muted-foreground leading-relaxed mb-4">
                  If you have any questions about these Terms, please contact us:
                </p>
                <div className="bg-secondary/20 p-4 rounded-lg">
                  <p className="text-muted-foreground">
                    <strong>LornuAI Inc.</strong><br />
                    Email: legal@lornu.ai<br />
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
            <Link to="/privacy">
              <Button variant="default" className="gradient-bg">
                Read Privacy Policy
              </Button>
            </Link>
          </div>
        </motion.div>
      </div>
    </div>
    </>
  )
}
