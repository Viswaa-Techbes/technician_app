/**
 * Centralized API configuration for TechBes CCTV Course platform.
 * Ensures the production frontend communicates with the verified production backend.
 */

export const PRODUCTION_API_URL = 'https://api.techbes.co.in';
export const LOCAL_DEV_API_URL = 'http://localhost:5000';

/**
 * Returns the backend API base URL with strict environment & hostname checking.
 * Under NO circumstance will a non-localhost browser runtime connect to localhost:5000.
 */
export function getApiBaseUrl(): string {
  // 1. Browser runtime: inspect window.location.hostname
  if (typeof window !== 'undefined') {
    const hostname = window.location.hostname;
    // Only permit localhost if the user is browsing on localhost or 127.0.0.1
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
      return (process.env.NEXT_PUBLIC_API_BASE_URL || LOCAL_DEV_API_URL).replace(/\/$/, '');
    }
    // In production (e.g. skills.techbes.co.in, techbes.co.in, vercel.app), NEVER use localhost
    const envUrl = process.env.NEXT_PUBLIC_API_BASE_URL;
    if (envUrl && !envUrl.includes('localhost') && !envUrl.includes('127.0.0.1')) {
      return envUrl.replace(/\/$/, '');
    }
    return PRODUCTION_API_URL;
  }

  // 2. Server-side runtime (SSR / SSG)
  if (process.env.NODE_ENV === 'production') {
    const envUrl = process.env.NEXT_PUBLIC_API_BASE_URL || process.env.BACKEND_API_URL;
    if (envUrl && !envUrl.includes('localhost') && !envUrl.includes('127.0.0.1')) {
      return envUrl.replace(/\/$/, '');
    }
    return PRODUCTION_API_URL;
  }

  return (process.env.NEXT_PUBLIC_API_BASE_URL || LOCAL_DEV_API_URL).replace(/\/$/, '');
}
