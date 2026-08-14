import React from 'react';
import { motion } from 'framer-motion';
import { IconType } from '@heroicons/react/24/solid';

interface FeatureCardProps {
  icon: IconType;
  title: string;
  description?: string;
}

export default function FeatureCard({ icon: Icon, title, description }: FeatureCardProps) {
  return (
    <motion.div
      whileHover={{ y: -4, boxShadow: '0 8px 20px rgba(0,0,0,0.2)' }}
      className="bg-white/5 backdrop-blur-sm rounded-xl border border-white/10 p-4 flex flex-col items-center text-center hover:border-yellow-400 transition"
    >
      <Icon className="h-8 w-8 text-yellow-300 mb-2" />
      <h3 className="text-sm font-medium text-white">{title}</h3>
      {description && <p className="mt-1 text-xs text-slate-300">{description}</p>}
    </motion.div>
  );
}
