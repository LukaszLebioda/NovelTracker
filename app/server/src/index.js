import express from 'express';
import cookieParser from 'cookie-parser';

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cookieParser());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(port, () => {
  console.log(`NovelTracker API listening on http://localhost:${port}`);
});

export default app;
