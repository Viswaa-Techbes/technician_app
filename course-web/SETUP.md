# TECHBES Training Institute - Setup Guide

## Backend Setup

The course web now uses the shared Node/Mongo backend instead of Supabase. The backend exposes these Render-backed APIs:

- `GET/POST /api/v2/courses`
- `GET/DELETE /api/v2/courses/:id`
- `GET/POST /api/v2/course-enrollments`
- `PATCH /api/v2/course-enrollments/:id`
- `GET/POST /api/v2/course-inquiries`
- `PATCH /api/v2/course-inquiries/:id`
- `POST /api/v2/course-admin/login`

## Initial Admin Setup

To access the course admin dashboard, configure these variables on the backend Render service:

- `COURSE_ADMIN_EMAIL`
- `COURSE_ADMIN_PASSWORD`
- `COURSE_ADMIN_NAME` optional

## Environment Variables

Set the backend URL in the course web environment:

- `BACKEND_API_URL=https://api.techbes.co.in`
- `NEXT_PUBLIC_BACKEND_API_URL=https://api.techbes.co.in`

For email functionality with Resend, add:
- `RESEND_API_KEY` - Your Resend API key from https://resend.com

## Running the Application

```bash
# Install dependencies (if not already done)
pnpm install

# Run development server
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start
```

## Feature Overview

### Public Pages
- **Home** (`/`) - Landing page with featured courses
- **Courses** (`/courses`) - Browse all published courses
- **Course Details** (`/courses/[id]`) - Individual course page with enrollment form
- **About** (`/about`) - Information about TECHBES
- **Contact** (`/contact`) - Contact form for inquiries

### Admin Dashboard
- **Login** (`/admin/login`) - Admin authentication
- **Dashboard** (`/admin/dashboard`) - Overview with statistics
- **Courses Management** (`/admin/courses`) - Create, edit, delete courses
- **Enrollments** (`/admin/enrollments`) - View and manage student enrollments
- **Inquiries** (`/admin/inquiries`) - View and respond to contact form submissions
- **Settings** (`/admin/settings`) - Platform configuration

### Key Features
- ✅ Student enrollment with automatic email confirmation
- ✅ Contact form with inquiry tracking
- ✅ Admin dashboard for course and enrollment management
- ✅ Email integration with Resend for notifications
- ✅ WhatsApp Click-to-Chat integration
- ✅ Row-level security for data protection
- ✅ Responsive design for mobile and desktop

## Sample Courses

The database comes with 5 pre-loaded courses:
1. Web Development Fundamentals (Beginner)
2. Advanced React Development (Intermediate)
3. Python for Data Science (Intermediate)
4. Full Stack Web Development (Advanced)
5. UI/UX Design Masterclass (Beginner)

## Email Configuration

The platform uses Resend for sending emails. Email templates are sent for:
- **Enrollment Confirmation** - When a student enrolls in a course
- **Contact Form Confirmation** - When someone submits the contact form
- **Admin Notification** - When a new inquiry is submitted (optional)

To enable emails:
1. Sign up for Resend at https://resend.com
2. Get your API key
3. Add `RESEND_API_KEY` to your environment variables

## Support & Contact

For issues or questions:
- Email: support@techbes.com
- WhatsApp: Click the WhatsApp icon on any page

## Next Steps

1. Create your admin user
2. Add your Resend API key for email functionality
3. Customize the courses and platform content
4. Deploy to Vercel
