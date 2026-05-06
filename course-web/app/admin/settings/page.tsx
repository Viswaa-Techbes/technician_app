'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowLeft } from 'lucide-react'

export default function AdminSettings() {
  const [adminData, setAdminData] = useState<any>(null)
  const router = useRouter()

  useEffect(() => {
    const admin = localStorage.getItem('admin_session')
    if (!admin) {
      router.push('/admin/login')
      return
    }
    setAdminData(JSON.parse(admin))
  }, [router])

  if (!adminData) return null

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center gap-4">
          <Link href="/admin/dashboard">
            <Button variant="ghost" size="sm">
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
          </Link>
          <div>
            <h1 className="text-2xl font-bold">Settings</h1>
            <p className="text-sm text-gray-600">Configure TECHBES admin settings</p>
          </div>
        </div>
      </header>

      <main className="max-w-4xl mx-auto px-4 py-8">
        <div className="grid gap-6">
          {/* Admin Profile */}
          <Card>
            <CardHeader>
              <CardTitle>Admin Profile</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                <div>
                  <label className="text-sm text-gray-600">Name</label>
                  <p className="text-lg font-medium">{adminData.name}</p>
                </div>
                <div>
                  <label className="text-sm text-gray-600">Email</label>
                  <p className="text-lg font-medium">{adminData.email}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Email Configuration */}
          <Card>
            <CardHeader>
              <CardTitle>Email Configuration</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4 text-sm">
                <p className="text-gray-600">
                  Email notifications are configured using Resend. Make sure your environment variable{' '}
                  <code className="bg-gray-100 px-2 py-1 rounded">RESEND_API_KEY</code> is set.
                </p>
                <div className="bg-blue-50 border border-blue-200 p-4 rounded">
                  <p className="text-blue-700">
                    <strong>Note:</strong> Enrollment confirmations and inquiry responses are automatically sent via email.
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* System Information */}
          <Card>
            <CardHeader>
              <CardTitle>System Information</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between border-b pb-2">
                  <span className="text-gray-600">Database</span>
                  <span className="font-medium">Supabase PostgreSQL</span>
                </div>
                <div className="flex justify-between border-b pb-2">
                  <span className="text-gray-600">Email Service</span>
                  <span className="font-medium">Resend</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Authentication</span>
                  <span className="font-medium">Email/Password</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Getting Started */}
          <Card>
            <CardHeader>
              <CardTitle>Getting Started</CardTitle>
            </CardHeader>
            <CardContent>
              <ol className="space-y-3 text-sm list-decimal list-inside">
                <li>
                  <Link href="/admin/courses/new" className="text-blue-600 hover:underline">
                    Create your first course
                  </Link>
                </li>
                <li>
                  <Link href="/admin/courses" className="text-blue-600 hover:underline">
                    Publish courses
                  </Link>{' '}
                  to make them visible to students
                </li>
                <li>Students can enroll through the public website</li>
                <li>
                  <Link href="/admin/enrollments" className="text-blue-600 hover:underline">
                    Manage enrollments
                  </Link>{' '}
                  from the dashboard
                </li>
                <li>
                  <Link href="/admin/inquiries" className="text-blue-600 hover:underline">
                    Respond to inquiries
                  </Link>{' '}
                  from potential students
                </li>
              </ol>
            </CardContent>
          </Card>
        </div>
      </main>
    </div>
  )
}
