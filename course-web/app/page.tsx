'use client'

import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Button } from '@/components/ui/button'
import { CheckCircle2 } from 'lucide-react'
import Link from 'next/link'

export default function HomePage() {
  return (
    <main className="min-h-screen bg-white">
      <Header />

      {/* Hero Section */}
      <section className="py-16 bg-white">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
            {/* Left Content */}
            <div className="space-y-6">
              <div>
                <h1 className="text-4xl md:text-5xl font-bold mb-4" style={{ color: '#0B4DBA' }}>
                  CCTV & IT Skill Development Program
                </h1>
                <p className="text-2xl font-semibold mb-2" style={{ color: '#FF6B00' }}>
                  2 Months Training + 1 Month Internship
                </p>
                <p className="text-gray-600 text-lg">
                  Get Job Ready | Work on Real Projects | Build Skills | Build Your Future
                </p>
              </div>

              {/* Features List */}
              <div className="space-y-3 pt-4">
                <div className="flex items-start gap-3">
                  <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <span className="text-gray-700 font-medium">100% Practical Training</span>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <span className="text-gray-700 font-medium">Real Project Internship</span>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <span className="text-gray-700 font-medium">Job Assistance</span>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <span className="text-gray-700 font-medium">Industry Expert Trainers</span>
                </div>
                <div className="flex items-start gap-3">
                  <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                  <span className="text-gray-700 font-medium">Certificate of Completion</span>
                </div>
              </div>

              {/* CTA Button */}
              <Link href="/admission">
                <Button
                  className="mt-8 px-8 py-3 text-lg font-semibold text-white"
                  style={{ backgroundColor: '#FF6B00' }}
                >
                  Enroll Now
                </Button>
              </Link>
            </div>

            {/* Right Image */}
            <div className="bg-gradient-to-br from-blue-50 to-blue-100 rounded-lg p-8 h-96 flex items-center justify-center">
              <div className="text-center">
                <div className="text-6xl mb-4">📹</div>
                <p className="text-gray-600 font-medium">CCTV & IT Training</p>
                <p className="text-sm text-gray-500 mt-2">Advanced Hardware Setup</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Course Modules Section */}
      <section className="py-16" style={{ backgroundColor: '#F5F9FF' }}>
        <div className="container mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12" style={{ color: '#0B4DBA' }}>
            Course Modules
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
            {/* Module 1 */}
            <div className="bg-white rounded-lg p-6 shadow-sm">
              <div className="text-4xl mb-4 text-center">🎥</div>
              <h3 className="text-xl font-bold mb-3" style={{ color: '#0B4DBA' }}>CCTV Technology</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>• CCTV Basics</li>
                <li>• IP & Analog Cameras</li>
                <li>• Installation & Wiring</li>
                <li>• DVR/NVR Setup</li>
                <li>• Mobile Viewing</li>
                <li>• Troubleshooting</li>
              </ul>
            </div>

            {/* Module 2 */}
            <div className="bg-white rounded-lg p-6 shadow-sm">
              <div className="text-4xl mb-4 text-center">🌐</div>
              <h3 className="text-xl font-bold mb-3" style={{ color: '#0B4DBA' }}>Networking</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>• Networking Basics</li>
                <li>• IP Addressing</li>
                <li>• Router Configuration</li>
                <li>• LAN & WiFi Setup</li>
                <li>• Switch Configuration</li>
              </ul>
            </div>

            {/* Module 3 */}
            <div className="bg-white rounded-lg p-6 shadow-sm">
              <div className="text-4xl mb-4 text-center">💻</div>
              <h3 className="text-xl font-bold mb-3" style={{ color: '#0B4DBA' }}>Computer Hardware</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>• Desktop Assembling</li>
                <li>• Laptop Repair Basics</li>
                <li>• OS Installation</li>
                <li>• Software Installation</li>
                <li>• Virus Removal</li>
                <li>• System Maintenance</li>
              </ul>
            </div>

            {/* Module 4 */}
            <div className="bg-white rounded-lg p-6 shadow-sm">
              <div className="text-4xl mb-4 text-center">🔧</div>
              <h3 className="text-xl font-bold mb-3" style={{ color: '#0B4DBA' }}>Practical Training</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>• Real Site Installations</li>
                <li>• Configuration Practice</li>
                <li>• Fault Finding</li>
                <li>• Client Handling</li>
                <li>• Maintenance Work</li>
              </ul>
            </div>

            {/* Module 5 */}
            <div className="bg-white rounded-lg p-6 shadow-sm">
              <div className="text-4xl mb-4 text-center">💼</div>
              <h3 className="text-xl font-bold mb-3" style={{ color: '#0B4DBA' }}>Business Skills</h3>
              <ul className="text-sm text-gray-700 space-y-2">
                <li>• How to Get Clients</li>
                <li>• Pricing & Quotation</li>
                <li>• Sales & Communication</li>
                <li>• Freelancing Tips</li>
                <li>• Start Your Own Business</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Who Can Join Section */}
      <section className="py-16 bg-white">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12" style={{ color: '#0B4DBA' }}>
            Who Can Join
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
            {['10th / 12th Pass Students', 'Diploma / ITI Students', 'Job Seekers', 'Career Switchers', 'Technicians & Electricians'].map((item) => (
              <div
                key={item}
                className="p-6 rounded-lg text-center font-semibold"
                style={{ backgroundColor: '#F5F9FF', color: '#0B4DBA' }}
              >
                {item}
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Career Section */}
      <section className="py-16" style={{ backgroundColor: '#F5F9FF' }}>
        <div className="container mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-4" style={{ color: '#0B4DBA' }}>
            Build a Secure Career
          </h2>
          <p className="text-center text-lg font-semibold mb-12" style={{ color: '#FF6B00' }}>
            High Demand | Good Salary | Bright Future
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {['CCTV Technician', 'Network Technician', 'IT Support Executive', 'Field Service Engineer'].map((role) => (
              <div
                key={role}
                className="bg-white rounded-lg p-6 text-center shadow-sm border-l-4"
                style={{ borderLeftColor: '#FF6B00' }}
              >
                <p className="font-bold" style={{ color: '#0B4DBA' }}>
                  {role}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Pricing Section */}
      <section className="py-16 bg-white">
        <div className="container mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12" style={{ color: '#0B4DBA' }}>
            Course Fees
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
            {/* Basic Plan */}
            <div className="bg-white border-2 border-gray-200 rounded-lg p-8">
              <h3 className="text-xl font-bold mb-2" style={{ color: '#0B4DBA' }}>
                BASIC PLAN
              </h3>
              <p className="text-3xl font-bold mb-6" style={{ color: '#FF6B00' }}>
                ₹7,999
              </p>
              <ul className="text-sm text-gray-700 space-y-2 mb-8">
                <li>✓ 2 Months Classroom Training</li>
                <li>✓ CCTV Basics & Installation</li>
                <li>✓ Networking Basics</li>
                <li>✓ Computer Hardware Basics</li>
                <li>✓ Practical Lab Sessions</li>
                <li>✓ Course Completion Certificate</li>
                <li>✓ Trainer Support During Course</li>
                <li>✓ Study Materials (PDF)</li>
              </ul>
              <Link href="/admission">
                <Button className="w-full text-white" style={{ backgroundColor: '#0B4DBA' }}>
                  Select Plan
                </Button>
              </Link>
            </div>

            {/* Job Ready Plan - Featured */}
            <div className="bg-white border-2 rounded-lg p-8 md:scale-105" style={{ borderColor: '#FF6B00' }}>
              <div
                className="text-center text-white font-bold py-1 px-3 rounded mb-4 inline-block w-full"
                style={{ backgroundColor: '#FF6B00' }}
              >
                Most Popular
              </div>
              <h3 className="text-xl font-bold mb-2" style={{ color: '#0B4DBA' }}>
                JOB READY PLAN
              </h3>
              <p className="text-3xl font-bold mb-6" style={{ color: '#FF6B00' }}>
                ₹14,999
              </p>
              <ul className="text-sm text-gray-700 space-y-2 mb-8">
                <li>✓ Everything in Basic Plan</li>
                <li>✓ 1 Month Real Project Internship</li>
                <li>✓ Advanced CCTV (IP Camera, NVR)</li>
                <li>✓ Advanced Networking (Router, Switch)</li>
                <li>✓ Troubleshooting & Maintenance</li>
                <li>✓ Mobile App Setup & Configuration</li>
                <li>✓ Soft Skills & Client Handling</li>
                <li>✓ Job Assistance & Guidance</li>
                <li>✓ Certificate + Internship Certificate</li>
              </ul>
              <Link href="/admission">
                <Button className="w-full text-white" style={{ backgroundColor: '#FF6B00' }}>
                  Select Plan
                </Button>
              </Link>
            </div>

            {/* Premium Plan */}
            <div className="bg-white border-2 border-gray-200 rounded-lg p-8">
              <h3 className="text-xl font-bold mb-2" style={{ color: '#0B4DBA' }}>
                PREMIUM PLAN
              </h3>
              <p className="text-3xl font-bold mb-6" style={{ color: '#FF6B00' }}>
                ₹24,999
              </p>
              <ul className="text-sm text-gray-700 space-y-2 mb-8">
                <li>✓ Everything in Job Ready Plan</li>
                <li>✓ 2 Months Extended Internship</li>
                <li>✓ Live Project Experience (On Site)</li>
                <li>✓ Business & Entrepreneurship Training</li>
                <li>✓ How to Start Your Own CCTV Business</li>
                <li>✓ Quotation, Pricing & Marketing</li>
                <li>✓ Placement Assistance</li>
                <li>✓ Interview Preparation</li>
                <li>✓ Premium Certificate</li>
                <li>✓ Lifetime Guidance & Support</li>
              </ul>
              <Link href="/admission">
                <Button className="w-full text-white" style={{ backgroundColor: '#0B4DBA' }}>
                  Select Plan
                </Button>
              </Link>
            </div>
          </div>

          {/* Why Choose Us */}
          <div className="bg-gray-50 rounded-lg p-8 text-center">
            <div className="grid grid-cols-1 md:grid-cols-5 gap-6">
              <div>
                <div className="text-3xl mb-2">✓</div>
                <p className="font-semibold" style={{ color: '#0B4DBA' }}>
                  100% Practical Training
                </p>
              </div>
              <div>
                <div className="text-3xl mb-2">✓</div>
                <p className="font-semibold" style={{ color: '#0B4DBA' }}>
                  Small Batch Size
                </p>
              </div>
              <div>
                <div className="text-3xl mb-2">✓</div>
                <p className="font-semibold" style={{ color: '#0B4DBA' }}>
                  Hands-on Lab Practice
                </p>
              </div>
              <div>
                <div className="text-3xl mb-2">✓</div>
                <p className="font-semibold" style={{ color: '#0B4DBA' }}>
                  Certificate of Completion
                </p>
              </div>
              <div>
                <div className="text-3xl mb-2">✓</div>
                <p className="font-semibold" style={{ color: '#0B4DBA' }}>
                  Lifetime Mentor Support
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
