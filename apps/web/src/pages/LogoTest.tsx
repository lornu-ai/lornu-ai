import { useState } from 'react'
import { motion } from 'framer-motion'
import { Link } from 'react-router-dom'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowLeft } from '@phosphor-icons/react'
import { Logo } from '@/components/Logo'

/**
 * Logo Test Page
 *
 * This page allows you to test and compare logo2.svg vs logo3.svg in large size.
 *
 * Visit: /logo-test
 */
export default function LogoTest() {
  const [selectedVariant, setSelectedVariant] = useState<'option2' | 'option3'>('option2')

  const variants = [
    { id: 'option2' as const, name: 'Option 2 (logo2.svg)', description: 'Logo variant 2' },
    { id: 'option3' as const, name: 'Option 3 (logo3.svg)', description: 'Logo variant 3' }
  ]

  return (
    <div className="min-h-screen bg-background">
      <nav className="bg-card/80 backdrop-blur-lg shadow-lg sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <Link to="/" className="text-2xl font-bold gradient-text" aria-label="LornuAI home">
              <Logo width={120} height={40} variant={selectedVariant} />
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

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
        >
          <div className="mb-8">
            <h1 className="text-4xl font-bold mb-2">Logo Variant Testing</h1>
            <p className="text-muted-foreground">
              Compare logo2.svg vs logo3.svg in large size
            </p>
          </div>

          {/* Variant Selector */}
          <Card className="mb-8">
            <CardHeader>
              <CardTitle>Select Variant</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="flex gap-4 flex-wrap">
                {variants.map((variant) => (
                  <Button
                    key={variant.id}
                    variant={selectedVariant === variant.id ? 'default' : 'outline'}
                    onClick={() => setSelectedVariant(variant.id)}
                    className="min-w-[150px]"
                  >
                    {variant.name}
                  </Button>
                ))}
              </div>
              <p className="text-sm text-muted-foreground mt-4">
                Currently selected: <strong>{variants.find(v => v.id === selectedVariant)?.name}</strong>
              </p>
            </CardContent>
          </Card>

          {/* Side by Side Comparison */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            {variants.map((variant) => (
              <Card key={variant.id} className={selectedVariant === variant.id ? 'ring-2 ring-primary' : ''}>
                <CardHeader>
                  <CardTitle className="text-lg">{variant.name}</CardTitle>
                  <p className="text-sm text-muted-foreground">{variant.description}</p>
                </CardHeader>
                <CardContent>
                  <div className="flex flex-col items-center justify-center p-8 bg-muted/50 rounded-lg">
                    {/* Large size only */}
                    <div className="flex flex-col items-center space-y-2">
                      <p className="text-xs text-muted-foreground uppercase tracking-wide mb-4">Large Size</p>
                      <Logo variant={variant.id} size="lg" />
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Usage Example */}
          <Card>
            <CardHeader>
              <CardTitle>Usage Example</CardTitle>
            </CardHeader>
            <CardContent>
              <pre className="bg-muted p-4 rounded-lg overflow-x-auto">
                <code className="text-sm">{`<Logo variant="${selectedVariant}" width={120} height={40} />`}</code>
              </pre>
            </CardContent>
          </Card>
        </motion.div>
      </main>
    </div>
  )
}
