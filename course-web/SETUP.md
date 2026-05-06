# TECHBES Training Institute - Setup Guide

## Database Setup

The database schema and sample courses have already been created in Supabase. The following tables are available:

- **courses** - Course catalog with pricing, duration, and instructor info
- **enrollments** - Student enrollments with payment tracking
- **inquiries** - Contact form submissions
- **email_logs** - Email delivery tracking
- **admins** - Admin user credentials

## Initial Admin Setup

To access the admin dashboard, you need to create an admin user:

1. Go to your Supabase dashboard
2. In the SQL editor, run the following command to create your first admin:

```sql
INSERT INTO public.admins (email, password_hash, name, is_active) VALUES
('admin@techbes.com', '$2b$10$...[your hashed password]...', 'Admin User', true);
```

**Important**: The password hash is a bcrypt hash. For testing, you can use an online bcrypt generator or create a script.

### Quick Admin Creation

For development, you can use Node.js to hash a password:

```bash
node -e "require('bcryptjs').hash('your-password', 10, (e, h) => console.log(h))"
```

Then insert it into the admins table.

## Environment Variables

All required environment variables are automatically set up by Supabase integration:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

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
