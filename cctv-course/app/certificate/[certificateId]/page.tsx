import Certificate from '../../../../models/Certificate'
import connect from '../../../../lib/mongodb'

export default async function Page({ params }: { params: { certificateId: string } }) {
  await connect()
  const cert = await Certificate.findOne({ certificateId: params.certificateId })
  if (!cert) return <div className="container px-4 py-10">Certificate not found or invalid.</div>

  return (
    <div className="container px-4 py-10">
      <h1 className="text-2xl font-semibold">Certificate Verification</h1>
      <div className="mt-4 bg-slate-900 p-6 rounded">
        <div className="text-green-400 font-bold">Valid Certificate</div>
        <div className="mt-3">Certificate ID: {cert.certificateId}</div>
        <div>Participant: {cert.participantName}</div>
        <div>Program: {cert.programName}</div>
        <div>Issue Date: {cert.issueDate?.toDateString()}</div>
      </div>
    </div>
  )
}
