'use client'

import { useEffect, useState } from 'react'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Users, CreditCard, BookOpen, Search, Filter } from 'lucide-react'

export default function AdminDashboard() {
  const [enrollments, setEnrollments] = useState<any[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetch('/api/enroll')
      .then(res => res.json())
      .then(data => {
        setEnrollments(data.enrollments || [])
        setLoading(false)
      })
      .catch(err => {
        console.error('Failed to fetch enrollments', err)
        setLoading(false)
      })
  }, [])

  return (
    <main className="min-h-screen bg-[#F5F9FF] overflow-x-hidden">
      <Header />
      
      <div className="pt-36 pb-20 container mx-auto px-4 max-w-7xl">
        <div className="mb-10">
          <h1 className="text-3xl md:text-4xl font-black text-primary mb-2">Admin Dashboard</h1>
          <p className="text-foreground/60 text-lg">Manage paid enrollments and student details.</p>
        </div>

        {/* Stats Row */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-primary/5 flex items-center gap-4">
            <div className="w-14 h-14 bg-blue-100 text-blue-600 rounded-xl flex items-center justify-center">
              <Users size={28} />
            </div>
            <div>
              <p className="text-sm font-semibold text-foreground/50">Total Paid Students</p>
              <p className="text-2xl font-black text-primary">{enrollments.length}</p>
            </div>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-primary/5 flex items-center gap-4">
            <div className="w-14 h-14 bg-green-100 text-green-600 rounded-xl flex items-center justify-center">
              <CreditCard size={28} />
            </div>
            <div>
              <p className="text-sm font-semibold text-foreground/50">Revenue (Test)</p>
              <p className="text-2xl font-black text-primary">
                ₹{enrollments.reduce((acc, curr) => acc + (curr.amountPaid || 0), 0).toLocaleString()}
              </p>
            </div>
          </div>
          <div className="bg-white p-6 rounded-2xl shadow-sm border border-primary/5 flex items-center gap-4">
            <div className="w-14 h-14 bg-orange-100 text-orange-600 rounded-xl flex items-center justify-center">
              <BookOpen size={28} />
            </div>
            <div>
              <p className="text-sm font-semibold text-foreground/50">Active Batches</p>
              <p className="text-2xl font-black text-primary">1</p>
            </div>
          </div>
        </div>

        {/* Table Section */}
        <div className="bg-white rounded-3xl shadow-sm border border-primary/5 overflow-hidden">
          <div className="p-6 border-b border-gray-100 flex flex-col md:flex-row justify-between items-center gap-4">
            <h2 className="text-xl font-black text-primary">Recent Enrollments</h2>
            <div className="flex gap-3 w-full md:w-auto">
              <div className="relative flex-1 md:w-64">
                <Search size={18} className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                <input type="text" placeholder="Search students..." className="w-full pl-10 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-lg text-sm focus:outline-none focus:border-primary" />
              </div>
              <button className="p-2 border border-gray-200 text-gray-600 rounded-lg bg-gray-50 hover:bg-gray-100">
                <Filter size={20} />
              </button>
            </div>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-gray-50 border-b border-gray-100">
                  <th className="p-4 text-sm font-bold text-gray-500">Student Name</th>
                  <th className="p-4 text-sm font-bold text-gray-500">Contact Info</th>
                  <th className="p-4 text-sm font-bold text-gray-500">Course & Plan</th>
                  <th className="p-4 text-sm font-bold text-gray-500">Enrollment ID</th>
                  <th className="p-4 text-sm font-bold text-gray-500">Date</th>
                  <th className="p-4 text-sm font-bold text-gray-500">Status</th>
                </tr>
              </thead>
              <tbody>
                {loading ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-gray-500">Loading enrollments...</td>
                  </tr>
                ) : enrollments.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="p-8 text-center text-gray-500">No paid enrollments found.</td>
                  </tr>
                ) : (
                  enrollments.map((enr: any, i: number) => (
                    <tr key={i} className="border-b border-gray-50 hover:bg-gray-50/50 transition-colors">
                      <td className="p-4">
                        <p className="font-bold text-primary">{enr.name}</p>
                        <p className="text-xs text-gray-500">{enr.qualification}</p>
                      </td>
                      <td className="p-4">
                        <p className="font-semibold text-gray-800">{enr.phone}</p>
                        <p className="text-xs text-gray-500">{enr.email}</p>
                      </td>
                      <td className="p-4">
                        <p className="font-bold text-gray-800 uppercase text-xs">{enr.plan.replace('-', ' ')}</p>
                        <p className="text-xs text-gray-500 truncate max-w-[200px]">{enr.course}</p>
                      </td>
                      <td className="p-4">
                        <span className="bg-blue-50 text-blue-700 px-2 py-1 rounded text-xs font-bold border border-blue-100">{enr.id}</span>
                        <p className="text-[10px] text-gray-400 mt-1">{enr.txId}</p>
                      </td>
                      <td className="p-4 text-sm text-gray-600">
                        {new Date(enr.date).toLocaleDateString()}
                      </td>
                      <td className="p-4">
                        <span className="bg-green-100 text-green-700 px-2 py-1 rounded-full text-xs font-bold flex items-center w-max gap-1">
                          <span className="w-1.5 h-1.5 rounded-full bg-green-500"></span> {enr.status}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <Footer />
    </main>
  )
}
