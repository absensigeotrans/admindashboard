'use client';

import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Circle, useMap } from 'react-leaflet';
import { Office, Location } from '@/types';
import { calculateDistance } from '@/lib/utils';

// Dynamic import for Leaflet to avoid SSR issues
let Icon: typeof import('leaflet').Icon | null = null;
if (typeof window !== 'undefined') {
  Icon = require('leaflet').Icon;
}

// CDN icons for Leaflet markers
const getDefaultIcon = () => {
  if (!Icon) return null;
  return new Icon({
    iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
    iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
    shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
    iconSize: [25, 41],
    iconAnchor: [12, 41],
    popupAnchor: [1, -34],
    shadowSize: [41, 41],
  });
};

// Simple SVG circle for user location
const userIconHtml = `
  <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
    <circle cx="12" cy="12" r="10" fill="#3b82f6" stroke="white" stroke-width="2"/>
    <circle cx="12" cy="12" r="4" fill="white"/>
  </svg>
`;

const getUserIcon = () => {
  if (!Icon) return null;
  return new Icon({
    iconUrl: `data:image/svg+xml;base64,${btoa(userIconHtml)}`,
    iconSize: [24, 24],
    iconAnchor: [12, 12],
  });
};

interface MapProps {
  office: Office;
  userLocation: Location | null;
  height?: string;
}

function MapUpdater({ center }: { center: [number, number] }) {
  const map = useMap();
  useEffect(() => {
    map.setView(center, map.getZoom());
  }, [center, map]);
  return null;
}

export function Map({ office, userLocation, height = '400px' }: MapProps) {
  const officePosition: [number, number] = [office.latitude, office.longitude];
  
  const distance = userLocation 
    ? calculateDistance(
        userLocation.latitude, 
        userLocation.longitude, 
        office.latitude, 
        office.longitude
      )
    : null;

  const isWithinRange = distance !== null && distance <= office.geofence_radius;

  return (
    <MapContainer
      center={officePosition}
      zoom={16}
      style={{ height, width: '100%', borderRadius: '0.5rem' }}
      scrollWheelZoom={false}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      
      {/* Office marker */}
      {Icon && <Marker position={officePosition} icon={getDefaultIcon()!} />}
      
      {/* Geofence circle */}
      <Circle
        center={officePosition}
        radius={office.geofence_radius}
        pathOptions={{
          color: isWithinRange ? '#22c55e' : '#ef4444',
          fillColor: isWithinRange ? '#22c55e' : '#ef4444',
          fillOpacity: 0.2,
          weight: 2,
        }}
      />
      
      {/* User location marker */}
      {userLocation && Icon && (
        <>
          <Marker 
            position={[userLocation.latitude, userLocation.longitude]} 
            icon={getUserIcon()!}
          />
          <MapUpdater center={[userLocation.latitude, userLocation.longitude]} />
        </>
      )}
    </MapContainer>
  );
}
