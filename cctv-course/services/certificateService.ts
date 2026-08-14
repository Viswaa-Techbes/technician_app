import { PDFDocument, rgb, StandardFonts } from 'pdf-lib'
import QRCode from 'qrcode'
import fs from 'fs'
import path from 'path'

export async function generateCertificatePdf({ participantName, programName, issueDate, certificateId }: any) {
  const pdfDoc = await PDFDocument.create()
  const page = pdfDoc.addPage([842, 595]) // landscape A4-ish
  const times = await pdfDoc.embedFont(StandardFonts.Helvetica)

  page.drawText('TECHBES', { x: 40, y: 520, size: 30, font: times, color: rgb(0.9, 0.7, 0.2) })
  page.drawText('CERTIFICATE OF PARTICIPATION', { x: 40, y: 480, size: 20, font: times })
  page.drawText(`This certificate is proudly presented to`, { x: 40, y: 440, size: 12, font: times })
  page.drawText(participantName, { x: 40, y: 410, size: 24, font: times })
  page.drawText(`For participating in ${programName}`, { x: 40, y: 380, size: 12, font: times })
  page.drawText(`Certificate ID: ${certificateId}`, { x: 40, y: 340, size: 10, font: times })

  const qrData = `${process.env.NEXT_PUBLIC_APP_URL}/certificate/${certificateId}`
  const qrPng = await QRCode.toDataURL(qrData)
  const qrImage = qrPng.split(',')[1]
  const qrUint8 = Buffer.from(qrImage, 'base64')
  const qrEmbed = await pdfDoc.embedPng(qrUint8)
  page.drawImage(qrEmbed, { x: 650, y: 300, width: 120, height: 120 })

  const pdfBytes = await pdfDoc.save()
  const outPath = path.join(process.cwd(), 'public', 'certificates', `${certificateId}.pdf`)
  fs.mkdirSync(path.dirname(outPath), { recursive: true })
  fs.writeFileSync(outPath, pdfBytes)
  return `/certificates/${certificateId}.pdf`
}
