import {
    Alert,
    Box,
    Card,
    CardContent,
    Chip,
    CircularProgress,
    FormControl,
    Grid,
    InputLabel,
    MenuItem,
    Paper,
    Select,
    SelectChangeEvent,
    Table,
    TableBody,
    TableCell,
    TableContainer,
    TableHead,
    TablePagination,
    TableRow,
    Typography
} from '@mui/material';
import { styled } from '@mui/material/styles';
import { format } from 'date-fns';
import React, { useEffect, useState } from 'react';

const StyledTableContainer = styled(TableContainer)(({ theme }) => ({
  marginTop: theme.spacing(2),
  borderRadius: '8px',
  boxShadow: theme.palette.mode === 'dark' 
    ? '0 2px 8px rgba(0,0,0,0.3)' 
    : '0 2px 8px rgba(0,0,0,0.1)',
}));

const StyledTableCell = styled(TableCell)(({ theme }) => ({
  fontWeight: 500,
  backgroundColor: theme.palette.mode === 'dark' ? '#424242' : '#f5f5f5',
}));

const StatsCard = styled(Card)(({ theme }) => ({
  borderRadius: '8px',
  boxShadow: theme.palette.mode === 'dark' 
    ? '0 2px 8px rgba(0,0,0,0.3)' 
    : '0 2px 8px rgba(0,0,0,0.1)',
}));

interface Submission {
  submission_id: string;
  first_name: string;
  last_name: string;
  message: string;
  batch_id: string | null;
  processing_time: number;
  created_at: string;
}

interface Statistics {
  total_submissions: number;
  total_messages: number;
  recent_submissions: number;
  avg_processing_time: number;
  latest_submission: {
    id: string;
    name: string;
    timestamp: string;
  } | null;
  api_version: string;
  status: string;
  debug_mode: boolean;
  last_submission: string | null;
  uptime_seconds: number;
}

const ReportingPage: React.FC = () => {
  const [submissions, setSubmissions] = useState<Submission[]>([]);
  const [statistics, setStatistics] = useState<Statistics | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [totalCount, setTotalCount] = useState(0);

  const fetchSubmissions = async (pageNum: number, limit: number) => {
    try {
      setLoading(true);
      setError(null);
      
      const offset = pageNum * limit;
      const response = await fetch(`/api/submissions?limit=${limit}&offset=${offset}`);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }      const data = await response.json();
      
      setSubmissions(data.submissions || []);
      setTotalCount(data.total || 0);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch submissions');
    } finally {
      setLoading(false);
    }
  };

  const fetchStatistics = async () => {
    try {
      const response = await fetch('/api/stats');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setStatistics(data);
    } catch (err) {
      console.error('Failed to fetch statistics:', err);
    }
  };
  useEffect(() => {
    fetchSubmissions(page, rowsPerPage);
    fetchStatistics();  }, [page, rowsPerPage]);

  const handleChangePage = (event: unknown, newPage: number) => {
    setPage(newPage);
  };

  const handleChangeRowsPerPage = (event: SelectChangeEvent<number>) => {
    const newRowsPerPage = parseInt(event.target.value as string, 10);
    setRowsPerPage(newRowsPerPage);
    setPage(0);
  };

  const formatDate = (dateString: string) => {
    try {
      return format(new Date(dateString), 'MMM dd, yyyy HH:mm:ss');
    } catch {
      return 'Invalid date';
    }
  };

  const formatProcessingTime = (time: number) => {
    return `${(time * 1000).toFixed(0)}ms`;
  };

  if (loading && submissions.length === 0) {
    return (
      <Box sx={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '400px' }}>
        <CircularProgress />
      </Box>
    );
  }  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom sx={{ fontWeight: 600, mb: 3 }}>
        Submissions Reporting
      </Typography>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}      {/* Statistics Cards */}
      {statistics && (
        <Grid container spacing={3} sx={{ mb: 4 }}>
          <Grid item xs={12} sm={6} md={3}>
            <StatsCard>
              <CardContent>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Total Submissions
                </Typography>
                <Typography variant="h4" component="div" color="primary">
                  {statistics.total_submissions}
                </Typography>
              </CardContent>
            </StatsCard>
          </Grid>
            <Grid item xs={12} sm={6} md={3}>
            <StatsCard>
              <CardContent>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Recent (24h)
                </Typography>
                <Typography variant="h4" component="div" color="secondary">
                  {statistics.recent_submissions}
                </Typography>
              </CardContent>
            </StatsCard>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <StatsCard>
              <CardContent>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Avg Processing Time
                </Typography>
                <Typography variant="h4" component="div">
                  {(statistics.avg_processing_time * 1000).toFixed(0)}ms
                </Typography>
              </CardContent>
            </StatsCard>
          </Grid>
          
          <Grid item xs={12} sm={6} md={3}>
            <StatsCard>
              <CardContent>
                <Typography color="textSecondary" gutterBottom variant="body2">
                  Latest Submission
                </Typography>
                <Typography variant="body1" component="div" sx={{ fontWeight: 500 }}>
                  {statistics.latest_submission?.name || 'None'}
                </Typography>
                {statistics.latest_submission && (
                  <Typography variant="caption" color="textSecondary">
                    {formatDate(statistics.latest_submission.timestamp)}
                  </Typography>
                )}
              </CardContent>
            </StatsCard>
          </Grid>
        </Grid>
      )}

      {/* Data Table */}
      <Paper>
        <Box sx={{ p: 2, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <Typography variant="h6" component="h2">
            Submission Details
          </Typography>
          
          <FormControl size="small" sx={{ minWidth: 120 }}>
            <InputLabel>Rows per page</InputLabel>
            <Select
              value={rowsPerPage}
              label="Rows per page"
              onChange={handleChangeRowsPerPage}
            >
              <MenuItem value={10}>10</MenuItem>
              <MenuItem value={25}>25</MenuItem>
              <MenuItem value={50}>50</MenuItem>
              <MenuItem value={100}>100</MenuItem>
            </Select>
          </FormControl>
        </Box>

        <StyledTableContainer>
          <Table>
            <TableHead>
              <TableRow>
                <StyledTableCell>Submission ID</StyledTableCell>
                <StyledTableCell>Name</StyledTableCell>
                <StyledTableCell>Message</StyledTableCell>
                <StyledTableCell>Batch ID</StyledTableCell>
                <StyledTableCell>Processing Time</StyledTableCell>
                <StyledTableCell>Created At</StyledTableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {submissions.map((submission) => (
                <TableRow key={submission.submission_id} hover>
                  <TableCell>
                    <Chip 
                      label={submission.submission_id}
                      variant="outlined" 
                      size="small"
                      sx={{ fontFamily: 'monospace', fontSize: '0.75rem' }}
                    />
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontWeight: 500 }}>
                      {submission.first_name} {submission.last_name}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography 
                      variant="body2" 
                      sx={{ 
                        maxWidth: 300, 
                        overflow: 'hidden', 
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap'
                      }}
                      title={submission.message}
                    >
                      {submission.message}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    {submission.batch_id ? (
                      <Chip 
                        label={submission.batch_id}
                        color="primary"
                        size="small"
                        variant="outlined"
                      />
                    ) : (
                      <Typography variant="body2" color="textSecondary">
                        —
                      </Typography>
                    )}
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2" sx={{ fontFamily: 'monospace' }}>
                      {formatProcessingTime(submission.processing_time)}
                    </Typography>
                  </TableCell>
                  <TableCell>
                    <Typography variant="body2">
                      {formatDate(submission.created_at)}
                    </Typography>
                  </TableCell>
                </TableRow>
              ))}
              
              {submissions.length === 0 && !loading && (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 4 }}>
                    <Typography variant="body1" color="textSecondary">
                      No submissions found
                    </Typography>
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </StyledTableContainer>        <TablePagination
          rowsPerPageOptions={[10, 25, 50, 100]}
          component="div"
          count={totalCount}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}          onRowsPerPageChange={(event) => {
            const newRowsPerPage = parseInt(event.target.value, 10);
            setRowsPerPage(newRowsPerPage);
            setPage(0);
          }}
          showFirstButton
          showLastButton
        />
        
      </Paper>
    </Box>
  );
};

export default ReportingPage;
