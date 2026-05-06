'use client'

import { useState } from 'react'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Button } from '@/components/ui/button'

export default function AdmissionPage() {
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    course: 'job-ready',
    plan: 'job-ready',
  })
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [error, setError] = useState('')

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
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
          email: formData.email,
          message: `Interested in: ${formData.plan} plan`,
          course_interest: formData.course,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to submit')
      }

      setSubmitted(true)
      setFormData({ name: '', phone: '', email: '', course: 'job-ready', plan: 'job-ready' })
    } catch (err: any) {
      setError(err.message || 'Error submitting form')
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="py-16">
        <div className="container mx-auto px-4 max-w-2xl">
          <h1 className="text-4xl font-bold text-center mb-2" style={{ color: '#0B4DBA' }}>
            Admissions Open
          </h1>
          <p className="text-center text-gray-600 mb-12">
            Limited Seats Available - Enroll Now
          </p>

          {submitted ? (
            <div className="bg-green-50 border border-green-200 rounded-lg p-8 text-center">
              <h2 className="text-2xl font-bold mb-2" style={{ color: '#0B4DBA' }}>
                Thank You!
              </h2>
              <p className="text-gray-600 mb-4">
                Your admission request has been submitted. Our team will contact you shortly.
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

              {/* Full Name */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Full Name
                </label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                  placeholder="Enter your full name"
                />
              </div>

              {/* Phone Number */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Phone Number
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

              {/* Email */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Email
                </label>
                <input
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                  placeholder="Enter your email"
                />
              </div>

              {/* Course Selection */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Course
                </label>
                <select
                  name="course"
                  value={formData.course}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                >
                  <option value="cctv-it">CCTV & IT Skill Development Program</option>
                </select>
              </div>

              {/* Plan Selection */}
              <div>
                <label className="block text-sm font-semibold mb-2" style={{ color: '#0B4DBA' }}>
                  Preferred Plan
                </label>
                <select
                  name="plan"
                  value={formData.plan}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
                >
                  <option value="basic">Basic Plan - ₹7,999</option>
                  <option value="job-ready">Job Ready Plan - ₹14,999 (Recommended)</option>
                  <option value="premium">Premium Plan - ₹24,999</option>
                </select>
              </div>

              {/* Submit Button */}
              <Button
                type="submit"
                disabled={submitting}
                className="w-full py-3 text-lg font-semibold text-white"
                style={{ backgroundColor: '#FF6B00' }}
              >
                {submitting ? 'Submitting...' : 'Submit Admission Request'}
              </Button>
            </form>
          )}
        </div>
      </section>

      <Footer />
    </main>
  )
}
