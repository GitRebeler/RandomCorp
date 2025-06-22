import {
  AccountCircle,
  Article,
  Brightness4,
  Brightness7,
  Close,
  Menu as MenuIcon,
  PlayArrow,
  Search
} from '@mui/icons-material';
import {
  AppBar,
  Box,
  Button,
  Container,
  createTheme,
  CssBaseline,
  Divider,
  IconButton,
  InputAdornment,
  Menu,
  MenuItem,
  Stack,
  TextField,
  ThemeProvider,
  Toolbar,
  Typography,
  useMediaQuery,
} from '@mui/material';
import { styled } from '@mui/material/styles';
import React, { useEffect, useMemo, useState } from 'react';
import { Route, BrowserRouter as Router, Routes, useLocation, useNavigate } from 'react-router-dom';

// Import components
import AppBreadcrumbs from './components/AppBreadcrumbs';
import HomePage from './components/HomePage';
import RandomCorpLogo from './components/RandomCorpLogo';
import ReportingPage from './components/ReportingPage';
import VideosPage from './components/VideosPage';

// Create dynamic theme function
const createAppTheme = (darkMode: boolean) => createTheme({
  palette: {
    mode: darkMode ? 'dark' : 'light',
    primary: {
      main: '#0078d4', // Microsoft blue
    },
    secondary: {
      main: '#6c757d', // Grey color
    },
    background: {
      default: darkMode ? '#121212' : '#f8f9fa',
      paper: darkMode ? '#1e1e1e' : '#ffffff',
    },
    text: {
      primary: darkMode ? '#ffffff' : '#323130',
      secondary: darkMode ? '#b3b3b3' : '#605e5c',
    },
  },
  typography: {
    fontFamily: '"Segoe UI", -apple-system, BlinkMacSystemFont, Roboto, "Helvetica Neue", sans-serif',
    h1: {
      fontSize: '2.5rem',
      fontWeight: 600,
      marginBottom: '1rem',
    },
    h2: {
      fontSize: '1.75rem',
      fontWeight: 500,
      marginBottom: '0.75rem',
    },
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',
          borderRadius: '4px',
          padding: '8px 24px',
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          marginBottom: '16px',
        },
      },
    },
    MuiAppBar: {
      styleOverrides: {
        root: {
          backgroundColor: darkMode ? '#1e1e1e' : '#ffffff',
          borderBottom: `1px solid ${darkMode ? '#323130' : '#e5e5e5'}`,
          boxShadow: darkMode 
            ? '0 1px 2px rgba(0,0,0,0.3)' 
            : '0 1px 2px rgba(0,0,0,0.1)',
        },
      },
    },
  },
});

// Navigation styled components
const NavButton = styled(Button)(({ theme }) => ({
  color: theme.palette.text.primary,
  textTransform: 'none',
  fontWeight: 400,
  padding: '8px 16px',
  minWidth: 'auto',
  '&:hover': {
    backgroundColor: theme.palette.action.hover,
  },
}));

const SearchField = styled(TextField)(({ theme }) => ({
  '& .MuiOutlinedInput-root': {
    backgroundColor: theme.palette.mode === 'dark' ? '#2d2d2d' : '#f3f2f1',
    border: 'none',
    borderRadius: '4px',
    height: '32px',
    fontSize: '14px',
    '& fieldset': {
      border: 'none',
    },
    '&:hover fieldset': {
      border: 'none',
    },
    '&.Mui-focused fieldset': {
      border: `1px solid ${theme.palette.primary.main}`,
    },
  },
  '& .MuiOutlinedInput-input': {
    padding: '6px 8px',
    '&::placeholder': {
      color: theme.palette.text.secondary,
      opacity: 1,
    },
  },
}));

// Main App Layout Component
interface AppLayoutProps {
  darkMode: boolean;
  toggleDarkMode: () => void;
}

const AppLayout: React.FC<AppLayoutProps> = ({ darkMode, toggleDarkMode }) => {
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [searchValue, setSearchValue] = useState('');
  
  const navigate = useNavigate();
  const location = useLocation();
  
  const isMobile = useMediaQuery((theme: any) => theme.breakpoints.down('md'));

  const handleMenuOpen = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleMobileMenuToggle = () => {
    setMobileMenuOpen(!mobileMenuOpen);
  };

  const handleBrandingClick = () => {
    navigate('/');
    setMobileMenuOpen(false);
  };

  const handleNavigation = (path: string) => {
    navigate(path);
    setMobileMenuOpen(false);
  };

  return (
    <>
      {/* Navigation Bar */}
      <AppBar position="static" elevation={0}>
        <Toolbar sx={{ minHeight: '48px !important', px: 2 }}>
          {/* Mobile menu button */}
          {isMobile && (
            <IconButton
              edge="start"
              color="inherit"
              aria-label="menu"
              onClick={handleMobileMenuToggle}
              sx={{ mr: 1, color: 'text.primary' }}
            >
              {mobileMenuOpen ? <Close /> : <MenuIcon />}
            </IconButton>
          )}          {/* Random Corp branding - clickable */}
          <RandomCorpLogo 
            size={isMobile ? 32 : 40}
            variant={isMobile ? 'compact' : 'default'}
            onClick={handleBrandingClick}
          />

          {/* Desktop Navigation Items */}
          {!isMobile && (
            <Stack direction="row" spacing={1} sx={{ flexGrow: 1 }}>
              <NavButton 
                startIcon={<Article />}
                onClick={() => handleNavigation('/reporting')}
                sx={{ 
                  backgroundColor: location.pathname === '/reporting' ? 'action.selected' : 'transparent'
                }}
              >
                Reporting
              </NavButton>
              <NavButton 
                startIcon={<PlayArrow />}
                onClick={() => handleNavigation('/videos')}
                sx={{ 
                  backgroundColor: location.pathname === '/videos' ? 'action.selected' : 'transparent'
                }}
              >
                Videos
              </NavButton>
            </Stack>
          )}

          {/* Search - Desktop */}
          {!isMobile && (
            <SearchField
              placeholder="Search"
              value={searchValue}
              onChange={(e) => setSearchValue(e.target.value)}
              size="small"
              sx={{ width: 200, mr: 2 }}
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <Search sx={{ fontSize: 16, color: 'text.secondary' }} />
                  </InputAdornment>
                ),
              }}
            />
          )}          {/* User actions */}
          <IconButton 
            color="inherit" 
            onClick={toggleDarkMode}
            aria-label="toggle dark mode"
            title={darkMode ? 'Switch to light mode' : 'Switch to dark mode'}
            sx={{ mr: 1, color: 'text.primary' }}
          >
            {darkMode ? <Brightness7 /> : <Brightness4 />}
          </IconButton>

          {!isMobile && (
            <Button
              startIcon={<AccountCircle />}
              onClick={handleMenuOpen}
              sx={{ 
                color: 'text.primary',
                textTransform: 'none',
                minWidth: 'auto'
              }}
            >
              Sign in
            </Button>
          )}

          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'right',
            }}
            transformOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
          >
            <MenuItem onClick={handleMenuClose}>Profile</MenuItem>
            <MenuItem onClick={handleMenuClose}>Settings</MenuItem>
            <Divider />
            <MenuItem onClick={handleMenuClose}>Sign out</MenuItem>
          </Menu>
        </Toolbar>

        {/* Mobile Navigation Menu */}
        {isMobile && mobileMenuOpen && (
          <Box sx={{ 
            borderTop: 1, 
            borderColor: 'divider',
            backgroundColor: 'background.paper',
            pb: 2
          }}>
            {/* Mobile Search */}
            <Box sx={{ p: 2 }}>
              <SearchField
                placeholder="Search"
                value={searchValue}
                onChange={(e) => setSearchValue(e.target.value)}
                size="small"
                fullWidth
                InputProps={{
                  startAdornment: (
                    <InputAdornment position="start">
                      <Search sx={{ fontSize: 16, color: 'text.secondary' }} />
                    </InputAdornment>
                  ),
                }}
              />
            </Box>

            {/* Mobile Navigation Items */}
            <Stack spacing={0} sx={{ px: 2 }}>
              <NavButton 
                startIcon={<Article />} 
                fullWidth 
                onClick={() => handleNavigation('/reporting')}
                sx={{ 
                  justifyContent: 'flex-start', 
                  py: 1.5,
                  backgroundColor: location.pathname === '/reporting' ? 'action.selected' : 'transparent'
                }}
              >
                Reporting
              </NavButton>
              <NavButton 
                startIcon={<PlayArrow />} 
                fullWidth 
                onClick={() => handleNavigation('/videos')}
                sx={{ 
                  justifyContent: 'flex-start', 
                  py: 1.5,
                  backgroundColor: location.pathname === '/videos' ? 'action.selected' : 'transparent'
                }}
              >
                Videos
              </NavButton>
              
              <Divider sx={{ my: 1 }} />
              
              <Button
                startIcon={<AccountCircle />}
                onClick={handleMenuOpen}
                fullWidth
                sx={{ 
                  color: 'text.primary',
                  textTransform: 'none',
                  justifyContent: 'flex-start',
                  py: 1.5
                }}
              >
                Sign in
              </Button>
            </Stack>
          </Box>
        )}
      </AppBar>

      {/* Breadcrumbs */}
      <AppBreadcrumbs />

      {/* Main Content */}
      <Container maxWidth="xl" sx={{ py: 2 }}>
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/reporting" element={<ReportingPage />} />
          <Route path="/videos" element={<VideosPage />} />
        </Routes>
      </Container>

      {/* Footer */}
      <Box sx={{ mt: 6, mb: 4, textAlign: 'center' }}>
        <Typography variant="body2" color="text.secondary">
          © 2025 Random Corp. All rights reserved.
        </Typography>
      </Box>
    </>
  );
};

function App() {
  // Dark mode detection and state
  const prefersDarkMode = useMediaQuery('(prefers-color-scheme: dark)');
  const [darkMode, setDarkMode] = useState(() => {
    const saved = localStorage.getItem('darkMode');
    return saved !== null ? JSON.parse(saved) : prefersDarkMode;
  });

  // Create theme based on dark mode state
  const theme = useMemo(() => createAppTheme(darkMode), [darkMode]);

  // Save dark mode preference to localStorage
  useEffect(() => {
    localStorage.setItem('darkMode', JSON.stringify(darkMode));
  }, [darkMode]);

  // Update dark mode when system preference changes (if user hasn't manually set it)
  useEffect(() => {
    const saved = localStorage.getItem('darkMode');
    if (saved === null) {
      setDarkMode(prefersDarkMode);
    }
  }, [prefersDarkMode]);
  const toggleDarkMode = () => {
    setDarkMode(!darkMode);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <AppLayout darkMode={darkMode} toggleDarkMode={toggleDarkMode} />
      </Router>
    </ThemeProvider>
  );
}

export default App;
