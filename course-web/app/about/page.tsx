import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Award, Target, Users } from 'lucide-react'

export default function AboutPage() {
  const values = [
    {
      icon: Target,
      title: 'Mission',
      description: 'To empower individuals with cutting-edge technology skills and knowledge that transform careers and drive innovation in the digital economy.',
    },
    {
      icon: Users,
      title: 'Community',
      description: 'We foster a vibrant learning community where students collaborate, share knowledge, and support each other on their educational journey.',
    },
    {
      icon: Award,
      title: 'Excellence',
      description: 'Our commitment to quality education means expert instructors, practical curriculum, and continuous improvement in all we do.',
    },
  ]

  const team = [
    {
      name: 'Dr. Rajesh Kumar',
      role: 'Founder & Director',
      bio: '20+ years in software development and technical education',
    },
    {
      name: 'Priya Sharma',
      role: 'Head of Curriculum',
      bio: 'Expert in web development with experience at leading tech companies',
    },
    {
      name: 'Amit Patel',
      role: 'Lead Instructor',
      bio: 'Full-stack developer and tech mentor with 15+ years of experience',
    },
    {
      name: 'Sarah Johnson',
      role: 'Student Success Manager',
      bio: 'Dedicated to ensuring every student achieves their learning goals',
    },
  ]

  return (
    <div className="min-h-screen flex flex-col bg-background">
      <Header />

      <main className="flex-1">
        {/* Hero Section */}
        <section className="px-4 py-12 md:py-24 border-b border-border bg-primary/5">
          <div className="container mx-auto max-w-4xl text-center">
            <h1 className="text-4xl md:text-5xl font-bold mb-6">About TECHBES</h1>
            <p className="text-lg text-muted-foreground">
              We&apos;re dedicated to transforming careers through high-quality technical education and professional development.
            </p>
          </div>
        </section>

        {/* Story Section */}
        <section className="px-4 py-12 md:py-16 border-b border-border">
          <div className="container mx-auto max-w-4xl">
            <h2 className="text-3xl font-bold mb-6">Our Story</h2>
            <div className="space-y-6 text-muted-foreground leading-relaxed">
              <p>
                TECHBES was founded on the belief that quality technical education should be accessible to everyone. With years of experience in the technology industry, our founders recognized a gap in the market: the need for practical, industry-relevant training delivered by experienced professionals.
              </p>
              <p>
                Since our inception, we&apos;ve trained hundreds of students who have gone on to successful careers at leading technology companies. We&apos;re proud of the impact we&apos;ve made in the lives of our students and the communities we serve.
              </p>
              <p>
                Today, TECHBES continues to evolve, offering cutting-edge courses that keep pace with the rapidly changing technology landscape. Our commitment remains unchanged: to provide the best possible learning experience for every student who walks through our doors.
              </p>
            </div>
          </div>
        </section>

        {/* Values Section */}
        <section className="px-4 py-12 md:py-16 border-b border-border">
          <div className="container mx-auto max-w-6xl">
            <h2 className="text-3xl font-bold mb-12 text-center">Our Values</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {values.map((value, index) => {
                const Icon = value.icon
                return (
                  <Card key={index} className="border border-border">
                    <CardHeader>
                      <div className="w-12 h-12 rounded-lg bg-primary/10 flex items-center justify-center mb-4">
                        <Icon className="w-6 h-6 text-primary" />
                      </div>
                      <CardTitle>{value.title}</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <p className="text-muted-foreground">{value.description}</p>
                    </CardContent>
                  </Card>
                )
              })}
            </div>
          </div>
        </section>

        {/* Team Section */}
        <section className="px-4 py-12 md:py-16 border-b border-border">
          <div className="container mx-auto max-w-6xl">
            <h2 className="text-3xl font-bold mb-12 text-center">Our Leadership Team</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              {team.map((member, index) => (
                <Card key={index} className="border border-border text-center">
                  <CardHeader>
                    <div className="w-24 h-24 rounded-full bg-primary/10 mx-auto mb-4 flex items-center justify-center">
                      <span className="text-2xl font-bold text-primary">
                        {member.name.charAt(0)}
                      </span>
                    </div>
                    <CardTitle className="text-lg">{member.name}</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <p className="text-sm font-medium text-primary mb-2">{member.role}</p>
                    <p className="text-sm text-muted-foreground">{member.bio}</p>
                  </CardContent>
                </Card>
              ))}
            </div>
          </div>
        </section>

        {/* Stats Section */}
        <section className="px-4 py-12 md:py-16">
          <div className="container mx-auto max-w-4xl">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
              <div>
                <p className="text-4xl md:text-5xl font-bold text-primary mb-2">500+</p>
                <p className="text-muted-foreground">Students Trained</p>
              </div>
              <div>
                <p className="text-4xl md:text-5xl font-bold text-primary mb-2">15+</p>
                <p className="text-muted-foreground">Expert Instructors</p>
              </div>
              <div>
                <p className="text-4xl md:text-5xl font-bold text-primary mb-2">20+</p>
                <p className="text-muted-foreground">Courses Offered</p>
              </div>
            </div>
          </div>
        </section>
      </main>

      <Footer />
    </div>
  )
}
