import { useState, useEffect } from 'react'
import { motion, useScroll, useTransform } from 'framer-motion'
import { HelmetProvider } from 'react-helmet-async'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import { Separator } from '@/components/ui/separator'
import { toast } from 'sonner'
import SEOHead from '@/components/SEOHead'
import { Logo } from '@/components/Logo'
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

function App() {
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

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.currentTarget)
    const name = formData.get('name')
    const email = formData.get('email')
    const message = formData.get('message')

    if (!name || !email || !message) {
      toast.error('Please fill in all fields')
      return
    }

    toast.success('Message sent! We\'ll be in touch soon.')
    e.currentTarget.reset()
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
    <HelmetProvider>
      <SEOHead 
        title="Enterprise AI RAG Search & Deep Dive Analysis"
        description="LornuAI is an AI-powered Retrieval-Augmented Generation platform for enterprise knowledge retrieval, content generation, and data analysis using Cloudflare AI and Google Vertex AI."
        canonical="/"
        ogTitle="LornuAI - Enterprise AI RAG Search"
        ogDescription="Transform your business with cutting-edge AI and automation solutions that deliver results fast."
      />
      <div className="min-h-screen bg-background">
        <header className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          isScrolled ? 'bg-card/80 backdrop-blur-lg shadow-lg' : 'bg-transparent'
        }`}>
          <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <Logo 
              onClick={() => scrollToSection('home')}
              size="md"
            />
            
            <div className="hidden md:flex space-x-8">
              {['home', 'services', 'about', 'contact'].map((section) => (
                <button
                  key={section}
                  onClick={() => scrollToSection(section)}
                  className={`text-sm font-semibold transition-colors capitalize ${
                    activeSection === section 
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
              className="hidden md:inline-flex gradient-bg hover:opacity-90"
            >
              Get Started
            </Button>
          </div>
          </nav>
        </header>

        <main>
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
            <h1 className="text-5xl sm:text-6xl lg:text-7xl font-bold mb-6 leading-tight">
              Transform Your Business with{' '}
              <span className="gradient-text">AI Innovation</span>
            </h1>
          </motion.div>
          
          <motion.p
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.2 }}
            className="text-lg sm:text-xl text-muted-foreground mb-12 max-w-3xl mx-auto leading-relaxed"
          >
            We build intelligent solutions that empower organizations to thrive in the digital age. 
            From concept to deployment, we're your partner in innovation.
          </motion.p>
          
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 0.4 }}
            className="flex flex-col sm:flex-row items-center justify-center gap-4"
          >
            <Button
              size="lg"
              onClick={() => scrollToSection('contact')}
              className="gradient-bg hover:opacity-90 text-lg px-8 group"
            >
              Start Your Journey
              <ArrowRight className="ml-2 group-hover:translate-x-1 transition-transform" />
            </Button>
            <Button
              size="lg"
              variant="outline"
              onClick={() => scrollToSection('services')}
              className="text-lg px-8 border-2"
            >
              Explore Services
            </Button>
          </motion.div>
        </motion.div>
          </section>

          <section id="services" className="py-20 lg:py-32 px-4">
            <div className="max-w-7xl mx-auto">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6 }}
                className="text-center mb-16"
              >
                <h2 className="text-4xl lg:text-5xl font-bold mb-4">Our Services</h2>
                <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
                  Comprehensive solutions designed to accelerate your digital transformation
                </p>
              </motion.div>

              <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8">
            {services.map((service, index) => (
              <motion.div
                key={service.title}
                initial={{ opacity: 0, y: 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.6, delay: index * 0.1 }}
              >
                <Card className="h-full border-2 hover:border-secondary transition-all duration-300 hover:shadow-xl hover:-translate-y-1">
                  <CardContent className="p-8">
                    <div className="w-14 h-14 rounded-2xl gradient-bg flex items-center justify-center mb-6">
                      <service.icon size={28} weight="bold" className="text-white" />
                    </div>
                    <h3 className="text-2xl font-semibold mb-4">{service.title}</h3>
                    <p className="text-muted-foreground leading-relaxed">{service.description}</p>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
            </div>
          </div>
            </section>

          <section id="about" className="py-20 lg:py-32 px-4 bg-muted/30">
            <div className="max-w-7xl mx-auto">
              <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">
                <motion.div
                  initial={{ opacity: 0, x: -30 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ duration: 0.6 }}
                >
                  <h2 className="text-4xl lg:text-5xl font-bold mb-6">
                    Building the Future, <span className="gradient-text">Together</span>
                  </h2>
                  <p className="text-lg text-muted-foreground mb-8 leading-relaxed">
                    At LornuAI, we believe technology should empower, not complicate. Our team of 
                    experts combines deep technical knowledge with business acumen to deliver solutions 
                    that drive real results.
                  </p>
              <p className="text-lg text-muted-foreground mb-8 leading-relaxed">
                We're not just developers—we're partners in your success, committed to understanding 
                your challenges and creating innovative solutions that scale with your growth.
              </p>
              <Button 
                size="lg" 
                onClick={() => scrollToSection('contact')}
                className="gradient-bg hover:opacity-90"
              >
                <Users className="mr-2" weight="bold" />
                Work With Us
              </Button>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, x: 30 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6 }}
            >
              <Card className="p-8 border-2">
                <h3 className="text-2xl font-semibold mb-6">Why Choose LornuAI?</h3>
                <div className="grid sm:grid-cols-2 gap-4">
                  {features.map((feature, index) => (
                    <motion.div
                      key={feature}
                      initial={{ opacity: 0, x: -10 }}
                      whileInView={{ opacity: 1, x: 0 }}
                      viewport={{ once: true }}
                      transition={{ duration: 0.4, delay: index * 0.1 }}
                      className="flex items-center gap-3"
                    >
                      <div className="w-6 h-6 rounded-full bg-accent flex items-center justify-center flex-shrink-0">
                        <Check size={16} weight="bold" className="text-accent-foreground" />
                      </div>
                      <span className="font-medium">{feature}</span>
                    </motion.div>
                  ))}
                </div>
              </Card>
            </motion.div>
          </div>
            </div>
          </section>

          <section id="contact" className="py-20 lg:py-32 px-4">
            <div className="max-w-4xl mx-auto">
              <motion.div
                initial={{ opacity: 0, y: 20 }}
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
                >
                  <Envelope className="mr-2" weight="bold" />
                  Send Message
                </Button>
              </form>
            </Card>
          </motion.div>
        </div>
      </section>
    </main>

    <footer className="bg-primary text-primary-foreground py-12 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <Logo size="md" />
            <p className="text-sm text-center md:text-left opacity-80">
              © 2025 LornuAI Inc. Building the future with intelligent solutions.
            </p>
            <div className="flex gap-6">
              <button onClick={() => toast('Privacy Policy coming soon')} className="text-sm hover:text-accent transition-colors">Privacy</button>
              <button onClick={() => toast('Terms of Service coming soon')} className="text-sm hover:text-accent transition-colors">Terms</button>
              <button onClick={() => scrollToSection('contact')} className="text-sm hover:text-accent transition-colors">Contact</button>
            </div>
          </div>
        </div>
      </footer>
      </div>
    </HelmetProvider>
  )
}

export default App