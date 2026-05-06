import { createClient } from '@/lib/supabase/server'
import crypto from 'crypto'

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
  const supabase = await createClient()

  // Query admins table directly
  const { data: admin, error } = await supabase
    .from('admins')
    .select('*')
    .eq('email', email)
    .eq('is_active', true)
    .single()

  if (error || !admin) {
    return { success: false, error: 'Invalid credentials' }
  }

  // Verify password
  const passwordMatch = await verifyPassword(password, admin.password_hash)
  if (!passwordMatch) {
    return { success: false, error: 'Invalid credentials' }
  }

  // Create session in cookies
  const sessionData = {
    admin_id: admin.id,
    email: admin.email,
    name: admin.name,
  }

  return { success: true, admin: sessionData }
}

export async function createAdminUser(
  email: string,
  password: string,
  name: string
) {
  const supabase = await createClient()
  const passwordHash = await hashPassword(password)

  const { data, error } = await supabase
    .from('admins')
    .insert({
      email,
      password_hash: passwordHash,
      name,
    })
    .select()
    .single()

  if (error) {
    return { success: false, error: error.message }
  }

  return { success: true, admin: data }
}
