'use client'

import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { CheckCircle2 } from 'lucide-react'

export default function InternshipPage() {
  return (
    <main className="min-h-screen bg-white">
      <Header />

      <section className="py-16">
        <div className="container mx-auto px-4 max-w-4xl">
          <h1 className="text-4xl font-bold text-center mb-12" style={{ color: '#0B4DBA' }}>
            Real Project Internship
          </h1>

          <div className="space-y-8">
            {/* Real Project Internship */}
            <div className="bg-white border-l-4 rounded-lg p-8" style={{ borderLeftColor: '#FF6B00' }}>
              <div className="flex gap-4">
                <div className="text-4xl">🏢</div>
                <div>
                  <h2 className="text-2xl font-bold mb-3" style={{ color: '#0B4DBA' }}>
                    Real Project Internship
                  </h2>
                  <p className="text-gray-600">
                    Get hands-on experience by working on real-world projects with actual clients and installations. Learn industry practices and build practical knowledge that employers value.
                  </p>
                </div>
              </div>
            </div>

            {/* Live CCTV Installation Training */}
            <div className="bg-white border-l-4 rounded-lg p-8" style={{ borderLeftColor: '#FF6B00' }}>
              <div className="flex gap-4">
                <div className="text-4xl">📹</div>
                <div>
                  <h2 className="text-2xl font-bold mb-3" style={{ color: '#0B4DBA' }}>
                    Live CCTV Installation Training
                  </h2>
                  <p className="text-gray-600">
                    Participate in actual CCTV system installations at client sites. Learn proper installation techniques, cable management, and system configuration in real-world environments.
                  </p>
                </div>
              </div>
            </div>

            {/* Networking Practice */}
            <div className="bg-white border-l-4 rounded-lg p-8" style={{ borderLeftColor: '#FF6B00' }}>
              <div className="flex gap-4">
                <div className="text-4xl">🌐</div>
                <div>
                  <h2 className="text-2xl font-bold mb-3" style={{ color: '#0B4DBA' }}>
                    Networking Practice
                  </h2>
                  <p className="text-gray-600">
                    Configure and manage network systems in production environments. Work with routers, switches, and network security under professional guidance.
                  </p>
                </div>
              </div>
            </div>

            {/* On-Site Experience */}
            <div className="bg-white border-l-4 rounded-lg p-8" style={{ borderLeftColor: '#FF6B00' }}>
              <div className="flex gap-4">
                <div className="text-4xl">🔧</div>
                <div>
                  <h2 className="text-2xl font-bold mb-3" style={{ color: '#0B4DBA' }}>
                    On-Site Experience
                  </h2>
                  <p className="text-gray-600">
                    Work directly at client locations gaining exposure to different environments, system types, and client handling. Build professional communication and problem-solving skills.
                  </p>
                </div>
              </div>
            </div>

            {/* Internship Certificate */}
            <div className="bg-white border-l-4 rounded-lg p-8" style={{ borderLeftColor: '#FF6B00' }}>
              <div className="flex gap-4">
                <div className="text-4xl">🏆</div>
                <div>
                  <h2 className="text-2xl font-bold mb-3" style={{ color: '#0B4DBA' }}>
                    Internship Certificate
                  </h2>
                  <p className="text-gray-600">
                    Receive a professional internship certificate recognizing your hands-on training and practical experience. This certificate adds value to your resume and job applications.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Key Benefits */}
          <div className="mt-16 bg-gradient-to-r from-blue-50 to-blue-100 rounded-lg p-8">
            <h2 className="text-2xl font-bold mb-6" style={{ color: '#0B4DBA' }}>
              Why Our Internship Program?
            </h2>
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                <span className="text-gray-700">Work with experienced mentors and industry professionals</span>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                <span className="text-gray-700">Gain real-world experience before entering the job market</span>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                <span className="text-gray-700">Build a professional network in the CCTV and IT industry</span>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                <span className="text-gray-700">Increase job prospects with practical experience and certifications</span>
              </div>
              <div className="flex items-start gap-3">
                <CheckCircle2 size={24} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-1" />
                <span className="text-gray-700">Potential job opportunities with partner companies</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
