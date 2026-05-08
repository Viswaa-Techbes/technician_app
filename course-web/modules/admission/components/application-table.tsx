'use client'

import type { AdmissionApplication } from '@/modules/admission/types'

interface Props {
  data: AdmissionApplication[]
  loading: boolean
}

export function ApplicationTable({ data, loading }: Props) {
  if (loading) {
    return <div className="animate-pulse rounded-xl bg-white p-6 text-primary">Loading applications...</div>
  }

  if (!data.length) {
    return <div className="rounded-xl border border-dashed border-primary/30 bg-white p-6">No applications found.</div>
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-primary/10 bg-white">
      <table className="w-full min-w-[1000px] text-left text-sm">
        <thead className="bg-primary/5">
          <tr>
            <th className="p-3">Student Name</th>
            <th className="p-3">Mobile</th>
            <th className="p-3">Qualification</th>
            <th className="p-3">Program Type</th>
            <th className="p-3">Financial Status</th>
            <th className="p-3">Payment Status</th>
            <th className="p-3">Application Status</th>
            <th className="p-3">Assigned Course</th>
            <th className="p-3">Assigned Internship</th>
            <th className="p-3">Created Date</th>
          </tr>
        </thead>
        <tbody>
          {data.map((row) => (
            <tr key={row._id} className="border-t border-primary/5">
              <td className="p-3 font-semibold">{row.fullName}</td>
              <td className="p-3">{row.phone}</td>
              <td className="p-3">{row.qualification}</td>
              <td className="p-3 capitalize">{row.programType?.replaceAll('_', ' ')}</td>
              <td className="p-3">{row.financialStability || '-'}</td>
              <td className="p-3 capitalize">{row.paymentStatus?.replaceAll('_', ' ')}</td>
              <td className="p-3 capitalize">{row.admissionStatus?.replaceAll('_', ' ')}</td>
              <td className="p-3">{row.assignedCourse || '-'}</td>
              <td className="p-3">{row.assignedInternship || '-'}</td>
              <td className="p-3">{new Date(row.createdAt).toLocaleDateString()}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
