import React from 'react';

function Navbar() {
  return (
    <header className="bg-white shadow-sm px-6 py-4 flex items-center justify-between">
      <h2 className="text-lg font-semibold text-gray-700">Farm OS</h2>
      <div className="flex items-center gap-3">
        <span className="text-sm text-gray-500">Welcome, Farm Manager</span>
        <div className="w-8 h-8 bg-green-600 rounded-full flex items-center justify-center text-white text-sm font-bold">
          F
        </div>
      </div>
    </header>
  );
}

export default Navbar;