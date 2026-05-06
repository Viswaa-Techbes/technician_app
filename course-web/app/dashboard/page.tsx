'use client'

import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { BookOpen, MapPin, CheckCircle2, Clock, Award, Shield, FileText, User } from 'lucide-react'

export default function UserDashboard() {
  const [userData, setUserData] = useState<any>(null)
  
  useEffect(() => {
    const saved = localStorage.getItem('userEnrollment')
    if (saved) {
      setUserData(JSON.parse(saved))
    } else {
      // Mock data for demo if navigated directly
      setUserData({
        name: 'John Doe',
        email: 'john@example.com',
        phone: '9876543210',
        id: 'ENR-902102',
        plan: 'job-ready',
        status: 'Paid',
        course: 'CCTV & IT Skill Development Program',
      })
    }
  }, [])

  if (!userData) return <div className="min-h-screen bg-[#F5F9FF]" />

  const planName = userData.plan === 'premium' ? 'Premium Plan' : userData.plan === 'job-ready' ? 'Job Ready Plan' : 'Basic Plan'

  return (
    <main className="min-h-screen bg-[#F5F9FF] overflow-x-hidden">
      <Header />
      
      <div className="pt-36 pb-20 container mx-auto px-4 max-w-6xl">
        <div className="flex items-center justify-between mb-10">
          <div>
            <h1 className="text-3xl md:text-4xl font-black text-primary mb-2">Student Dashboard</h1>
            <p className="text-foreground/60 text-lg">Welcome back, {userData.name}!</p>
          </div>
          <div className="hidden md:flex items-center gap-2 bg-white px-4 py-2 rounded-xl shadow-sm border border-primary/10">
            <Shield size={20} className="text-green-500" />
            <span className="font-bold text-sm">Verified Student</span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Left Column - Profile & Quick Stats */}
          <div className="space-y-8">
            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="bg-white rounded-3xl p-6 shadow-[0_10px_40px_rgba(11,77,186,0.05)] border border-primary/5">
              <div className="flex items-center gap-4 mb-6">
                <div className="w-16 h-16 bg-gradient-to-br from-primary to-accent rounded-full flex items-center justify-center text-white text-2xl font-black shadow-lg">
                  {userData.name.charAt(0)}
                </div>
                <div>
                  <h3 className="font-black text-lg text-primary">{userData.name}</h3>
                  <p className="text-sm text-foreground/50">{userData.email}</p>
                </div>
              </div>
              <div className="space-y-4">
                <div className="flex justify-between items-center py-3 border-b border-gray-100">
                  <span className="text-foreground/60 text-sm font-medium">Enrollment ID</span>
                  <span className="font-bold text-primary bg-primary/10 px-2 py-1 rounded-lg text-sm">{userData.id}</span>
                </div>
                <div className="flex justify-between items-center py-3 border-b border-gray-100">
                  <span className="text-foreground/60 text-sm font-medium">Phone</span>
                  <span className="font-bold text-foreground">{userData.phone}</span>
                </div>
                <div className="flex justify-between items-center py-3">
                  <span className="text-foreground/60 text-sm font-medium">Payment Status</span>
                  <span className="font-bold text-green-500 flex items-center gap-1"><CheckCircle2 size={16}/> {userData.status}</span>
                </div>
              </div>
            </motion.div>

            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.1 }} className="bg-gradient-to-br from-[#FF6B00] to-[#e65c00] rounded-3xl p-6 text-white shadow-lg shadow-accent/20">
              <h3 className="font-black text-xl mb-2">Need Help?</h3>
              <p className="text-sm text-white/80 mb-4">Contact your batch mentor for any technical doubts or schedule queries.</p>
              <button className="w-full bg-white text-accent font-bold py-3 rounded-xl hover:bg-gray-50 transition-colors">
                Contact Mentor
              </button>
            </motion.div>
          </div>

          {/* Right Column - Course Details & Progress */}
          <div className="lg:col-span-2 space-y-8">
            <motion.div initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.2 }} className="bg-white rounded-3xl p-8 shadow-[0_10px_40px_rgba(11,77,186,0.05)] border border-primary/5">
              <h2 className="text-2xl font-black text-primary mb-6">Course Overview</h2>
              
              <div className="flex items-start gap-5 p-5 bg-primary/5 rounded-2xl border border-primary/10 mb-8">
                <div className="w-14 h-14 bg-primary rounded-xl flex items-center justify-center text-white flex-shrink-0 shadow-md">
                  <BookOpen size={28} />
                </div>
                <div>
                  <p className="text-xs font-bold text-accent uppercase tracking-widest mb-1">{planName}</p>
                  <h3 className="text-xl font-black text-primary">{userData.course}</h3>
                  <div className="flex gap-4 mt-3 flex-wrap">
                    <span className="flex items-center gap-1.5 text-sm font-semibold text-foreground/60 bg-white px-3 py-1 rounded-lg shadow-sm">
                      <Clock size={16} className="text-primary" /> 3 Months
                    </span>
                    <span className="flex items-center gap-1.5 text-sm font-semibold text-foreground/60 bg-white px-3 py-1 rounded-lg shadow-sm">
                      <MapPin size={16} className="text-primary" /> Offline Center
                    </span>
                  </div>
                </div>
              </div>

              <h3 className="font-bold text-lg mb-4">Your Progress</h3>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {[
                  { label: 'Course Content', val: '0%', icon: FileText, color: 'blue' },
                  { label: 'Live Projects', val: '0/5', icon: CheckCircle2, color: 'orange' },
                  { label: 'Internship', val: 'Pending', icon: User, color: 'purple' },
                  { label: 'Certificate', val: 'Locked', icon: Award, color: 'gray' }
                ].map((stat, i) => (
                  <div key={i} className="bg-gray-50 border border-gray-100 rounded-2xl p-4 text-center hover:shadow-md transition-shadow">
                    <stat.icon size={24} className={`mx-auto mb-2 text-${stat.color}-500`} />
                    <p className="text-xl font-black text-primary">{stat.val}</p>
                    <p className="text-xs font-semibold text-foreground/50">{stat.label}</p>
                  </div>
                ))}
              </div>
            </motion.div>

            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: 0.3 }} className="bg-white rounded-3xl p-8 shadow-[0_10px_40px_rgba(11,77,186,0.05)] border border-primary/5">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-black text-primary">Recent Documents</h2>
                <button className="text-accent text-sm font-bold hover:underline">View All</button>
              </div>
              
              <div className="space-y-4">
                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl hover:bg-primary/5 transition-colors cursor-pointer border border-transparent hover:border-primary/20">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-green-100 text-green-600 rounded-lg flex items-center justify-center">
                      <FileText size={20} />
                    </div>
                    <div>
                      <p className="font-bold text-foreground">Fee Receipt</p>
                      <p className="text-xs text-foreground/50">{userData.date ? new Date(userData.date).toLocaleDateString() : 'Today'}</p>
                    </div>
                  </div>
                  <button className="px-4 py-2 bg-white shadow-sm border border-gray-200 rounded-lg text-sm font-bold hover:text-primary">Download</button>
                </div>
                <div className="flex items-center justify-between p-4 bg-gray-50 rounded-xl border border-transparent opacity-60">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-gray-200 text-gray-400 rounded-lg flex items-center justify-center">
                      <Award size={20} />
                    </div>
                    <div>
                      <p className="font-bold text-foreground">Course Certificate</p>
                      <p className="text-xs text-foreground/50">Unlocks after completion</p>
                    </div>
                  </div>
                  <Lock size={20} className="text-gray-400 mr-2" />
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </div>

      <Footer />
    </main>
  )
}
