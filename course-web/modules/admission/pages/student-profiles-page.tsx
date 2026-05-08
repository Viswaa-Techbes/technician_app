export default function StudentProfilesPage() {
  return (
    <div className="rounded-xl bg-white p-6">
      <h2 className="text-xl font-black text-primary">Student Profiles</h2>
      <p className="mt-2 text-sm text-primary/70">
        Detailed profile tabs (Personal, Parent, Education, Financial, Assignment, Payments, Documents) are enabled via
        `/api/admission/:id`.
      </p>
    </div>
  )
}
