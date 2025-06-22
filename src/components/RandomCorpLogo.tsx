import { Box, SvgIcon } from '@mui/material';
import { styled } from '@mui/material/styles';
import React from 'react';

interface RandomCorpLogoProps {
  size?: number;
  color?: string;
  variant?: 'default' | 'compact' | 'icon-only';
  onClick?: () => void;
}

const LogoContainer = styled(Box)<{ clickable?: boolean }>(({ theme, clickable }) => ({
  display: 'flex',
  alignItems: 'center',
  cursor: clickable ? 'pointer' : 'default',
  transition: 'transform 0.2s ease-in-out',
  '&:hover': clickable ? {
    transform: 'scale(1.05)',
  } : {},
}));

const LogoText = styled('span')(({ theme }) => ({
  marginLeft: theme.spacing(1),
  fontWeight: 700,
  fontSize: '1.5rem',
  background: 'linear-gradient(45deg, #2196F3 30%, #21CBF3 90%)',
  WebkitBackgroundClip: 'text',
  WebkitTextFillColor: 'transparent',
  backgroundClip: 'text',
}));

const RandomCorpLogo: React.FC<RandomCorpLogoProps> = ({ 
  size = 40, 
  color = 'primary', 
  variant = 'default',
  onClick 
}) => {
  const LogoIcon = () => (
    <SvgIcon 
      sx={{ 
        width: size, 
        height: size,
        filter: 'drop-shadow(0 2px 4px rgba(0,0,0,0.1))'
      }}
      viewBox="0 0 100 100"
    >
      {/* Outer circle with gradient */}
      <defs>
        <linearGradient id="logoGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#2196F3" />
          <stop offset="50%" stopColor="#21CBF3" />
          <stop offset="100%" stopColor="#1976D2" />
        </linearGradient>
        <linearGradient id="letterGradient" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" stopColor="#FFFFFF" />
          <stop offset="100%" stopColor="#F0F8FF" />
        </linearGradient>
        <filter id="shadow">
          <feDropShadow dx="0" dy="2" stdDeviation="2" floodOpacity="0.3"/>
        </filter>
      </defs>
      
      {/* Main circle background */}
      <circle 
        cx="50" 
        cy="50" 
        r="45" 
        fill="url(#logoGradient)"
        filter="url(#shadow)"
      />
      
      {/* Inner circle for depth */}
      <circle 
        cx="50" 
        cy="50" 
        r="40" 
        fill="none" 
        stroke="rgba(255,255,255,0.2)" 
        strokeWidth="1"
      />
      
      {/* Letter R */}
      <g transform="translate(20, 25)">
        <path 
          d="M 0 0 L 0 40 M 0 0 L 15 0 Q 20 0 20 8 Q 20 16 15 16 L 0 16 M 12 16 L 20 40" 
          stroke="url(#letterGradient)" 
          strokeWidth="4" 
          fill="none" 
          strokeLinecap="round" 
          strokeLinejoin="round"
        />
      </g>
      
      {/* Letter C */}
      <g transform="translate(55, 25)">
        <path 
          d="M 20 8 Q 12 0 4 8 Q 0 12 0 20 Q 0 28 4 32 Q 12 40 20 32" 
          stroke="url(#letterGradient)" 
          strokeWidth="4" 
          fill="none" 
          strokeLinecap="round"
        />
      </g>
      
      {/* Decorative dots */}
      <circle cx="25" cy="75" r="2" fill="rgba(255,255,255,0.6)" />
      <circle cx="75" cy="75" r="2" fill="rgba(255,255,255,0.6)" />
      <circle cx="50" cy="15" r="1.5" fill="rgba(255,255,255,0.4)" />
    </SvgIcon>
  );

  if (variant === 'icon-only') {
    return (
      <LogoContainer clickable={!!onClick} onClick={onClick}>
        <LogoIcon />
      </LogoContainer>
    );
  }

  if (variant === 'compact') {
    return (
      <LogoContainer clickable={!!onClick} onClick={onClick}>
        <LogoIcon />
        <LogoText style={{ fontSize: '1.2rem' }}>RC</LogoText>
      </LogoContainer>
    );
  }

  return (
    <LogoContainer clickable={!!onClick} onClick={onClick}>
      <LogoIcon />
      <LogoText>Random Corp</LogoText>
    </LogoContainer>
  );
};

export default RandomCorpLogo;
