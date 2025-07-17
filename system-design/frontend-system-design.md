# Frontend System Design - QR-Based Attendance System

## 1. Frontend Architecture Overview

### 1.1 Technology Stack
```yaml
Framework: React 18 with TypeScript
Styling: Tailwind CSS
State Management: Context API + useReducer
Routing: React Router v6
QR Scanner: react-qr-scanner
QR Generator: qrcode.js
Real-time: Socket.io-client
HTTP Client: Axios
Build Tool: Vite
```

### 1.2 Application Structure
```
src/
├── components/
│   ├── common/
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   ├── LoadingSpinner.tsx
│   │   └── ErrorBoundary.tsx
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   ├── RegisterForm.tsx
│   │   └── ProtectedRoute.tsx
│   ├── student/
│   │   ├── Dashboard.tsx
│   │   ├── QRScanner.tsx
│   │   ├── AttendanceHistory.tsx
│   │   └── ClassList.tsx
│   └── employee/
│       ├── Dashboard.tsx
│       ├── QRGenerator.tsx
│       ├── SessionManager.tsx
│       └── AttendanceReport.tsx
├── pages/
│   ├── Landing.tsx
│   ├── Login.tsx
│   ├── Register.tsx
│   ├── StudentDashboard.tsx
│   └── EmployeeDashboard.tsx
├── hooks/
│   ├── useAuth.tsx
│   ├── useWebSocket.tsx
│   ├── useQRScanner.tsx
│   └── useAttendance.tsx
├── contexts/
│   ├── AuthContext.tsx
│   ├── ThemeContext.tsx
│   └── NotificationContext.tsx
├── services/
│   ├── api.ts
│   ├── auth.ts
│   ├── attendance.ts
│   └── websocket.ts
├── utils/
│   ├── constants.ts
│   ├── helpers.ts
│   └── types.ts
└── App.tsx
```

## 2. Routing Architecture

### 2.1 Route Structure
```typescript
const routes = [
  {
    path: "/",
    element: <Landing />,
    public: true
  },
  {
    path: "/auth/login",
    element: <Login />,
    public: true
  },
  {
    path: "/auth/register", 
    element: <Register />,
    public: true
  },
  {
    path: "/student",
    element: <ProtectedRoute role="student" />,
    children: [
      { path: "/", element: <StudentDashboard /> },
      { path: "/scan", element: <QRScanner /> },
      { path: "/history", element: <AttendanceHistory /> },
      { path: "/classes", element: <ClassList /> }
    ]
  },
  {
    path: "/employee",
    element: <ProtectedRoute role="employee" />,
    children: [
      { path: "/", element: <EmployeeDashboard /> },
      { path: "/sessions", element: <SessionManager /> },
      { path: "/generate-qr", element: <QRGenerator /> },
      { path: "/reports", element: <AttendanceReport /> }
    ]
  }
];
```

### 2.2 Protected Route Implementation
```typescript
const ProtectedRoute: React.FC<{ role: 'student' | 'employee' }> = ({ role }) => {
  const { user, isAuthenticated } = useAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/auth/login" replace />;
  }
  
  if (user?.role !== role) {
    return <Navigate to="/" replace />;
  }
  
  return <Outlet />;
};
```

## 3. State Management

### 3.1 Auth Context
```typescript
interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  loading: boolean;
  error: string | null;
}

const AuthContext = createContext<{
  state: AuthState;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
  register: (userData: RegisterData) => Promise<void>;
} | undefined>(undefined);
```

### 3.2 Attendance Context
```typescript
interface AttendanceState {
  sessions: Session[];
  currentSession: Session | null;
  attendanceRecords: AttendanceRecord[];
  loading: boolean;
}

const AttendanceContext = createContext<{
  state: AttendanceState;
  markAttendance: (qrToken: string) => Promise<void>;
  generateQR: (sessionId: string) => Promise<string>;
  startSession: (sessionId: string) => Promise<void>;
  endSession: (sessionId: string) => Promise<void>;
} | undefined>(undefined);
```

## 4. Component Architecture

### 4.1 Student Portal Components

#### QR Scanner Component
```typescript
const QRScanner: React.FC = () => {
  const [scanning, setScanning] = useState(false);
  const [result, setResult] = useState<string | null>(null);
  const { markAttendance } = useAttendance();
  
  const handleScan = async (data: string) => {
    if (data) {
      setScanning(false);
      try {
        await markAttendance(data);
        setResult('Attendance marked successfully!');
      } catch (error) {
        setResult('Failed to mark attendance');
      }
    }
  };
  
  return (
    <div className="qr-scanner-container">
      {scanning && (
        <QrReader
          delay={300}
          onError={handleError}
          onScan={handleScan}
          style={{ width: '100%' }}
        />
      )}
      <button onClick={() => setScanning(!scanning)}>
        {scanning ? 'Stop Scanner' : 'Start Scanner'}
      </button>
      {result && <div className="result">{result}</div>}
    </div>
  );
};
```

#### Attendance History Component
```typescript
const AttendanceHistory: React.FC = () => {
  const [records, setRecords] = useState<AttendanceRecord[]>([]);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    fetchAttendanceHistory();
  }, []);
  
  const fetchAttendanceHistory = async () => {
    try {
      const data = await api.get('/attendance/student/history');
      setRecords(data);
    } catch (error) {
      console.error('Failed to fetch attendance history');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <div className="attendance-history">
      <h2>Attendance History</h2>
      {loading ? (
        <LoadingSpinner />
      ) : (
        <div className="records-grid">
          {records.map(record => (
            <AttendanceCard key={record.id} record={record} />
          ))}
        </div>
      )}
    </div>
  );
};
```

### 4.2 Employee Portal Components

#### QR Generator Component
```typescript
const QRGenerator: React.FC = () => {
  const [qrCode, setQRCode] = useState<string | null>(null);
  const [sessionId, setSessionId] = useState<string>('');
  const { generateQR } = useAttendance();
  const { socket } = useWebSocket();
  
  const handleGenerateQR = async () => {
    try {
      const qrData = await generateQR(sessionId);
      setQRCode(qrData);
      
      // Set auto-refresh for QR code (every 5 minutes)
      setTimeout(() => {
        handleGenerateQR();
      }, 5 * 60 * 1000);
    } catch (error) {
      console.error('Failed to generate QR code');
    }
  };
  
  useEffect(() => {
    if (socket) {
      socket.on('attendance-marked', (data) => {
        // Update UI with new attendance
        console.log('New attendance:', data);
      });
    }
  }, [socket]);
  
  return (
    <div className="qr-generator">
      <h2>Generate QR Code</h2>
      <div className="session-selector">
        <select 
          value={sessionId} 
          onChange={(e) => setSessionId(e.target.value)}
        >
          <option value="">Select Session</option>
          {/* Session options */}
        </select>
        <button onClick={handleGenerateQR}>Generate QR</button>
      </div>
      {qrCode && (
        <div className="qr-display">
          <QRCodeDisplay value={qrCode} />
          <p>QR Code expires in 5 minutes</p>
        </div>
      )}
    </div>
  );
};
```

## 5. Real-time Features

### 5.1 WebSocket Hook
```typescript
const useWebSocket = () => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [connected, setConnected] = useState(false);
  
  useEffect(() => {
    const newSocket = io(process.env.REACT_APP_WS_URL || 'http://localhost:3001');
    
    newSocket.on('connect', () => {
      setConnected(true);
    });
    
    newSocket.on('disconnect', () => {
      setConnected(false);
    });
    
    setSocket(newSocket);
    
    return () => {
      newSocket.close();
    };
  }, []);
  
  return { socket, connected };
};
```

### 5.2 Real-time Attendance Updates
```typescript
const AttendanceMonitor: React.FC = () => {
  const [attendanceList, setAttendanceList] = useState<AttendanceRecord[]>([]);
  const { socket } = useWebSocket();
  
  useEffect(() => {
    if (socket) {
      socket.on('attendance-marked', (newAttendance: AttendanceRecord) => {
        setAttendanceList(prev => [...prev, newAttendance]);
      });
      
      socket.on('qr-generated', (qrData) => {
        // Update QR display
      });
    }
  }, [socket]);
  
  return (
    <div className="attendance-monitor">
      <h3>Live Attendance</h3>
      <div className="attendance-list">
        {attendanceList.map(record => (
          <div key={record.id} className="attendance-item">
            {record.student.name} - {record.markedAt}
          </div>
        ))}
      </div>
    </div>
  );
};
```

## 6. Mobile Responsiveness

### 6.1 Responsive Design Approach
```css
/* Mobile-first approach with Tailwind CSS */
.qr-scanner-container {
  @apply w-full max-w-md mx-auto p-4;
}

.qr-scanner-container video {
  @apply w-full h-64 object-cover rounded-lg;
}

@media (min-width: 768px) {
  .qr-scanner-container {
    @apply max-w-2xl;
  }
  
  .qr-scanner-container video {
    @apply h-96;
  }
}
```

### 6.2 Touch-friendly Interface
```typescript
const TouchFriendlyButton: React.FC = () => {
  return (
    <button className="w-full py-4 px-6 text-lg font-medium bg-blue-600 text-white rounded-lg touch-manipulation">
      Scan QR Code
    </button>
  );
};
```

## 7. Performance Optimizations

### 7.1 Code Splitting
```typescript
const StudentDashboard = lazy(() => import('./pages/StudentDashboard'));
const EmployeeDashboard = lazy(() => import('./pages/EmployeeDashboard'));

const App: React.FC = () => {
  return (
    <Router>
      <Suspense fallback={<LoadingSpinner />}>
        <Routes>
          <Route path="/student/*" element={<StudentDashboard />} />
          <Route path="/employee/*" element={<EmployeeDashboard />} />
        </Routes>
      </Suspense>
    </Router>
  );
};
```

### 7.2 Memoization
```typescript
const AttendanceCard = React.memo<{ record: AttendanceRecord }>(({ record }) => {
  return (
    <div className="attendance-card">
      <h4>{record.session.class.name}</h4>
      <p>Status: {record.status}</p>
      <p>Time: {formatDate(record.markedAt)}</p>
    </div>
  );
});
```

## 8. Error Handling & UX

### 8.1 Error Boundary
```typescript
class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }
  
  static getDerivedStateFromError(error: Error): State {
    return { hasError: true };
  }
  
  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }
  
  render() {
    if (this.state.hasError) {
      return (
        <div className="error-fallback">
          <h2>Something went wrong</h2>
          <button onClick={() => window.location.reload()}>
            Reload Page
          </button>
        </div>
      );
    }
    
    return this.props.children;
  }
}
```

### 8.2 Loading States
```typescript
const LoadingButton: React.FC<{ loading: boolean; onClick: () => void }> = ({ 
  loading, 
  onClick,
  children 
}) => {
  return (
    <button 
      onClick={onClick}
      disabled={loading}
      className="btn-primary"
    >
      {loading ? <LoadingSpinner size="sm" /> : children}
    </button>
  );
};
```