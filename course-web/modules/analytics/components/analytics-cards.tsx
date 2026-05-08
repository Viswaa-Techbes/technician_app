'use client'

export function AnalyticsCards({ data }: { data: any }) {
  const cards = [
    { label: 'Total Visitors', value: data?.totalVisitors ?? 0 },
    { label: 'Today Visitors', value: data?.todayVisitors ?? 0 },
    { label: 'Live Visitors', value: data?.liveVisitors ?? 0 },
    { label: 'Top Pages', value: data?.topPages?.length ?? 0 },
  ]

  return (
    <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
      {cards.map((card) => (
        <div key={card.label} className="rounded-xl bg-white p-4 shadow-sm">
          <div className="text-xs text-primary/70">{card.label}</div>
          <div className="text-2xl font-black text-primary">{card.value}</div>
        </div>
      ))}
    </div>
  )
}
