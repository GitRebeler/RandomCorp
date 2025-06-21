import React, { useState } from 'react';
import {
  ThemeProvider,
  createTheme,
  CssBaseline,
  AppBar,
  Toolbar,
  Typography,
  Container,
  Box,
  TextField,
  Button,
  Paper,
  Card,
  CardContent,
  Alert,
  CircularProgress
} from '@mui/material';
import { styled } from '@mui/material/styles';

// Create theme similar to Microsoft Learn
const theme = createTheme({
  palette: {
    primary: {
      main: '#0078d4', // Microsoft blue
    },
    secondary: {
      main: '#6c757d', // Grey color
    },
    background: {
      default: '#f8f9fa',
      paper: '#ffffff',
    },
    text: {
      primary: '#323130',
      secondary: '#605e5c',
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
  },
});

// Styled components
const HeaderSection = styled(Box)(({ theme }) => ({
  background: 'linear-gradient(135deg, #0078d4 0%, #106ebe 100%)',
  color: 'white',
  padding: theme.spacing(6, 0),
  textAlign: 'center',
}));

const Logo = styled(Box)({
  width: '60px',
  height: '60px',
  backgroundColor: '#6c757d',
  borderRadius: '8px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  marginBottom: '16px',
  fontSize: '24px',
  fontWeight: 'bold',
  color: 'white',
  margin: '0 auto 16px',
});

const FormSection = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(4),
  marginTop: theme.spacing(4),
  borderRadius: '8px',
  boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
}));

const ResultSection = styled(Card)(({ theme }) => ({
  marginTop: theme.spacing(3),
  borderRadius: '8px',
  boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
}));

interface SubmissionResult {
  firstName: string;
  lastName: string;
  message: string;
}

function App() {
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [result, setResult] = useState<SubmissionResult | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!firstName.trim() || !lastName.trim()) {
      setError('Please fill in both first name and last name');
      return;
    }

    setLoading(true);
    setError(null);    try {
      const response = await fetch('/api/submit', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          firstName: firstName.trim(),
          lastName: lastName.trim(),
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      setResult(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'An error occurred while submitting');
    } finally {
      setLoading(false);
    }
  };

  const handleClear = () => {
    setFirstName('');
    setLastName('');
    setResult(null);
    setError(null);
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AppBar position="static" elevation={0}>
        <Toolbar>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Random Corp
          </Typography>
        </Toolbar>
      </AppBar>

      <HeaderSection>
        <Container maxWidth="md">
          <Logo>RC</Logo>
          <Typography variant="h1" component="h1" gutterBottom>
            Random Corp
          </Typography>
          <Typography variant="h6" sx={{ opacity: 0.9 }}>
            Welcome to our professional submission portal
          </Typography>
        </Container>
      </HeaderSection>

      <Container maxWidth="md">
        <FormSection>
          <Typography variant="h2" component="h2" gutterBottom>
            Submit Your Information
          </Typography>
          <Typography variant="body1" color="text.secondary" paragraph>
            Please provide your first and last name to get started.
          </Typography>

          {error && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {error}
            </Alert>
          )}

          <Box component="form" onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="First Name"
              variant="outlined"
              value={firstName}
              onChange={(e) => setFirstName(e.target.value)}
              disabled={loading}
              required
            />
            <TextField
              fullWidth
              label="Last Name"
              variant="outlined"
              value={lastName}
              onChange={(e) => setLastName(e.target.value)}
              disabled={loading}
              required
            />
            <Box sx={{ display: 'flex', gap: 2, mt: 2 }}>
              <Button
                type="submit"
                variant="contained"
                size="large"
                disabled={loading}
                sx={{ minWidth: 120 }}
              >
                {loading ? <CircularProgress size={24} /> : 'Submit'}
              </Button>
              <Button
                type="button"
                variant="outlined"
                size="large"
                onClick={handleClear}
                disabled={loading}
              >
                Clear
              </Button>
            </Box>
          </Box>
        </FormSection>

        {result && (
          <ResultSection>
            <CardContent>
              <Typography variant="h6" component="h3" gutterBottom>
                Submission Result
              </Typography>
              <Typography variant="body1" paragraph>
                <strong>First Name:</strong> {result.firstName}
              </Typography>
              <Typography variant="body1" paragraph>
                <strong>Last Name:</strong> {result.lastName}
              </Typography>
              <Typography variant="body1" color="primary">
                <strong>Message:</strong> {result.message}
              </Typography>
            </CardContent>
          </ResultSection>
        )}

        <Box sx={{ mt: 6, mb: 4, textAlign: 'center' }}>
          <Typography variant="body2" color="text.secondary">
            © 2025 Random Corp. All rights reserved.
          </Typography>
        </Box>
      </Container>
    </ThemeProvider>
  );
}

export default App;
