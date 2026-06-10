import React, { useState } from 'react';
import Dashboard from './pages/Dashboard';
import FarmsPage from './pages/FarmsPage';
import PlotsPage from './pages/PlotsPage';
import CropsPage from './pages/CropsPage';
import InventoryPage from './pages/InventoryPage';
import EmployeesPage from './pages/EmployeesPage';
import WeatherPage from './pages/WeatherPage';
import LeafDetectionPage from './pages/LeafDetectionPage';
import Sidebar from './components/Sidebar';
import Navbar from './components/Navbar';

function App() {
  // this tracks which page is currently showing
  // starts on dashboard
  const [currentPage, setCurrentPage] = useState('dashboard');

  // this function decides which page component to show
  const renderPage = () => {
    switch(currentPage) {
      case 'dashboard':    return <Dashboard setCurrentPage={setCurrentPage} />;
      case 'farms':        return <FarmsPage />;
      case 'plots':        return <PlotsPage />;
      case 'crops':        return <CropsPage />;
      case 'inventory':    return <InventoryPage />;
      case 'employees':    return <EmployeesPage />;
      case 'weather':      return <WeatherPage />;
      case 'leaf':         return <LeafDetectionPage />;
      default:             return <Dashboard setCurrentPage={setCurrentPage} />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-100">
      {/* sidebar on the left */}
      <Sidebar currentPage={currentPage} setCurrentPage={setCurrentPage} />

      {/* main content on the right */}
      <div className="flex-1 flex flex-col overflow-hidden">
        <Navbar />
        <main className="flex-1 overflow-y-auto p-6">
          {renderPage()}
        </main>
      </div>
    </div>
  );
}

export default App;