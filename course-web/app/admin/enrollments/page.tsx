'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowLeft, CheckCircle, Clock } from 'lucide-react'

interface Enrollment {
  id: string
  student_name: string
  student_email: string
  student_phone: string
  course_id: string
  status: string
  payment_status: string
  enrollment_date: string
}

export default function EnrollmentsAdmin() {
  const [enrollments, setEnrollments] = useState<Enrollment[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const admin = localStorage.getItem('admin_session')
    if (!admin) {
      router.push('/admin/login')
      return
    }
    fetchEnrollments()
  }, [router])

  const fetchEnrollments = async () => {
    try {
      const response = await fetch('/api/admin/enrollments')
      const data = await response.json()
      if (response.ok) {
        setEnrollments(data.enrollments || [])
      }
    } catch (error) {
      console.error('Error fetching enrollments:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleStatusChange = async (
    enrollmentId: string,
    newStatus: string
  ) => {
    try {
      const response = await fetch(`/api/admin/enrollments/${enrollmentId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      })

      if (response.ok) {
        setEnrollments(
          enrollments.map((e) =>
            e.id === enrollmentId ? { ...e, status: newStatus } : e
          )
        )
      }
    } catch (error) {
      console.error('Error updating enrollment:', error)
    }
  }

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
            <h1 className="text-2xl font-bold">Manage Enrollments</h1>
            <p className="text-sm text-gray-600">
              View and manage student enrollments
            </p>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {isLoading ? (
          <Card>
            <CardContent className="pt-6">Loading enrollments...</CardContent>
          </Card>
        ) : enrollments.length === 0 ? (
          <Card>
            <CardContent className="pt-6 text-center">
              <p className="text-gray-600">No enrollments yet</p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4">
            {enrollments.map((enrollment) => (
              <Card key={enrollment.id} className="hover:shadow-md transition-shadow">
                <CardContent className="pt-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <div>
                      <h3 className="font-semibold text-lg mb-2">
                        {enrollment.student_name}
                      </h3>
                      <div className="space-y-1 text-sm text-gray-600">
                        <p>
                          <span className="font-medium">Email:</span>{' '}
                          {enrollment.student_email}
                        </p>
                        <p>
                          <span className="font-medium">Phone:</span>{' '}
                          {enrollment.student_phone}
                        </p>
                        <p>
                          <span className="font-medium">Enrolled:</span>{' '}
                          {new Date(enrollment.enrollment_date).toLocaleDateString()}
                        </p>
                      </div>
                    </div>

                    <div className="flex flex-col justify-between">
                      <div>
                        <p className="text-sm text-gray-600 mb-2">
                          <span className="font-medium">Payment Status:</span>
                          <span
                            className={`ml-2 px-2 py-1 rounded text-xs ${
                              enrollment.payment_status === 'paid'
                                ? 'bg-green-100 text-green-800'
                                : 'bg-yellow-100 text-yellow-800'
                            }`}
                          >
                            {enrollment.payment_status}
                          </span>
                        </p>
                      </div>

                      <div className="flex gap-2">
                        {enrollment.status === 'pending' && (
                          <Button
                            size="sm"
                            onClick={() =>
                              handleStatusChange(enrollment.id, 'confirmed')
                            }
                            className="bg-green-600 hover:bg-green-700"
                          >
                            <CheckCircle className="w-4 h-4 mr-1" />
                            Confirm
                          </Button>
                        )}
                        {enrollment.status !== 'cancelled' && (
                          <Button
                            size="sm"
                            variant="outline"
                            onClick={() =>
                              handleStatusChange(enrollment.id, 'cancelled')
                            }
                            className="text-red-600 hover:text-red-700"
                          >
                            Cancel
                          </Button>
                        )}
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 pt-4 border-t flex items-center gap-2 text-sm">
                    {enrollment.status === 'confirmed' ? (
                      <>
                        <CheckCircle className="w-4 h-4 text-green-600" />
                        <span className="text-green-700">Confirmed</span>
                      </>
                    ) : (
                      <>
                        <Clock className="w-4 h-4 text-yellow-600" />
                        <span className="text-yellow-700">Pending</span>
                      </>
                    )}
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
