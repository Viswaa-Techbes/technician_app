import { z } from 'zod'

export const visitorTrackSchema = z.object({
  page: z.string().min(1),
  eventType: z.enum(['page_view', 'service_viewed', 'booking_started', 'booking_completed', 'payment_completed']).optional(),
  serviceName: z.string().optional(),
})
