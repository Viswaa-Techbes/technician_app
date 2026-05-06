'use client'

import { useState } from 'react'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Button } from '@/components/ui/button'

export default function EnquiryPage() {
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    course_interested: 'general',
    message: '',
  })
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [error, setError] = useState('')

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
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
        body: JSON.stringify({
          name: formData.name,
          phone: formData.phone,
          email: formData.phone, // Using phone as placeholder since email not in form
          message: formData.message,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to submit')
      }

      setSubmitted(true)
      setFormData({ name: '', phone: '', course_interested: 'general', message: '' })
    } catch (err: any) {
      setError(err.message || 'Error submitting form')
    } finally {
      setSubmitting(false)
    }
  }

  const whatsappMessage = encodeURIComponent('Hi TECHBES, I would like to know more about your CCTV & IT training programs.')
  const whatsappLink = `https://wa.me/919591144949?text=${whatsappMessage}`

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="py-16">
        <div className="container mx-auto px-4 max-w-2xl">
          <h1 className="text-4xl font-bold text-center mb-2" style={{ color: '#0B4DBA' }}>
            Send an Enquiry
          </h1>
          <p className="text-center text-gray-600 mb-12">
            Have questions? Reach out to us. We are happy to help!
          </p>

          {submitted ? (
            <div className="bg-green-50 border border-green-200 rounded-lg p-8 text-center">
              <h2 className="text-2xl font-bold mb-2" style={{ color: '#0B4DBA' }}>
                Thank You!
              </h2>
              <p className="text-gray-600 mb-4">
                Your enquiry has been received. Our team will get back to you shortly.
              </p>
              <Button
                onClick={() => (window.location.href = '/')}
                style={{ backgroundColor: '#0B4DBA' }}
                className="text-white"
              >
                Back to Home
              </Button>
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
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                  placeholder="Enter your name"
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
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                  placeholder="Enter your phone number"
                />
              </div>

              {/* Course Interested */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Course Interested
                </label>
                <select
                  name="course_interested"
                  value={formData.course_interested}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                >
                  <option value="general">Select a course</option>
                  <option value="cctv">CCTV Technology</option>
                  <option value="networking">Networking</option>
                  <option value="hardware">Computer Hardware</option>
                  <option value="practical">Practical Training</option>
                  <option value="business">Business Skills</option>
                </select>
              </div>

              {/* Message */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Message
                </label>
                <textarea
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  rows={5}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                  placeholder="Tell us about your queries or interests"
                />
              </div>

              {/* Buttons */}
              <div className="space-y-3">
                <Button
                  type="submit"
                  disabled={submitting}
                  className="w-full py-3 text-lg font-semibold text-white"
                  style={{ backgroundColor: '#0B4DBA' }}
                >
                  {submitting ? 'Submitting...' : 'Submit Enquiry'}
                </Button>

                <a href={whatsappLink} target="_blank" rel="noopener noreferrer">
                  <Button
                    type="button"
                    className="w-full py-3 text-lg font-semibold text-white"
                    style={{ backgroundColor: '#25D366' }}
                  >
                    💬 Message on WhatsApp
                  </Button>
                </a>
              </div>
            </form>
          )}
        </div>
      </section>

      <Footer />
    </main>
  )
}
