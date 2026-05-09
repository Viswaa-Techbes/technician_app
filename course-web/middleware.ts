import { NextResponse } from 'next/server'
import { type NextRequest } from 'next/server'

export async function middleware(request: NextRequest) {
  const response = NextResponse.next({ request });
  
  // Fire and forget visitor tracking
  const { pathname } = request.nextUrl
  if (!pathname.startsWith('/api') && !pathname.startsWith('/_next') && !pathname.match(/\.(png|jpg|jpeg|gif|webp|svg|ico)$/)) {
    const ip = request.ip || request.headers.get('x-forwarded-for') || 'unknown'
    const userAgent = request.headers.get('user-agent') || 'unknown'
    const referral = request.headers.get('referer') || ''
    
    let sessionId = request.cookies.get('tb_session_id')?.value;
    if (!sessionId) {
      sessionId = crypto.randomUUID();
      response.cookies.set('tb_session_id', sessionId, { maxAge: 60 * 60 * 24 * 365, path: '/' });
    }

    // We don't await this to avoid blocking the response
    fetch(`${process.env.BACKEND_API_URL || 'http://localhost:5000'}/api/v2/analytics/visitors/track`, {
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
