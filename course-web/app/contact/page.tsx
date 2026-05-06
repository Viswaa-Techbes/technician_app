'use client'

import { useState } from 'react'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Button } from '@/components/ui/button'
import { Phone, MapPin } from 'lucide-react'

export default function ContactPage() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    message: '',
  })
  const [submitted, setSubmitted] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    try {
      const response = await fetch('/api/contact', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to submit form')
      }

      setSubmitted(true)
      setFormData({ name: '', email: '', phone: '', message: '' })
    } catch (err: any) {
      setError(err.message || 'Error submitting form. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  const whatsappMessage = encodeURIComponent('Hi TECHBES, I would like to know more about your training programs.')
  const whatsappLink = `https://wa.me/919591144949?text=${whatsappMessage}`

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="py-16">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 max-w-5xl mx-auto">
            {/* Contact Info */}
            <div className="space-y-8">
              <div>
                <h1 className="text-4xl font-bold mb-4" style={{ color: '#0B4DBA' }}>
                  Get in Touch
                </h1>
                <p className="text-gray-600">
                  Have questions about our CCTV & IT training programs? We're here to help!
                </p>
              </div>

              {/* Contact Details */}
              <div className="space-y-6">
                <div className="flex items-start gap-4">
                  <Phone size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <div>
                    <h3 className="font-semibold mb-1" style={{ color: '#0B4DBA' }}>
                      Phone
                    </h3>
                    <p className="text-gray-600">9591144949</p>
                  </div>
                </div>

                <div className="flex items-start gap-4">
                  <MapPin size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <div>
                    <h3 className="font-semibold mb-1" style={{ color: '#0B4DBA' }}>
                      Location
                    </h3>
                    <p className="text-gray-600">Nagarbhavi, Bangalore</p>
                    <p className="text-gray-600">Karnataka – 560072</p>
                  </div>
                </div>
              </div>

              {/* WhatsApp Link */}
              <a href={whatsappLink} target="_blank" rel="noopener noreferrer">
                <Button
                  className="w-full py-3 text-lg font-semibold text-white"
                  style={{ backgroundColor: '#25D366' }}
                >
                  💬 Message on WhatsApp
                </Button>
              </a>
            </div>

            {/* Contact Form */}
            <div>
              {submitted ? (
                <div className="bg-green-50 border border-green-200 rounded-lg p-8 text-center">
                  <h2 className="text-2xl font-bold mb-2" style={{ color: '#0B4DBA' }}>
                    Thank You!
                  </h2>
                  <p className="text-gray-600">
                    We have received your message and will get back to you soon.
                  </p>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="bg-white border border-gray-200 rounded-lg p-8 space-y-6">
                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                      {error}
                    </div>
                  )}

                  {/* Name */}
                  <div>
                    <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                      Name
                    </label>
                    <input
                      type="text"
                      name="name"
                      value={formData.name}
                      onChange={handleInputChange}
                      required
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                      placeholder="Your name"
                    />
                  </div>

                  {/* Email */}
                  <div>
                    <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                      Email
                    </label>
                    <input
                      type="email"
                      name="email"
                      value={formData.email}
                      onChange={handleInputChange}
                      required
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                      placeholder="Your email"
                    />
                  </div>

                  {/* Phone */}
                  <div>
                    <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                      Phone
                    </label>
                    <input
                      type="tel"
                      name="phone"
                      value={formData.phone}
                      onChange={handleInputChange}
                      required
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                      placeholder="Your phone number"
                    />
                  </div>

                  {/* Message */}
                  <div>
                    <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                      Message
                    </label>
                    <textarea
                      name="message"
                      value={formData.message}
                      onChange={handleInputChange}
                      rows={4}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                      placeholder="Your message"
                    />
                  </div>

                  {/* Submit Button */}
                  <Button
                    type="submit"
                    disabled={submitting}
                    className="w-full py-3 text-lg font-semibold text-white"
                    style={{ backgroundColor: '#FF6B00' }}
                  >
                    {submitting ? 'Sending...' : 'Send Message'}
                  </Button>
                </form>
              )}
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
