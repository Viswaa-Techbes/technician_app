import crypto from 'crypto'
import { backendRequest } from '@/lib/backend-api'

export async function hashPassword(password: string): Promise<string> {
  return crypto.createHash('sha256').update(password).digest('hex')
}

export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  const passwordHash = await hashPassword(password)
  return passwordHash === hash
}

export async function loginAdmin(email: string, password: string) {
  const response = await backendRequest('/api/v2/course-admin/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    return { success: false, error: data.message || 'Invalid credentials' }
  }

  return { success: true, admin: data.admin }
}

export async function createAdminUser(
  email: string,
  password: string,
  name: string
) {
  const passwordHash = await hashPassword(password)
  return {
    success: false,
    error: `Create admin users in the backend environment. Suggested values: COURSE_ADMIN_EMAIL=${email}, COURSE_ADMIN_NAME=${name}, COURSE_ADMIN_PASSWORD=<password>. Local hash: ${passwordHash}`,
  }
}
