import {
    Alert,
    Box,
    Button,
    Card,
    CardContent,
    CircularProgress,
    Container,
    Paper,
    TextField,
    Typography,
} from '@mui/material';
import { styled } from '@mui/material/styles';
import React, { useState } from 'react';
import RandomCorpLogo from './RandomCorpLogo';

const HeaderSection = styled(Box)(({ theme }) => ({
  background: theme.palette.mode === 'dark' 
    ? 'linear-gradient(135deg, #1e3a8a 0%, #1e40af 100%)'
    : 'linear-gradient(135deg, #0078d4 0%, #106ebe 100%)',
  color: 'white',
  padding: theme.spacing(6, 0),
  textAlign: 'center',
}));

const Logo = styled(Box)(({ theme }) => ({
  width: '60px',
  height: '60px',
  backgroundColor: theme.palette.secondary.main,
  borderRadius: '8px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  marginBottom: '16px',
  fontSize: '24px',
  fontWeight: 'bold',
  color: 'white',
  margin: '0 auto 16px',
}));

const FormSection = styled(Paper)(({ theme }) => ({
  padding: theme.spacing(4),
  marginTop: theme.spacing(4),
  borderRadius: '8px',
  boxShadow: theme.palette.mode === 'dark' 
    ? '0 2px 8px rgba(0,0,0,0.3)' 
    : '0 2px 8px rgba(0,0,0,0.1)',
}));

const ResultSection = styled(Card)(({ theme }) => ({
  marginTop: theme.spacing(3),
  borderRadius: '8px',
  boxShadow: theme.palette.mode === 'dark' 
    ? '0 2px 8px rgba(0,0,0,0.3)' 
    : '0 2px 8px rgba(0,0,0,0.1)',
}));

interface SubmissionResult {
  firstName: string;
  lastName: string;
  message: string;
}

const HomePage: React.FC = () => {
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
    setError(null);
    
    try {
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
    <>      <HeaderSection>
        <Container maxWidth="md">
          <Box sx={{ display: 'flex', justifyContent: 'center', mb: 2 }}>
            <RandomCorpLogo size={80} variant="icon-only" />
          </Box>
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

          <Box component="form" onSubmit={handleSubmit} sx={{ mt: 2 }}>
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

            <Box sx={{ display: 'flex', gap: 2, mt: 3 }}>
              <Button
                type="submit"
                variant="contained"
                size="large"
                disabled={loading}
                sx={{ flex: 1 }}
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

          {result && (
            <ResultSection>
              <CardContent>
                <Typography variant="h6" component="h3" gutterBottom color="primary">
                  Submission Successful! ✅
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>Name:</strong> {result.firstName} {result.lastName}
                </Typography>
                <Typography variant="body1" paragraph>
                  <strong>Message:</strong> {result.message}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  Your submission has been processed successfully. Thank you for using Random Corp!
                </Typography>
              </CardContent>
            </ResultSection>
          )}
        </FormSection>
      </Container>
    </>
  );
};

export default HomePage;
