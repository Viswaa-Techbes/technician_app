import { Metadata } from 'next'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { SectionShell, Reveal, GlassCard } from '@/components/premium-ui'
import { Breadcrumbs } from '@/components/seo/Breadcrumbs'
import { ChevronRight, Calendar, User } from 'lucide-react'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Blog & Career Insights | TECHBES',
  description: 'Stay updated with the latest trends in CCTV, networking, and IT skills. Career tips, industry insights, and technical guides.',
}

const posts = [
  {
    title: 'Why CCTV Installation is the Fastest Growing Career in 2026',
    slug: 'cctv-career-growth-2026',
    date: 'May 10, 2026',
    author: 'TECHBES Team',
    excerpt: 'Discover why surveillance technology is booming and how you can capitalize on this industry growth.'
  },
  {
    title: 'Top 10 Networking Interview Questions for Freshers',
    slug: 'networking-interview-questions',
    date: 'May 08, 2026',
    author: 'IT Trainer',
    excerpt: 'Master your next interview with these essential networking questions and expert answers.'
  }
]

export default function BlogPage() {
  return (
    <main className="min-h-screen bg-[#F5F9FF]">
      <Header />
      <section className="pt-32 pb-16 px-6">
        <div className="container mx-auto max-w-7xl">
          <Breadcrumbs items={[{ label: 'Blog', href: '/blog' }]} />
          
          <Reveal>
            <h1 className="text-4xl md:text-6xl font-black text-primary mb-6">TECHBES <span className="text-accent">Blog</span></h1>
            <p className="text-xl text-foreground/60 mb-12">Insights, guides, and career tips for the next generation of IT professionals.</p>
          </Reveal>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {posts.map((post, i) => (
              <GlassCard key={post.slug} delay={i * 0.1}>
                <div className="p-8 space-y-4">
                  <div className="flex items-center gap-4 text-sm text-foreground/50">
                    <span className="flex items-center gap-1"><Calendar size={14} /> {post.date}</span>
                    <span className="flex items-center gap-1"><User size={14} /> {post.author}</span>
                  </div>
                  <h2 className="text-2xl font-bold text-primary hover:text-accent transition-colors">
                    <Link href={`/blog/${post.slug}`}>{post.title}</Link>
                  </h2>
                  <p className="text-foreground/60 leading-relaxed">{post.excerpt}</p>
                  <Link href={`/blog/${post.slug}`} className="inline-flex items-center gap-2 text-accent font-bold group">
                    Read More <ChevronRight size={18} className="group-hover:translate-x-1 transition-transform" />
                  </Link>
                </div>
              </GlassCard>
            ))}
          </div>
        </div>
      </section>
      <Footer />
    </main>
  )
}
