import React, { useEffect, useState } from 'react';
import api from '../services/api';
import { 
  MdAgriculture, MdPeople, MdInventory, 
  MdWbSunny, MdYard 
} from 'react-icons/md';
import { GiPlantRoots, GiLeafSwirl } from 'react-icons/gi';

// feature cards shown on dashboard
const features = [
  {
    id: 'farms',
    title: 'Farm Management',
    description: 'Manage your farms and view details',
    icon: MdAgriculture,
    color: 'bg-green-500',
    status: 'live'
  },
  {
    id: 'plots',
    title: 'Plot Management',
    description: 'Divide farms into plots and sections',
    icon: MdYard,
    color: 'bg-emerald-500',
    status: 'live'
  },
  {
    id: 'crops',
    title: 'Crop Management',
    description: 'Track crop calendar and irrigation schedule',
    icon: GiPlantRoots,
    color: 'bg-lime-500',
    status: 'coming soon'
  },
  {
    id: 'inventory',
    title: 'Inventory',
    description: 'Track fertilizers, pesticides and equipment',
    icon: MdInventory,
    color: 'bg-yellow-500',
    status: 'coming soon'
  },
  {
    id: 'employees',
    title: 'Employees & Payroll',
    description: 'Attendance tracking and wage calculation',
    icon: MdPeople,
    color: 'bg-blue-500',
    status: 'coming soon'
  },
  {
    id: 'weather',
    title: 'Weather',
    description: 'Hyperlocal weather and rain forecast',
    icon: MdWbSunny,
    color: 'bg-sky-500',
    status: 'coming soon'
  },
  {
    id: 'leaf',
    title: 'Leaf Disease Detection',
    description: 'AI powered plant disease diagnosis',
    icon: GiLeafSwirl,
    color: 'bg-rose-500',
    status: 'coming soon'
  },
];

function Dashboard({ setCurrentPage }) {
  const [farmCount, setFarmCount] = useState(0);

  useEffect(() => {
    api.get('/farms')
      .then(res => setFarmCount(res.data.length))
      .catch(err => console.error(err));
  }, []);

  return (
    <div>
      {/* page title */}
      <div className="mb-6">
        <h2 className="text-2xl font-bold text-gray-800">Dashboard</h2>
        <p className="text-gray-500 text-sm mt-1">Welcome to your Farm OS overview</p>
      </div>

      {/* stats row */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl p-4 shadow-sm border">
          <p className="text-sm text-gray-500">Total Farms</p>
          <p className="text-3xl font-bold text-green-600 mt-1">{farmCount}</p>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-sm border">
          <p className="text-sm text-gray-500">Total Plots</p>
          <p className="text-3xl font-bold text-emerald-600 mt-1">—</p>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-sm border">
          <p className="text-sm text-gray-500">Active Crops</p>
          <p className="text-3xl font-bold text-lime-600 mt-1">—</p>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-sm border">
          <p className="text-sm text-gray-500">Employees</p>
          <p className="text-3xl font-bold text-blue-600 mt-1">—</p>
        </div>
      </div>

      {/* feature cards */}
      <h3 className="text-lg font-semibold text-gray-700 mb-4">All Features</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {features.map(feature => {
          const Icon = feature.icon;
          return (
            <button
              key={feature.id}
              onClick={() => setCurrentPage(feature.id)}
              className="bg-white rounded-xl p-5 shadow-sm border hover:shadow-md transition-shadow text-left"
            >
              <div className="flex items-start justify-between">
                <div className={`${feature.color} p-3 rounded-lg`}>
                  <Icon size={22} className="text-white" />
                </div>
                {/* badge showing if feature is live or coming soon */}
                <span className={`text-xs px-2 py-1 rounded-full font-medium ${
                  feature.status === 'live' 
                    ? 'bg-green-100 text-green-700' 
                    : 'bg-gray-100 text-gray-500'
                }`}>
                  {feature.status === 'live' ? '✅ Live' : '🔜 Soon'}
                </span>
              </div>
              <h4 className="font-semibold text-gray-800 mt-3">{feature.title}</h4>
              <p className="text-sm text-gray-500 mt-1">{feature.description}</p>
            </button>
          );
        })}
      </div>
    </div>
  );
}

export default Dashboard;