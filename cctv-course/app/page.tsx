import Hero from '../components/Hero'
import RegistrationForm from '../components/RegistrationForm'

export default function Home() {
  return (
    <div className="container px-4 py-10">
      <Hero />
      <section className="mt-12">
        <h2 className="text-2xl font-semibold">Masterclass Overview</h2>
        <p className="mt-3 text-slate-300">Learn CCTV Installation, IP Networking, NVR Configuration, Mobile Viewing and Troubleshooting through a live practical masterclass.</p>
      </section>

      <section id="register" className="mt-12">
        <h2 className="text-2xl font-semibold">Register Now</h2>
        <div className="mt-4">
          <RegistrationForm />
        </div>
      </section>
    </div>
  )
}
