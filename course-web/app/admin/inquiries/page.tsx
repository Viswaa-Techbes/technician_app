'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { ArrowLeft, Mail, Phone, CheckCircle } from 'lucide-react'

interface Inquiry {
  id: string
  name: string
  email: string
  phone: string
  message: string
  status: string
  created_at: string
}

export default function InquiriesAdmin() {
  const [inquiries, setInquiries] = useState<Inquiry[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const admin = localStorage.getItem('admin_session')
    if (!admin) {
      router.push('/admin/login')
      return
    }
    fetchInquiries()
  }, [router])

  const fetchInquiries = async () => {
    try {
      const response = await fetch('/api/admin/inquiries')
      const data = await response.json()
      if (response.ok) {
        setInquiries(data.inquiries || [])
      }
    } catch (error) {
      console.error('Error fetching inquiries:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const handleStatusChange = async (inquiryId: string, newStatus: string) => {
    try {
      const response = await fetch(`/api/admin/inquiries/${inquiryId}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      })

      if (response.ok) {
        setInquiries(
          inquiries.map((i) =>
            i.id === inquiryId ? { ...i, status: newStatus } : i
          )
        )
      }
    } catch (error) {
      console.error('Error updating inquiry:', error)
    }
  }

  const filteredInquiries = {
    new: inquiries.filter((i) => i.status === 'new'),
    responded: inquiries.filter((i) => i.status === 'responded'),
    closed: inquiries.filter((i) => i.status === 'closed'),
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
            <h1 className="text-2xl font-bold">Manage Inquiries</h1>
            <p className="text-sm text-gray-600">
              Respond to student inquiries and questions
            </p>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        {isLoading ? (
          <Card>
            <CardContent className="pt-6">Loading inquiries...</CardContent>
          </Card>
        ) : inquiries.length === 0 ? (
          <Card>
            <CardContent className="pt-6 text-center">
              <p className="text-gray-600">No inquiries yet</p>
            </CardContent>
          </Card>
        ) : (
          <div className="space-y-8">
            {/* New Inquiries */}
            <div>
              <div className="mb-4">
                <h2 className="text-xl font-semibold">
                  New ({filteredInquiries.new.length})
                </h2>
              </div>
              <div className="grid gap-4">
                {filteredInquiries.new.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">
                    No new inquiries
                  </p>
                ) : (
                  filteredInquiries.new.map((inquiry) => (
                    <InquiryCard
                      key={inquiry.id}
                      inquiry={inquiry}
                      onStatusChange={handleStatusChange}
                    />
                  ))
                )}
              </div>
            </div>

            {/* Responded Inquiries */}
            <div>
              <div className="mb-4">
                <h2 className="text-xl font-semibold text-green-700">
                  Responded ({filteredInquiries.responded.length})
                </h2>
              </div>
              <div className="grid gap-4">
                {filteredInquiries.responded.length === 0 ? (
                  <p className="text-gray-500 text-center py-8">
                    No responded inquiries
                  </p>
                ) : (
                  filteredInquiries.responded.map((inquiry) => (
                    <InquiryCard
                      key={inquiry.id}
                      inquiry={inquiry}
                      onStatusChange={handleStatusChange}
                    />
                  ))
                )}
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  )
}

function InquiryCard({
  inquiry,
  onStatusChange,
}: {
  inquiry: Inquiry
  onStatusChange: (id: string, status: string) => void
}) {
  return (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="pt-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="md:col-span-2">
            <h3 className="font-semibold text-lg mb-2">{inquiry.name}</h3>
            <div className="space-y-2 text-sm text-gray-600 mb-4">
              <p className="flex items-center gap-2">
                <Mail className="w-4 h-4" />
                {inquiry.email}
              </p>
              <p className="flex items-center gap-2">
                <Phone className="w-4 h-4" />
                {inquiry.phone}
              </p>
              <p className="text-xs">
                {new Date(inquiry.created_at).toLocaleDateString()}
              </p>
            </div>
            <div className="bg-gray-50 p-3 rounded border border-gray-200 text-sm">
              {inquiry.message}
            </div>
          </div>

          <div className="flex flex-col justify-between">
            <div>
              <p className="text-sm font-medium mb-2">Status:</p>
              <span
                className={`px-3 py-1 rounded text-xs font-medium ${
                  inquiry.status === 'new'
                    ? 'bg-blue-100 text-blue-800'
                    : inquiry.status === 'responded'
                      ? 'bg-green-100 text-green-800'
                      : 'bg-gray-100 text-gray-800'
                }`}
              >
                {inquiry.status.charAt(0).toUpperCase() + inquiry.status.slice(1)}
              </span>
            </div>

            <div className="flex flex-col gap-2">
              {inquiry.status === 'new' && (
                <Button
                  size="sm"
                  onClick={() => onStatusChange(inquiry.id, 'responded')}
                  className="bg-green-600 hover:bg-green-700"
                >
                  <CheckCircle className="w-4 h-4 mr-1" />
                  Mark Responded
                </Button>
              )}
              {inquiry.status !== 'closed' && (
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => onStatusChange(inquiry.id, 'closed')}
                >
                  Close
                </Button>
              )}
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
