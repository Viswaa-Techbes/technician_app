'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { createClient } from '@/lib/supabase/client'
import { ArrowRight, Calendar, Users, BookOpen } from 'lucide-react'

interface Course {
  id: string
  title: string
  description: string
  price: number
  level: string
  instructor_name: string
  duration: string
  max_students: number
}

export default function CoursesPage() {
  const [courses, setCourses] = useState<Course[]>([])
  const [filteredCourses, setFilteredCourses] = useState<Course[]>([])
  const [selectedLevel, setSelectedLevel] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState('')

  useEffect(() => {
    const fetchCourses = async () => {
      try {
        const supabase = createClient()
        const { data, error } = await supabase
          .from('courses')
          .select('*')
          .eq('status', 'published')
          .order('created_at', { ascending: false })

        if (error) throw error
        setCourses(data || [])
        setFilteredCourses(data || [])
      } catch (error) {
        console.error('Error fetching courses:', error)
      } finally {
        setLoading(false)
      }
    }

    fetchCourses()
  }, [])

  // Filter courses
  useEffect(() => {
    let filtered = courses

    if (searchQuery) {
      filtered = filtered.filter(
        (course) =>
          course.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
          course.description.toLowerCase().includes(searchQuery.toLowerCase())
      )
    }

    if (selectedLevel) {
      filtered = filtered.filter((course) => course.level === selectedLevel)
    }

    setFilteredCourses(filtered)
  }, [searchQuery, selectedLevel, courses])

  const levels = ['beginner', 'intermediate', 'advanced']

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <Header />

      <main className="flex-1">
        {/* Header */}
        <section className="px-4 py-12 md:py-16 border-b border-border bg-primary/5">
          <div className="container mx-auto max-w-6xl">
            <h1 className="text-4xl md:text-5xl font-bold mb-4">Our Courses</h1>
            <p className="text-lg text-muted-foreground max-w-2xl">
              Choose from our wide selection of professional technology courses designed for all skill levels.
            </p>
          </div>
        </section>

        {/* Filters and Courses */}
        <section className="px-4 py-12 md:py-16">
          <div className="container mx-auto max-w-6xl">
            {/* Filters */}
            <div className="mb-8 space-y-4">
              {/* Search */}
              <div>
                <input
                  type="text"
                  placeholder="Search courses..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full px-4 py-2 rounded-lg border border-border bg-background text-foreground placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary"
                />
              </div>

              {/* Level Filter */}
              <div className="flex flex-wrap gap-2">
                <button
                  onClick={() => setSelectedLevel(null)}
                  className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                    selectedLevel === null
                      ? 'bg-primary text-primary-foreground'
                      : 'border border-border hover:border-primary'
                  }`}
                >
                  All Levels
                </button>
                {levels.map((level) => (
                  <button
                    key={level}
                    onClick={() => setSelectedLevel(level)}
                    className={`px-4 py-2 rounded-lg font-medium transition-colors capitalize ${
                      selectedLevel === level
                        ? 'bg-primary text-primary-foreground'
                        : 'border border-border hover:border-primary'
                    }`}
                  >
                    {level}
                  </button>
                ))}
              </div>
            </div>

            {/* Courses Grid */}
            {loading ? (
              <div className="text-center py-12">
                <p className="text-muted-foreground">Loading courses...</p>
              </div>
            ) : filteredCourses.length === 0 ? (
              <div className="text-center py-12">
                <p className="text-muted-foreground text-lg">No courses found matching your criteria.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {filteredCourses.map((course) => (
                  <Card key={course.id} className="flex flex-col border border-border hover:shadow-lg transition-shadow">
                    <CardHeader>
                      <div className="flex items-start justify-between mb-4">
                        <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-primary/10 text-primary capitalize">
                          {course.level}
                        </span>
                        <span className="text-xl font-bold text-primary">
                          {course.price === 0 ? 'Free' : `$${course.price}`}
                        </span>
                      </div>
                      <CardTitle className="text-xl line-clamp-2">{course.title}</CardTitle>
                      <CardDescription className="line-clamp-2">{course.instructor_name}</CardDescription>
                    </CardHeader>
                    <CardContent className="flex-1 flex flex-col">
                      <p className="text-sm text-muted-foreground mb-4 line-clamp-3">{course.description}</p>

                      {/* Course Meta */}
                      <div className="space-y-2 mb-6 mt-auto">
                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Calendar size={16} />
                          <span>{course.duration}</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Users size={16} />
                          <span>Max {course.max_students} students</span>
                        </div>
                      </div>

                      {/* CTA Button */}
                      <Link href={`/courses/${course.id}`} className="w-full">
                        <Button className="w-full">
                          View Details
                          <ArrowRight className="ml-2 h-4 w-4" />
                        </Button>
                      </Link>
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </section>
      </main>

      <Footer />
    </div>
  )
}
