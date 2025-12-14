import { useState, useEffect } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { toast } from 'sonner'
import { Link } from 'react-router-dom'
import { Logo } from '@/components/Logo'
import SEOHead from '@/components/SEOHead'
import {
  Lightning,
  Code,
  Rocket,
  ChartLine,
  Users,
  Envelope,
  ArrowRight,
  Check
} from '@phosphor-icons/react'

export default function Home() {
  const [activeSection, setActiveSection] = useState('home')
  const [isScrolled, setIsScrolled] = useState(false)
  const { scrollYProgress } = useScroll()
  const opacity = useTransform(scrollYProgress, [0, 0.2], [1, 0])
  const scale = useTransform(scrollYProgress, [0, 0.2], [1, 0.8])

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 50)

      const sections = ['home', 'services', 'about', 'contact']
      const current = sections.find(section => {
        const element = document.getElementById(section)
        if (element) {
          const rect = element.getBoundingClientRect()
          return rect.top <= 100 && rect.bottom >= 100
        }
        return false
      })

      if (current) setActiveSection(current)
    }

    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const scrollToSection = (id: string) => {
    const element = document.getElementById(id)
    if (element) {
      element.scrollIntoView({ behavior: 'smooth' })
    }
  }

  const [isSubmitting, setIsSubmitting] = useState(false)

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const form = e.currentTarget
    const formData = new FormData(form)
    const name = formData.get('name') as string
    const email = formData.get('email') as string
    const message = formData.get('message') as string

    if (!name || !email || !message) {
      toast.error('Please fill in all fields')
      return
    }

    setIsSubmitting(true)

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name, email, message }),
      })

      let data: { error?: string } | null = null
      const responseText = await response.text()

      try {
        data = JSON.parse(responseText)
      } catch {
        data = { error: responseText || 'Failed to parse error response' }
      }

      if (!response.ok) {
        throw new Error(data?.error || 'Failed to send message')
      }

      toast.success('Message sent! We\'ll be in touch soon.')
      // Reset the form after successful submission
      form.reset()
    } catch (error) {
      console.error('Error submitting form:', error)
      toast.error(error instanceof Error ? error.message : 'Failed to send message. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  const services = [
    {
      icon: Lightning,
      title: 'Digital Acceleration',
      description: 'Transform your business with cutting-edge AI and automation solutions that deliver results fast.'
    },
    {
      icon: Code,
      title: 'Custom Development',
      description: 'Tailored software solutions built with modern technologies to meet your unique business needs.'
    },
    {
      icon: ChartLine,
      title: 'Data Analytics',
      description: 'Turn your data into actionable insights with advanced analytics and visualization platforms.'
    }
  ]

  const features = [
    'AI-Powered Solutions',
    'Scalable Architecture',
    '24/7 Support',
    'Cloud Native',
    'Security First',
    'Agile Delivery'
  ]

  return (
    <>
      <SEOHead
        title="Enterprise AI RAG Search & Deep Dive Analysis"
        description="LornuAI is an AI-powered Retrieval-Augmented Generation platform for enterprise knowledge retrieval, content generation, and data analysis using Cloudflare AI and Google Vertex AI."
        canonical="/"
        ogTitle="LornuAI - Enterprise AI RAG Search"
        ogDescription="Transform your business with cutting-edge AI and automation solutions that deliver results fast."
      />
      <div className="min-h-screen bg-background">
        <nav className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${isScrolled ? 'bg-card/80 backdrop-blur-lg shadow-lg' : 'bg-transparent'
          }`}>
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between h-20 md:h-24">
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                className="text-2xl font-bold gradient-text"
              >
                <Logo width={60} height={60} />
              </motion.div>

              <div className="hidden md:flex space-x-10">
                {['home', 'services', 'about', 'contact'].map((section) => (
                  <button
                    key={section}
                    onClick={() => scrollToSection(section)}
                    className={`text-lg font-semibold transition-colors capitalize ${activeSection === section
                      ? 'text-foreground'
                      : 'text-muted-foreground hover:text-foreground'
                      }`}
                  >
                    {section}
                  </button>
                ))}
              </div>

              <Button
                onClick={() => scrollToSection('contact')}
                className="hidden md:inline-flex gradient-bg hover:opacity-90 text-base px-6 py-4 h-auto"
              >
                Get Started
              </Button>
            </div>
          </div>
        </nav>

        <section id="home" className="relative min-h-screen flex items-center justify-center px-4 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-secondary/10 via-background to-accent/5" />

          <motion.div
            style={{ opacity, scale }}
            className="relative z-10 text-center max-w-5xl mx-auto"
          >
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.8 }}
            >
              <h1 className="text-5xl md:text-7xl lg:text-8xl font-black mb-6 leading-tight">
                <span className="gradient-text">Build the Future</span>
                <br />
                <span className="text-foreground">with AI</span>
              </h1>
              <p className="text-xl md:text-2xl text-muted-foreground mb-8 max-w-3xl mx-auto">
                We transform ambitious ideas into powerful digital solutions.
                Harness the power of artificial intelligence to accelerate your business growth.
              </p>
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <Button
                  size="lg"
                  onClick={() => scrollToSection('contact')}
                  className="gradient-bg hover:opacity-90 text-lg px-8"
                >
                  Get Started
                  <ArrowRight className="ml-2" weight="bold" />
                </Button>
                <Button
                  size="lg"
                  variant="outline"
                  onClick={() => scrollToSection('about')}
                  className="text-lg px-8"
                >
                  Learn More
                </Button>
              </div>
            </motion.div>
          </motion.div>
        </section>

        <section id="services" className="py-24 px-4 bg-secondary/5">
          <div className="max-w-7xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center mb-16"
            >
              <h2 className="text-4xl lg:text-5xl font-bold mb-4">What We Do</h2>
              <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
                We deliver cutting-edge solutions that drive innovation and growth for businesses of all sizes.
              </p>
            </motion.div>

            <div className="grid md:grid-cols-3 gap-8">
              {services.map((service, index) => (
                <motion.div
                  key={service.title}
                  initial={{ opacity: 0, y: 30 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6, delay: index * 0.1 }}
                >
                  <Card className="h-full hover:shadow-xl transition-all duration-300 border-2 hover:border-accent/50">
                    <CardContent className="p-8">
                      <service.icon size={48} weight="duotone" className="text-accent mb-4" />
                      <h3 className="text-2xl font-semibold mb-3">{service.title}</h3>
                      <p className="text-muted-foreground leading-relaxed">{service.description}</p>
                    </CardContent>
                  </Card>
                </motion.div>
              ))}
            </div>
          </div>
        </section>

        <section id="about" className="py-24 px-4">
          <div className="max-w-7xl mx-auto">
            <div className="grid lg:grid-cols-2 gap-12 items-center">
              <motion.div
                initial={{ opacity: 0, x: -30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6 }}
              >
                <h2 className="text-4xl lg:text-5xl font-bold mb-6">
                  Why Choose <span className="gradient-text">LornuAI</span>
                </h2>
                <p className="text-lg text-muted-foreground mb-8 leading-relaxed">
                  We combine deep technical expertise with a passion for innovation to deliver solutions
                  that don't just meet expectations—they exceed them. Our team of experienced engineers
                  and data scientists are dedicated to transforming your vision into reality.
                </p>
                <div className="grid grid-cols-2 gap-4">
                  {features.map((feature, index) => (
                    <motion.div
                      key={feature}
                      initial={{ opacity: 0, x: -20 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.4, delay: index * 0.05 }}
                      className="flex items-center gap-2"
                    >
                      <Check size={20} weight="bold" className="text-accent flex-shrink-0" />
                      <span className="text-muted-foreground">{feature}</span>
                    </motion.div>
                  ))}
                </div>
              </motion.div>

              <motion.div
                initial={{ opacity: 0, x: 30 }}
                whileInView={{ opacity: 1, x: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6 }}
                className="relative"
              >
                <Card className="p-8 border-2">
                  <CardContent className="space-y-6">
                    <div className="flex items-center gap-4">
                      <Rocket size={40} weight="duotone" className="text-accent" />
                      <div>
                        <h3 className="text-2xl font-semibold">Fast Delivery</h3>
                        <p className="text-muted-foreground">Launch products in weeks, not months</p>
                      </div>
                    </div>
                    <Separator />
                    <div className="flex items-center gap-4">
                      <Users size={40} weight="duotone" className="text-accent" />
                      <div>
                        <h3 className="text-2xl font-semibold">Expert Team</h3>
                        <p className="text-muted-foreground">Work with seasoned professionals</p>
                      </div>
                    </div>
                    <Separator />
                    <div className="flex items-center gap-4">
                      <ChartLine size={40} weight="duotone" className="text-accent" />
                      <div>
                        <h3 className="text-2xl font-semibold">Proven Results</h3>
                        <p className="text-muted-foreground">Track record of successful projects</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </div>
          </div>
        </section>

        <section id="contact" className="py-24 px-4 bg-secondary/5">
          <div className="max-w-3xl mx-auto">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
              className="text-center mb-12"
            >
              <h2 className="text-4xl lg:text-5xl font-bold mb-4">Let's Talk</h2>
              <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
                Ready to transform your business? Get in touch and let's discuss how we can help you achieve your goals.
              </p>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: 0.2 }}
            >
              <Card className="p-8 border-2">
                <form onSubmit={handleSubmit} className="space-y-6">
                  <div className="space-y-2">
                    <Label htmlFor="name">Name</Label>
                    <Input
                      id="name"
                      name="name"
                      placeholder="Your name"
                      required
                      className="h-12"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="email">Email</Label>
                    <Input
                      id="email"
                      name="email"
                      type="email"
                      placeholder="your.email@example.com"
                      required
                      className="h-12"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="message">Message</Label>
                    <Textarea
                      id="message"
                      name="message"
                      placeholder="Tell us about your project..."
                      required
                      className="min-h-32 resize-none"
                    />
                  </div>

                  <Button
                    type="submit"
                    size="lg"
                    className="w-full gradient-bg hover:opacity-90 text-lg"
                    disabled={isSubmitting}
                  >
                    {isSubmitting ? (
                      <>
                        <span className="animate-spin mr-2">⏳</span>
                        Sending...
                      </>
                    ) : (
                      <>
                        <Envelope className="mr-2" weight="bold" />
                        Send Message
                      </>
                    )}
                  </Button>
                </form>
              </Card>
            </motion.div>
          </div>
        </section>

        <footer className="bg-primary text-primary-foreground py-12 px-4">
          <div className="max-w-7xl mx-auto">
            <div className="flex flex-col md:flex-row items-center justify-between gap-6">
              <div className="text-2xl font-bold gradient-text"><Logo width={120} height={40} /></div>
              <p className="text-sm text-center md:text-left opacity-80">
                © 2025 LornuAI Inc. Building the future with intelligent solutions.
              </p>
              <div className="flex gap-6">
                <Link to="/privacy" className="text-sm hover:text-accent transition-colors">Privacy</Link>
                <Link to="/terms" className="text-sm hover:text-accent transition-colors">Terms</Link>
                <Link to="/security" className="text-sm hover:text-accent transition-colors">Security</Link>
                <button onClick={() => scrollToSection('contact')} className="text-sm hover:text-accent transition-colors">Contact</button>
              </div>
            </div>
          </div>
        </footer>
      </div>
    </>
  )
}
