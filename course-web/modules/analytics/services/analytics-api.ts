export async function fetchVisitorDashboard() {
  const res = await fetch('/api/analytics/dashboard', { cache: 'no-store' })
  if (!res.ok) throw new Error('Failed to fetch analytics dashboard')
  return res.json()
}
