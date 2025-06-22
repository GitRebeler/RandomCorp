import { PlayArrow, Videocam } from '@mui/icons-material';
import { Box, Button, Card, CardContent, CardMedia, Grid, Paper, Typography } from '@mui/material';
import React from 'react';

const VideosPage: React.FC = () => {
  // Placeholder video data
  const videos = [
    {
      id: 1,
      title: "Getting Started with Random Corp",
      description: "Learn the basics of using our submission system",
      duration: "5:32",
      thumbnail: "https://via.placeholder.com/300x200/0078d4/ffffff?text=Video+1"
    },
    {
      id: 2,
      title: "Advanced Reporting Features",
      description: "Discover powerful reporting and analytics capabilities",
      duration: "8:15",
      thumbnail: "https://via.placeholder.com/300x200/106ebe/ffffff?text=Video+2"
    },
    {
      id: 3,
      title: "Best Practices Guide",
      description: "Tips and tricks for optimal system usage",
      duration: "6:45",
      thumbnail: "https://via.placeholder.com/300x200/1e40af/ffffff?text=Video+3"
    }
  ];

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <Videocam sx={{ mr: 2, fontSize: 32, color: 'primary.main' }} />
        <Typography variant="h4" component="h1" sx={{ fontWeight: 600 }}>
          Video Library
        </Typography>
      </Box>
      
      <Typography variant="body1" color="text.secondary" paragraph>
        Explore our collection of tutorial and educational videos to help you make the most of Random Corp.
      </Typography>

      <Grid container spacing={3} sx={{ mt: 2 }}>
        {videos.map((video) => (
          <Grid item xs={12} sm={6} md={4} key={video.id}>
            <Card sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
              <CardMedia
                component="div"
                sx={{
                  height: 200,
                  background: `url(${video.thumbnail})`,
                  backgroundSize: 'cover',
                  backgroundPosition: 'center',
                  position: 'relative',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  '&:hover': {
                    '& .play-overlay': {
                      opacity: 1,
                    }
                  }
                }}
              >
                <Box
                  className="play-overlay"
                  sx={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    background: 'rgba(0,0,0,0.5)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    opacity: 0,
                    transition: 'opacity 0.2s ease-in-out',
                  }}
                >
                  <PlayArrow sx={{ fontSize: 48, color: 'white' }} />
                </Box>
                
                <Box
                  sx={{
                    position: 'absolute',
                    bottom: 8,
                    right: 8,
                    background: 'rgba(0,0,0,0.8)',
                    color: 'white',
                    padding: '4px 8px',
                    borderRadius: '4px',
                    fontSize: '0.75rem',
                    fontWeight: 500,
                  }}
                >
                  {video.duration}
                </Box>
              </CardMedia>
              
              <CardContent sx={{ flexGrow: 1 }}>
                <Typography variant="h6" component="h3" gutterBottom>
                  {video.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" paragraph>
                  {video.description}
                </Typography>
                <Button
                  variant="outlined"
                  startIcon={<PlayArrow />}
                  size="small"
                  fullWidth
                  sx={{ mt: 'auto' }}
                >
                  Watch Video
                </Button>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Coming Soon Section */}
      <Paper sx={{ p: 4, mt: 4, textAlign: 'center', backgroundColor: 'action.hover' }}>
        <Typography variant="h5" component="h2" gutterBottom>
          More Videos Coming Soon!
        </Typography>
        <Typography variant="body1" color="text.secondary">
          We're constantly creating new content to help you succeed. 
          Check back regularly for the latest tutorials and guides.
        </Typography>
      </Paper>
    </Box>
  );
};

export default VideosPage;
