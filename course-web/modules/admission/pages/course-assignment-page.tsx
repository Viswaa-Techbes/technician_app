export default function CourseAssignmentPage() {
  return (
    <div className="rounded-xl bg-white p-6">
      <h2 className="text-xl font-black text-primary">Course Assignment</h2>
      <p className="mt-2 text-sm text-primary/70">
        Assign courses manually for approved applications with `PATCH /api/admission/:id/assignment`.
      </p>
    </div>
  )
}
