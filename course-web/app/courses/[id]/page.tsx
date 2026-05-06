'use client'

import { useEffect, useState } from 'react'
import { useParams } from 'next/navigation'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { createClient } from '@/lib/supabase/client'
import { Calendar, Users, BookOpen, CheckCircle, AlertCircle } from 'lucide-react'

interface Course {
  id: string
  title: string
  description: string
  long_description: string
  price: number
  level: string
  instructor_name: string
  duration: string
  max_students: number
  start_date: string
  end_date: string
}

export default function CourseDetailsPage() {
  const params = useParams()
  const courseId = params.id as string
  const [course, setCourse] = useState<Course | null>(null)
  const [loading, setLoading] = useState(true)
  const [enrollmentStep, setEnrollmentStep] = useState<'form' | 'success'>('form')
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
  })
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    const fetchCourse = async () => {
      try {
        const supabase = createClient()
        const { data, error } = await supabase
          .from('courses')
          .select('*')
          .eq('id', courseId)
          .eq('status', 'published')
          .single()

        if (error) throw error
        setCourse(data)
      } catch (error) {
        console.error('Error fetching course:', error)
      } finally {
        setLoading(false)
      }
    }

    if (courseId) {
      fetchCourse()
    }
  }, [courseId])

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target
    setFormData((prev) => ({ ...prev, [name]: value }))
  }

  const handleEnroll = async (e: React.FormEvent) => {
    e.preventDefault()
    setSubmitting(true)
    setError('')

    try {
      const response = await fetch('/api/enroll', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          course_id: courseId,
          student_name: formData.name,
          student_email: formData.email,
          student_phone: formData.phone,
        }),
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to enroll')
      }

      setEnrollmentStep('success')
    } catch (err: any) {
      console.error('Error enrolling:', err)
      setError(err.message || 'Error submitting enrollment. Please try again.')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen flex flex-col bg-background">
        <Header />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-muted-foreground">Loading course details...</p>
        </main>
        <Footer />
      </div>
    )
  }

  if (!course) {
    return (
      <div className="min-h-screen flex flex-col bg-background">
        <Header />
        <main className="flex-1 flex items-center justify-center">
          <p className="text-muted-foreground">Course not found.</p>
        </main>
        <Footer />
      </div>
    )
  }

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <Header />

      <main className="flex-1">
        <div className="container mx-auto max-w-6xl px-4 py-8 md:py-12">
          {/* Course Header */}
          <div className="mb-12 pb-8 border-b border-border">
            <div className="flex flex-col md:flex-row gap-8">
              {/* Course Info */}
              <div className="flex-1">
                <div className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-primary/10 text-primary capitalize mb-4">
                  {course.level}
                </div>
                <h1 className="text-4xl md:text-5xl font-bold mb-4">{course.title}</h1>
                <p className="text-xl text-muted-foreground mb-6">{course.description}</p>

                {/* Course Meta */}
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-6">
                  <div className="flex items-center gap-3">
                    <Calendar className="text-primary" size={20} />
                    <div>
                      <p className="text-sm text-muted-foreground">Duration</p>
                      <p className="font-semibold">{course.duration}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Users className="text-primary" size={20} />
                    <div>
                      <p className="text-sm text-muted-foreground">Max Students</p>
                      <p className="font-semibold">{course.max_students}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <BookOpen className="text-primary" size={20} />
                    <div>
                      <p className="text-sm text-muted-foreground">Instructor</p>
                      <p className="font-semibold">{course.instructor_name}</p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Price and CTA */}
              <div className="md:w-80">
                <Card className="sticky top-20 border border-border">
                  <CardHeader>
                    <div className="text-4xl font-bold text-primary mb-2">
                      {course.price === 0 ? 'Free' : `$${course.price}`}
                    </div>
                    {course.start_date && (
                      <p className="text-sm text-muted-foreground">
                        Starts: {new Date(course.start_date).toLocaleDateString()}
                      </p>
                    )}
                  </CardHeader>
                  <CardContent>
                    {enrollmentStep === 'form' ? (
                      <Button className="w-full" onClick={() => setEnrollmentStep('form')}>
                        Enroll Now
                      </Button>
                    ) : (
                      <Button className="w-full" disabled>
                        Enrolled Successfully
                      </Button>
                    )}
                  </CardContent>
                </Card>
              </div>
            </div>
          </div>

          {/* Content and Enrollment Form */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
            {/* Course Description */}
            <div className="lg:col-span-2">
              <h2 className="text-2xl font-bold mb-4">About This Course</h2>
              <div className="prose prose-sm dark:prose-invert max-w-none">
                <p className="text-muted-foreground leading-relaxed mb-6">
                  {course.long_description || course.description}
                </p>

                <h3 className="text-lg font-semibold mt-8 mb-4">What You&apos;ll Learn</h3>
                <ul className="space-y-2 text-muted-foreground">
                  <li className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-primary flex-shrink-0 mt-1" />
                    <span>Industry-relevant skills and practical knowledge</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-primary flex-shrink-0 mt-1" />
                    <span>Real-world project experience with expert guidance</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-primary flex-shrink-0 mt-1" />
                    <span>Professional certification upon completion</span>
                  </li>
                  <li className="flex items-start gap-3">
                    <CheckCircle size={20} className="text-primary flex-shrink-0 mt-1" />
                    <span>Lifetime access to course materials</span>
                  </li>
                </ul>
              </div>
            </div>

            {/* Enrollment Form */}
            <div>
              <Card className="border border-border sticky top-20">
                <CardHeader>
                  <CardTitle>
                    {enrollmentStep === 'form' ? 'Enroll in Course' : 'Enrollment Complete'}
                  </CardTitle>
                </CardHeader>
                <CardContent>
                  {enrollmentStep === 'form' ? (
                    <form onSubmit={handleEnroll} className="space-y-4">
                      {error && (
                        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded flex items-start gap-3">
                          <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
                          <span>{error}</span>
                        </div>
                      )}
                      <div>
                        <label htmlFor="name" className="block text-sm font-medium mb-2">
                          Full Name
                        </label>
                        <input
                          id="name"
                          name="name"
                          type="text"
                          required
                          value={formData.name}
                          onChange={handleInputChange}
                          className="w-full px-3 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                          placeholder="John Doe"
                        />
                      </div>

                      <div>
                        <label htmlFor="email" className="block text-sm font-medium mb-2">
                          Email
                        </label>
                        <input
                          id="email"
                          name="email"
                          type="email"
                          required
                          value={formData.email}
                          onChange={handleInputChange}
                          className="w-full px-3 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                          placeholder="john@example.com"
                        />
                      </div>

                      <div>
                        <label htmlFor="phone" className="block text-sm font-medium mb-2">
                          Phone Number
                        </label>
                        <input
                          id="phone"
                          name="phone"
                          type="tel"
                          required
                          value={formData.phone}
                          onChange={handleInputChange}
                          className="w-full px-3 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                          placeholder="+1 (555) 000-0000"
                        />
                      </div>

                      <Button
                        type="submit"
                        className="w-full"
                        disabled={submitting}
                      >
                        {submitting ? 'Submitting...' : 'Complete Enrollment'}
                      </Button>

                      <p className="text-xs text-muted-foreground text-center">
                        We&apos;ll send you a confirmation email with next steps.
                      </p>
                    </form>
                  ) : (
                    <div className="text-center space-y-4 py-6">
                      <div className="flex justify-center">
                        <CheckCircle size={48} className="text-green-500" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-lg mb-2">Welcome, {formData.name}!</h3>
                        <p className="text-sm text-muted-foreground mb-4">
                          Your enrollment has been submitted. Check your email for confirmation details and next steps.
                        </p>
                      </div>
                      <Button
                        variant="outline"
                        className="w-full"
                        onClick={() => window.location.href = '/courses'}
                      >
                        Back to Courses
                      </Button>
                    </div>
                  )}
                </CardContent>
              </Card>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </div>
  )
}
