import { SvgIcon } from '@mui/material';
import React from 'react';

interface FaviconLogoProps {
  size?: number;
}

const FaviconLogo: React.FC<FaviconLogoProps> = ({ size = 32 }) => {
  return (
    <SvgIcon 
      sx={{ 
        width: size, 
        height: size,
      }}
      viewBox="0 0 32 32"
    >
      <defs>
        <linearGradient id="faviconGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#2196F3" />
          <stop offset="100%" stopColor="#1976D2" />
        </linearGradient>
      </defs>
      
      {/* Simple circular background */}
      <circle 
        cx="16" 
        cy="16" 
        r="15" 
        fill="url(#faviconGradient)"
      />
      
      {/* Simple R */}
      <path 
        d="M 6 8 L 6 24 M 6 8 L 14 8 Q 16 8 16 12 Q 16 16 14 16 L 6 16 M 12 16 L 16 24" 
        stroke="white" 
        strokeWidth="2" 
        fill="none" 
        strokeLinecap="round"
      />
      
      {/* Simple C */}
      <path 
        d="M 26 12 Q 22 8 18 12 Q 18 16 18 16 Q 18 20 22 20 Q 26 20 26 16" 
        stroke="white" 
        strokeWidth="2" 
        fill="none" 
        strokeLinecap="round"
      />
    </SvgIcon>
  );
};

export default FaviconLogo;
