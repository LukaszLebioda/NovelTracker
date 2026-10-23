import { useEffect, useState } from 'react';

export default function App() {
  const [status, setStatus] = useState('checking...');

  useEffect(() => {
    fetch('/health')
      .then((res) => res.json())
      .then((data) => setStatus(data.status))
      .catch(() => setStatus('unreachable'));
  }, []);

  return (
    <main>
      <h1>NovelTracker</h1>
      <p>API status: {status}</p>
    </main>
  );
}
