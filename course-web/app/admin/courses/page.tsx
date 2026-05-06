'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Input } from '@/components/ui/input'
import { Edit, Trash2, Plus, ArrowLeft } from 'lucide-react'

interface Course {
  id: string
  title: string
  slug: string
  level: string
  price: number
  status: string
  instructor_name: string
}

export default function CoursesAdmin() {
  const [courses, setCourses] = useState<Course[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const router = useRouter()

  useEffect(() => {
    const admin = localStorage.getItem('admin_session')
    if (!admin) {
      router.push('/admin/login')
      return
    }
    fetchCourses()
  }, [router])

  const fetchCourses = async () => {
    try {
      const response = await fetch('/api/admin/courses')
      const data = await response.json()
      if (response.ok) {
        setCourses(data.courses || [])
      }
    } catch (error) {
      console.error('Error fetching courses:', error)
    } finally {
      setIsLoading(false)
    }
  }

  const filteredCourses = courses.filter(
    (course) =>
      course.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      course.slug.toLowerCase().includes(searchTerm.toLowerCase())
  )

  const handleDelete = async (courseId: string) => {
    if (!confirm('Are you sure you want to delete this course?')) return

    try {
      const response = await fetch(`/api/admin/courses/${courseId}`, {
        method: 'DELETE',
      })
      if (response.ok) {
        setCourses(courses.filter((c) => c.id !== courseId))
      }
    } catch (error) {
      console.error('Error deleting course:', error)
    }
  }

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      <header className="bg-white border-b">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-4">
            <Link href="/admin/dashboard">
              <Button variant="ghost" size="sm">
                <ArrowLeft className="w-4 h-4 mr-2" />
                Back
              </Button>
            </Link>
            <div>
              <h1 className="text-2xl font-bold">Manage Courses</h1>
              <p className="text-sm text-gray-600">Create and manage your courses</p>
            </div>
          </div>
          <Link href="/admin/courses/new">
            <Button className="bg-blue-600 hover:bg-blue-700">
              <Plus className="w-4 h-4 mr-2" />
              New Course
            </Button>
          </Link>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 py-8">
        <Card className="mb-6">
          <CardHeader>
            <CardTitle>Search Courses</CardTitle>
          </CardHeader>
          <CardContent>
            <Input
              placeholder="Search by course name or slug..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full"
            />
          </CardContent>
        </Card>

        {isLoading ? (
          <Card>
            <CardContent className="pt-6">Loading courses...</CardContent>
          </Card>
        ) : filteredCourses.length === 0 ? (
          <Card>
            <CardContent className="pt-6 text-center">
              <p className="text-gray-600 mb-4">No courses found</p>
              <Link href="/admin/courses/new">
                <Button className="bg-blue-600 hover:bg-blue-700">
                  Create First Course
                </Button>
              </Link>
            </CardContent>
          </Card>
        ) : (
          <div className="grid gap-4">
            {filteredCourses.map((course) => (
              <Card key={course.id} className="hover:shadow-md transition-shadow">
                <CardContent className="pt-6">
                  <div className="flex justify-between items-start">
                    <div className="flex-1">
                      <h3 className="font-semibold text-lg mb-1">{course.title}</h3>
                      <div className="grid grid-cols-2 gap-2 text-sm text-gray-600">
                        <p>
                          <span className="font-medium">Level:</span> {course.level}
                        </p>
                        <p>
                          <span className="font-medium">Price:</span> ₹
                          {course.price}
                        </p>
                        <p>
                          <span className="font-medium">Instructor:</span>{' '}
                          {course.instructor_name}
                        </p>
                        <p>
                          <span className="font-medium">Status:</span>{' '}
                          <span
                            className={`px-2 py-1 rounded text-xs ${
                              course.status === 'published'
                                ? 'bg-green-100 text-green-800'
                                : 'bg-yellow-100 text-yellow-800'
                            }`}
                          >
                            {course.status}
                          </span>
                        </p>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <Link href={`/admin/courses/${course.id}`}>
                        <Button variant="outline" size="sm">
                          <Edit className="w-4 h-4" />
                        </Button>
                      </Link>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleDelete(course.id)}
                        className="text-red-600 hover:text-red-700"
                      >
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
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
