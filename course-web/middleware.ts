import { NextResponse } from 'next/server'
import { type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  const response = NextResponse.next({ request });
  
  // Fire and forget visitor tracking
  const { pathname } = request.nextUrl
  if (!pathname.startsWith('/api') && !pathname.startsWith('/_next') && !pathname.match(/\.(png|jpg|jpeg|gif|webp|svg|ico)$/)) {
    const ip = request.headers.get('x-forwarded-for')?.split(',')[0].trim() || request.ip || 'unknown'
    const userAgent = request.headers.get('user-agent') || 'unknown'
    const referral = request.headers.get('referer') || ''
    
    let sessionId = request.cookies.get('tb_session_id')?.value;
    if (!sessionId) {
      sessionId = crypto.randomUUID();
      response.cookies.set('tb_session_id', sessionId, { maxAge: 60 * 60 * 24 * 365, path: '/' });
    }

    const backendBase = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_BACKEND_API_URL || 'https://technician-app.onrender.com';
    const trackUrl = `${backendBase.replace(/\/$/, '')}/api/v2/analytics/visitors/track`;

    // We don't await this to avoid blocking the response
    fetch(trackUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': userAgent,
        'X-Forwarded-For': ip,
      },
      body: JSON.stringify({
        page: pathname,
        domain: 'skills.techbes.co.in',
        sessionId: sessionId,
        referral: referral,
        eventType: 'page_view'
      })
    }).catch(e => {}) // Ignore errors
  }

  return response;
}

export const config = {
  matcher: [
    /*
     * Match all request paths except:
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - images - .svg, .png, .jpg, .jpeg, .gif, .webp
     * Feel free to modify this pattern to include more paths.
     */
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
