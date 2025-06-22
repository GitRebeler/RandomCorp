import { Home, NavigateNext } from '@mui/icons-material';
import { Box, Breadcrumbs, Link, Typography } from '@mui/material';
import React from 'react';
import { Link as RouterLink, useLocation } from 'react-router-dom';

interface BreadcrumbItem {
  label: string;
  path: string;
  icon?: React.ReactNode;
}

const getBreadcrumbs = (pathname: string): BreadcrumbItem[] => {
  const breadcrumbs: BreadcrumbItem[] = [
    { label: 'Home', path: '/', icon: <Home sx={{ mr: 0.5, fontSize: 16 }} /> }
  ];

  if (pathname === '/reporting') {
    breadcrumbs.push({ label: 'Reporting', path: '/reporting' });
  } else if (pathname === '/videos') {
    breadcrumbs.push({ label: 'Videos', path: '/videos' });
  }

  return breadcrumbs;
};

const AppBreadcrumbs: React.FC = () => {
  const location = useLocation();
  const breadcrumbs = getBreadcrumbs(location.pathname);

  // Don't show breadcrumbs on home page
  if (location.pathname === '/') {
    return null;
  }

  return (
    <Box sx={{ py: 2, px: 3, borderBottom: 1, borderColor: 'divider' }}>
      <Breadcrumbs
        separator={<NavigateNext fontSize="small" />}
        aria-label="breadcrumb"
      >
        {breadcrumbs.map((breadcrumb, index) => {
          const isLast = index === breadcrumbs.length - 1;
          
          if (isLast) {
            return (
              <Typography 
                key={breadcrumb.path}
                color="text.primary" 
                sx={{ display: 'flex', alignItems: 'center' }}
              >
                {breadcrumb.icon}
                {breadcrumb.label}
              </Typography>
            );
          }

          return (
            <Link
              key={breadcrumb.path}
              component={RouterLink}
              to={breadcrumb.path}
              underline="hover"
              color="inherit"
              sx={{ display: 'flex', alignItems: 'center' }}
            >
              {breadcrumb.icon}
              {breadcrumb.label}
            </Link>
          );
        })}
      </Breadcrumbs>
    </Box>
  );
};

export default AppBreadcrumbs;
