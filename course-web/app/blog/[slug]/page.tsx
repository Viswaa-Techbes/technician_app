import { Metadata } from 'next'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { SectionShell, Reveal } from '@/components/premium-ui'
import { Breadcrumbs } from '@/components/seo/Breadcrumbs'
import { JsonLd } from '@/components/seo/JsonLd'
import { Calendar, User, Clock } from 'lucide-react'

// This would normally come from a CMS or API
const getPost = (slug: string) => ({
  title: slug.split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' '),
  date: 'May 10, 2026',
  author: 'TECHBES Expert',
  content: 'Article content would go here. This is a placeholder for SEO structure demonstration.',
})

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const post = getPost(params.slug)
  return {
    title: `${post.title} | TECHBES Blog`,
    description: `Read about ${post.title} on the TECHBES blog. Insights into CCTV, networking, and IT skills.`,
  }
}

export default function BlogPost({ params }: { params: { slug: string } }) {
  const post = getPost(params.slug)
  
  const articleSchema = {
    "@context": "https://schema.org",
    "@type": "Article",
    "headline": post.title,
    "datePublished": "2026-05-10T08:00:00+08:00",
    "author": {
      "@type": "Person",
      "name": post.author
    }
  }

  return (
    <main className="min-h-screen bg-white">
      <JsonLd data={articleSchema} />
      <Header />
      <article className="pt-32 pb-16 px-6">
        <div className="container mx-auto max-w-4xl">
          <Breadcrumbs items={[
            { label: 'Blog', href: '/blog' },
            { label: post.title, href: `/blog/${params.slug}` }
          ]} />
          
          <Reveal>
            <header className="mb-12">
              <h1 className="text-4xl md:text-5xl font-black text-primary mb-6 leading-tight">{post.title}</h1>
              <div className="flex flex-wrap items-center gap-6 text-sm text-foreground/50 border-y border-foreground/5 py-4">
                <span className="flex items-center gap-2"><Calendar size={16} /> {post.date}</span>
                <span className="flex items-center gap-2"><User size={16} /> {post.author}</span>
                <span className="flex items-center gap-2"><Clock size={16} /> 5 min read</span>
              </div>
            </header>
            
            <div className="prose prose-lg max-w-none text-foreground/70 leading-relaxed">
              <p>
                In the rapidly evolving world of security and IT infrastructure, staying ahead of the curve is essential. 
                This article explores <strong>{post.title}</strong> and its implications for aspiring technicians and business owners.
              </p>
              {/* Actual content would be rendered here */}
              <div className="bg-[#F5F9FF] p-8 rounded-3xl my-10 border border-primary/5">
                <h2 className="text-2xl font-bold text-primary mb-4">Key Takeaways</h2>
                <ul className="space-y-3">
                  <li>Practical knowledge is the foundation of career growth.</li>
                  <li>Industry demand for skilled technicians is at an all-time high.</li>
                  <li>Certification and internships provide a competitive edge.</li>
                </ul>
              </div>
            </div>
          </Reveal>
        </div>
      </article>
      <Footer />
    </main>
  )
}
